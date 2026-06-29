<#
.SYNOPSIS
    easyBacklog Management Script (Windows / PowerShell)

.DESCRIPTION
    Manage your local easyBacklog installation.

.PARAMETER Command
    setup    First-time setup: download files, start services, init DB
    start    Start all services
    stop     Stop all services (data is kept)
    reset    Wipe all data and reinitialise from scratch
    delete   Remove everything (containers, volumes, local files)
    update   Pull latest images and restart
    status   Show container status

.EXAMPLE
    .\manage.ps1 setup
    .\manage.ps1 start
    .\manage.ps1 stop
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('setup', 'start', 'stop', 'reset', 'delete', 'update', 'status')]
    [string]$Command
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Configuration ──────────────────────────────────────────────────────────
$RepoUrl     = 'https://github.com/mattanmr/easybacklog'
$ReleaseBase = "$RepoUrl/releases/latest/download"
$AppUrl      = 'http://localhost:3000'

# ── Helpers ────────────────────────────────────────────────────────────────
function Write-Info($msg)    { Write-Host "  -> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)      { Write-Host "  v $msg"  -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "  ! $msg"  -ForegroundColor Yellow }
function Write-Err($msg)     { Write-Host "  x $msg"  -ForegroundColor Red }

function Confirm-Action($prompt) {
    $answer = Read-Host "  ? $prompt [y/N]"
    return ($answer -match '^[Yy]$')
}

function Prompt-YN($prompt, $default = 'N') {
    $display = if ($default -eq 'Y') { '[Y/n]' } else { '[y/N]' }
    $answer  = Read-Host "  ? $prompt $display"
    if ([string]::IsNullOrWhiteSpace($answer)) { $answer = $default }
    return ($answer -match '^[Yy]$')
}

# ── Prerequisite checks ────────────────────────────────────────────────────
function Assert-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Err 'Docker is not installed or not in PATH.'
        Write-Host '  Install Docker from: https://docs.docker.com/get-docker/' -ForegroundColor White
        exit 1
    }
    $info = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err 'Docker daemon is not running.'
        Write-Host '  Please start Docker Desktop and try again.' -ForegroundColor White
        exit 1
    }
}

# ── Download helper ────────────────────────────────────────────────────────
function Get-ReleaseFile($url, $dest) {
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
}

# ── Ensure release files are present ──────────────────────────────────────
function Ensure-Files {
    if (-not (Test-Path 'docker-compose.yml')) {
        Write-Info 'Downloading docker-compose.yml...'
        Get-ReleaseFile "$ReleaseBase/docker-compose.yml" 'docker-compose.yml'
        Write-Ok 'docker-compose.yml downloaded.'
    }
    if (-not (Test-Path '.env')) {
        Write-Info 'Downloading .env...'
        Get-ReleaseFile "$ReleaseBase/.env" '.env'
        Write-Ok '.env downloaded.'
    }
}

# ── Wait for the app to become healthy ────────────────────────────────────
function Wait-AppHealthy {
    $timeout = 180
    $elapsed = 0
    Write-Info "Waiting for Rails to start (up to ${timeout}s)..."
    while ($elapsed -lt $timeout) {
        # Check TCP port 3000 -- same check the container healthcheck uses.
        # Do NOT check /status here; it requires the DB schema which isn't loaded yet.
        $tcp = $null
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect('localhost', 3000)
            Write-Host ''
            Write-Ok "Rails is accepting connections at $AppUrl"
            return $true
        } catch {
            $null
        } finally {
            if ($tcp) { $tcp.Dispose() }
        }
        Start-Sleep -Seconds 5
        $elapsed += 5
        Write-Host '.' -NoNewline
    }
    Write-Host ''
    Write-Err 'Timed out waiting for Rails to start.'
    Write-Host "  Run 'docker compose logs web' to diagnose." -ForegroundColor White
    return $false
}

# ── Check if DB is already initialised ────────────────────────────────────
function Test-DbInitialised {
    $oldPref = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $result = docker compose exec -T web bundle exec rails runner "puts ActiveRecord::Base.connection.table_exists?(:users)" 2>&1 |
        Where-Object { $_ -is [string] -or $_ -isnot [System.Management.Automation.ErrorRecord] } |
        Out-String
    $ErrorActionPreference = $oldPref
    return ($result -match 'true')
}

