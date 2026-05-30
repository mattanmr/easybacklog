<#
.SYNOPSIS
    easyBacklog — one-shot setup script (Windows PowerShell)
.DESCRIPTION
    What this script does:
      1. Checks that Docker is installed and running
      2. Creates an easybacklog\ directory and enters it
      3. Downloads docker-compose.yml from this GitHub release
      4. Generates a .env file with secure random tokens
      5. Pulls the pre-built Docker images
      6. Starts all services (PostgreSQL, Redis, Rails, Sidekiq)
      7. Waits for the web server to become ready
      8. Initialises the database (schema + seed data)
      9. Prints the URL and demo credentials
.EXAMPLE
    # Download and run in one step (PowerShell):
    Invoke-WebRequest -Uri https://github.com/mattanmr/easybacklog/releases/latest/download/setup.ps1 -OutFile setup.ps1 ; .\setup.ps1

    # Skip demo sample data:
    .\setup.ps1 -SkipSampleData
.NOTES
    Requirements: Docker Desktop for Windows (must be running).
    Run from the directory where you want easybacklog\ to be created.
#>

[CmdletBinding()]
param(
    [switch]$SkipSampleData   # omit loading demo account and sample backlog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Constants ─────────────────────────────────────────────────────────────
$ReleaseBaseUrl  = 'https://github.com/mattanmr/easybacklog/releases/latest/download'
$InstallDir      = 'easybacklog'
$AppUrl          = 'http://localhost:3000'
$HealthUrl       = "$AppUrl/status"
$HealthTimeout   = 120   # seconds to wait for the web server
$ComposeProject  = 'easybacklog'

# ── Helpers ───────────────────────────────────────────────────────────────
function Write-Step($number, $message) {
    Write-Host ""
    Write-Host "── Step $number`: $message" -ForegroundColor White
}

function Write-Info($message)    { Write-Host "▶  $message" -ForegroundColor Cyan }
function Write-Success($message) { Write-Host "✔  $message" -ForegroundColor Green }
function Write-Warn($message)    { Write-Host "⚠  $message" -ForegroundColor Yellow }
function Write-Fail($message)    { Write-Host "✖  $message" -ForegroundColor Red }

function Exit-WithError($message) {
    Write-Fail $message
    exit 1
}

function Invoke-DockerCompose {
    param([string[]]$Arguments)
    $allArgs = @('-p', $ComposeProject) + $Arguments
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & docker compose @allArgs
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    return $code
}

function Invoke-DockerComposeExec {
    param([string[]]$Command)
    $allArgs = @('-p', $ComposeProject, 'exec', '-T', 'web') + $Command
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & docker compose @allArgs
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    return $code
}

# ── Step 1: Check Docker ──────────────────────────────────────────────────
Write-Step 1 'Checking prerequisites'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Exit-WithError 'Docker not found. Install Docker Desktop from https://www.docker.com/products/docker-desktop/ and try again.'
}

$dockerInfo = & docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Exit-WithError 'Docker is installed but not running. Start Docker Desktop and try again.'
}

$composeCheck = & docker compose version 2>&1
if ($LASTEXITCODE -ne 0) {
    Exit-WithError 'Docker Compose plugin not found. Update Docker Desktop to a recent version (it includes Compose v2).'
}

$dockerVersion = (& docker --version) -replace '.*?(\d+\.\d+\.\d+).*', '$1'
Write-Success "Docker $dockerVersion is running"

# ── Step 2: Create install directory ──────────────────────────────────────
Write-Step 2 'Creating install directory'

if (Test-Path $InstallDir) {
    Write-Warn "Directory '.\$InstallDir' already exists — continuing inside it."
} else {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
    Write-Success "Created '.\$InstallDir'"
}
Set-Location $InstallDir

# ── Step 3: Download docker-compose.yml ───────────────────────────────────
Write-Step 3 'Downloading docker-compose.yml'

if (Test-Path 'docker-compose.yml') {
    Write-Warn 'docker-compose.yml already exists — skipping download.'
} else {
    try {
        Invoke-WebRequest -Uri "$ReleaseBaseUrl/docker-compose.yml" -OutFile 'docker-compose.yml' -UseBasicParsing
        Write-Success 'Downloaded docker-compose.yml'
    } catch {
        Exit-WithError "Download failed: $_`nCheck your internet connection and try again."
    }
}

# ── Step 4: Generate .env file ────────────────────────────────────────────
Write-Step 4 'Generating .env file'