# ── Initialise the database ────────────────────────────────────────────────
function Initialize-Db {
    Write-Info 'Loading database schema...'
    docker compose exec -T web bundle exec rake db:schema:load
    Write-Info 'Seeding database...'
    docker compose exec -T web bundle exec rake db:seed
    Write-Ok 'Database initialised.'

    Write-Host ''
    if (Prompt-YN 'Load sample data? (creates demo@example.com / password123)' 'Y') {
        Write-Info 'Loading sample data...'
        docker compose exec -T web bundle exec rake db:seed:sample
        Write-Ok 'Sample data loaded.'
        Write-Host ''
        Write-Host '  Demo credentials: demo@example.com / password123' -ForegroundColor White
    }
}

# ════════════════════════════════════════════════════════════════════════════
# COMMANDS
# ════════════════════════════════════════════════════════════════════════════

function Invoke-Setup {
    Write-Host ''
    Write-Host 'easyBacklog Setup' -ForegroundColor White
    Write-Host ('=' * 44) -ForegroundColor White
    Write-Host ''

    Assert-Docker
    Ensure-Files

    # Offer to generate a secure SECRET_TOKEN
    Write-Host ''
    Write-Warn 'The default SECRET_TOKEN is a demo value — fine for local use, but should'
    Write-Warn 'be changed for any shared or internet-facing deployment.'

    if (Prompt-YN 'Generate a secure SECRET_TOKEN now?' 'Y') {
        $token = -join ((1..64) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
        $envContent = (Get-Content '.env') -replace '^SECRET_TOKEN=.*', "SECRET_TOKEN=$token"
        $envContent | Set-Content '.env' -Encoding UTF8
        Write-Ok 'SECRET_TOKEN updated in .env.'
    } else {
        Write-Warn 'Using demo SECRET_TOKEN. Edit .env to change it later.'
    }

    Write-Host ''
    Write-Info 'Pulling images...'
    docker compose pull

    Write-Host ''
    Write-Info 'Starting services...'
    docker compose up -d

    Write-Host ''
    $healthy = Wait-AppHealthy
    if (-not $healthy) { exit 1 }

    Write-Host ''
    if (Test-DbInitialised) {
        Write-Info 'Database already initialised — skipping.'
    } else {
        Initialize-Db
    }

    Write-Host ''
    Write-Host ('=' * 44) -ForegroundColor White
    Write-Host 'Setup complete!' -ForegroundColor Green
    Write-Host ('=' * 44) -ForegroundColor White
    Write-Host "  App URL : $AppUrl" -ForegroundColor White
    Write-Host ''
    Write-Host '  Useful commands:' -ForegroundColor White
    Write-Host '    .\manage.ps1 stop'
    Write-Host '    .\manage.ps1 start'
    Write-Host '    .\manage.ps1 status'
    Write-Host '    .\manage.ps1 update'
    Write-Host '    .\manage.ps1 reset'
    Write-Host ''
}

function Invoke-Start {
    Assert-Docker
    Ensure-Files
    Write-Info 'Starting services...'
    docker compose up -d
    Write-Host ''
    Wait-AppHealthy | Out-Null
}

function Invoke-Stop {
    Assert-Docker
    Write-Info 'Stopping services (data is kept)...'
    docker compose down
    Write-Ok 'Services stopped.'
}

function Invoke-Reset {
    Assert-Docker
    Write-Host ''
    Write-Warn 'This will DELETE all data (database, uploads) and reinitialise from scratch.'
    if (-not (Confirm-Action 'Are you sure you want to reset?')) {
        Write-Info 'Reset cancelled.'
        exit 0
    }
    Write-Info 'Stopping and removing volumes...'
    docker compose down -v
    Write-Info 'Starting services...'
    docker compose up -d
    Write-Host ''
    $healthy = Wait-AppHealthy
    if (-not $healthy) { exit 1 }
    Write-Host ''
    Initialize-Db
    Write-Ok 'Reset complete.'
}

function Invoke-Delete {
    Assert-Docker
    Write-Host ''
    Write-Warn 'This will DELETE all containers, volumes, AND the local files (docker-compose.yml, .env).'
    Write-Warn 'This cannot be undone.'
    if (-not (Confirm-Action 'Are you sure you want to delete everything?')) {
        Write-Info 'Delete cancelled.'
        exit 0
    }
    Write-Info 'Removing containers and volumes...'
    docker compose down -v --remove-orphans
    Write-Info 'Removing local files...'
    Remove-Item 'docker-compose.yml', '.env' -ErrorAction SilentlyContinue
    Write-Ok 'Everything removed.'
}

function Invoke-Update {
    Assert-Docker
    Write-Info 'Pulling latest images...'
    docker compose pull
    Write-Info 'Restarting with updated images...'
    docker compose up -d
    Write-Host ''
    Wait-AppHealthy | Out-Null
    Write-Ok 'Update complete.'
}

function Invoke-Status {
    Assert-Docker
    Write-Host ''
    Write-Host '+----------------------------------------------------------+' -ForegroundColor White
    Write-Host '|               easyBacklog Status                         |' -ForegroundColor White
    Write-Host '+----------------------------------------------------------+' -ForegroundColor White

    $hdr = '|  {0,-12} {1,-14} {2,-12} {3,-12} |'
    Write-Host ($hdr -f 'SERVICE','STATUS','HEALTH','PORTS') -ForegroundColor White
    Write-Host '+----------------------------------------------------------+' -ForegroundColor White

    $lines = docker compose ps --format '{{.Service}} {{.State}} {{if .Health}}{{.Health}}{{else}}N/A{{end}} {{.Ports}}' 2>$null | Sort-Object
    foreach ($line in $lines) {
        $parts  = $line -split '\s+', 4
        $svc    = $parts[0]
        $status = $parts[1]
        $health = $parts[2]
        $ports  = if ($parts.Count -gt 3) { $parts[3] } else { '' }
        if ($ports.Length -gt 20) {
            $ports = $ports.Substring(0, 20)
        }

        $icon  = if ($status -eq 'running') { '*' } else { 'o' }
        $sColor = if ($status -eq 'running') { 'Green' } else { 'Red' }
        $hColor = if ($health -eq 'healthy') { 'Green' } elseif ($health -eq 'N/A') { 'Yellow' } else { 'Red' }

        Write-Host '|  ' -ForegroundColor White -NoNewline
        Write-Host "$icon " -ForegroundColor $sColor -NoNewline
        $fmt1 = '{0,-10} '
        Write-Host ($fmt1 -f $svc) -NoNewline
        $fmt2 = '{0,-14} '
        Write-Host ($fmt2 -f $status) -NoNewline
        $fmt3 = '{0,-12} '
        Write-Host ($fmt3 -f $health) -ForegroundColor $hColor -NoNewline
        $fmt4 = '{0,-12}'
        Write-Host ($fmt4 -f $ports) -NoNewline
        Write-Host '|' -ForegroundColor White
    }

    Write-Host '+----------------------------------------------------------+' -ForegroundColor White
    $urlLine = '|  App URL : {0,-43} |'
    Write-Host ($urlLine -f $AppUrl) -ForegroundColor White
    Write-Host '+----------------------------------------------------------+' -ForegroundColor White
    Write-Host ''
}

function Show-Usage {
    Write-Host ''
    Write-Host 'Usage: .\manage.ps1 <command>' -ForegroundColor White
    Write-Host ''
    Write-Host '  setup    First-time setup: download files, start services, init DB'
    Write-Host '  start    Start all services'
    Write-Host '  stop     Stop all services (data is kept)'
    Write-Host '  reset    Wipe all data and reinitialise from scratch'
    Write-Host '  delete   Remove everything (containers, volumes, local files)'
    Write-Host '  update   Pull latest images and restart'
    Write-Host '  status   Show container status'
    Write-Host ''
}

# ════════════════════════════════════════════════════════════════════════════
# DISPATCH
# ════════════════════════════════════════════════════════════════════════════

switch ($Command) {
    'setup'  { Invoke-Setup  }
    'start'  { Invoke-Start  }
    'stop'   { Invoke-Stop   }
    'reset'  { Invoke-Reset  }
    'delete' { Invoke-Delete }
    'update' { Invoke-Update }
    'status' { Invoke-Status }
    default  { Show-Usage; exit 1 }
}