if (Test-Path '.env') {
    Write-Warn '.env already exists — skipping generation. Delete it and re-run to regenerate.'
} else {
    $secretToken  = -join ((1..64) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
    $devisePepper = -join ((1..64) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
    $timestamp    = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm') + ' UTC'

    $envContent = @"
# easyBacklog environment configuration
# Generated by setup.ps1 on $timestamp
# ---------------------------------------------------------
# SECRET_TOKEN    -- Rails session secret. Must be >= 30 chars.
#                    Changing this invalidates all active sessions.
SECRET_TOKEN=$secretToken

# DEVISE_PEPPER   -- Password hashing pepper. Must be >= 30 chars.
#                    Never change this once users have been created
#                    (it would invalidate all passwords).
DEVISE_PEPPER=$devisePepper

# DB_PASSWORD     -- PostgreSQL password for the 'postgres' user.
#                    Change before exposing the database port publicly.
DB_PASSWORD=password
"@
    Set-Content -Path '.env' -Value $envContent -Encoding UTF8
    Write-Success 'Generated .env with secure random tokens'
}

# ── Step 5: Pull images ────────────────────────────────────────────────────
Write-Step 5 'Pulling Docker images (this may take a minute on first run)'

$pullExit = Invoke-DockerCompose @('pull')
if ($pullExit -ne 0) {
    Exit-WithError 'Image pull failed. Check your internet connection and try again.'
}
Write-Success 'Images pulled'

# ── Step 6: Start services ─────────────────────────────────────────────────
Write-Step 6 'Starting services'

$upExit = Invoke-DockerCompose @('up', '-d')
if ($upExit -ne 0) {
    Exit-WithError "Failed to start services. Run 'docker compose logs' inside .\$InstallDir for details."
}
Write-Success 'Services started (db, redis, web, sidekiq)'

# ── Step 7: Wait for web server ────────────────────────────────────────────
Write-Step 7 "Waiting for the web server to become ready (timeout: ${HealthTimeout}s)"

$elapsed = 0
$ready   = $false
while ($elapsed -lt $HealthTimeout) {
    try {
        $resp = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($resp.StatusCode -eq 200) {
            $ready = $true
            break
        }
    } catch { }
    Start-Sleep -Seconds 5
    $elapsed += 5
    Write-Host '.' -NoNewline
}

if ($ready) {
    Write-Host ''
    Write-Success "Web server is ready (${elapsed}s)"
} else {
    Write-Host ''
    Write-Warn "Web server did not respond within ${HealthTimeout}s."
    Write-Warn "Check logs with: docker compose -p $ComposeProject logs -f web"
    Write-Warn 'The database init commands below may still work once it starts.'
}

# ── Step 8: Initialise the database ───────────────────────────────────────
Write-Step 8 'Initialising the database (first-run only)'

Write-Info 'Loading schema…'
$schemaExit = Invoke-DockerComposeExec @('bundle', 'exec', 'rake', 'db:schema:load')
if ($schemaExit -ne 0) { Exit-WithError 'db:schema:load failed. Check logs for details.' }

Write-Info 'Loading seed data…'
$seedExit = Invoke-DockerComposeExec @('bundle', 'exec', 'rake', 'db:seed')
if ($seedExit -ne 0) { Exit-WithError 'db:seed failed. Check logs for details.' }

if (-not $SkipSampleData) {
    Write-Info 'Loading sample data (demo account + backlog)…'
    $sampleExit = Invoke-DockerComposeExec @('bundle', 'exec', 'rake', 'db:seed:sample')
    if ($sampleExit -ne 0) { Exit-WithError 'db:seed:sample failed. Check logs for details.' }
    Write-Success 'Database initialised with schema, seeds, and sample data'
} else {
    Write-Success 'Database initialised with schema and seeds (sample data skipped)'
}

# ── Step 9: Done ───────────────────────────────────────────────────────────
Write-Host ''
Write-Host '══════════════════════════════════════════════' -ForegroundColor Green
Write-Host '  easyBacklog is ready!'                        -ForegroundColor Green
Write-Host '══════════════════════════════════════════════' -ForegroundColor Green
Write-Host ''
Write-Host "  URL:       $AppUrl" -ForegroundColor White
if (-not $SkipSampleData) {
    Write-Host '  Email:     demo@example.com'  -ForegroundColor White
    Write-Host '  Password:  password123'       -ForegroundColor White
    Write-Host ''
    Write-Host "  (Or sign up for a new account at $AppUrl/users/sign_up)" -ForegroundColor DarkGray
}
Write-Host ''
Write-Host "  Config:    $(Get-Location)\.env"                                           -ForegroundColor DarkGray
Write-Host "  Stop:      docker compose -p $ComposeProject down"                         -ForegroundColor DarkGray
Write-Host "  Logs:      docker compose -p $ComposeProject logs -f web"                  -ForegroundColor DarkGray
Write-Host "  Restart:   docker compose -p $ComposeProject up -d"                        -ForegroundColor DarkGray
Write-Host ''
Write-Warn 'Keep your .env file safe — it contains your secret tokens.'
Write-Warn "To delete all data:  docker compose -p $ComposeProject down -v"
Write-Host ''
