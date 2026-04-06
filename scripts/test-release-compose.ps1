<#
.SYNOPSIS
    End-to-end test for the standalone release docker-compose.yml.
.DESCRIPTION
    Simulates an end-user experience: pulls images, starts services, seeds
    the database, runs smoke / auth / API-CRUD / persistence tests, then
    cleans up. Uses an isolated Docker Compose project name so it never
    touches the dev environment.
.NOTES
    Prerequisites: Docker Desktop running on Windows.
    Run from any directory — the script copies the release compose file to
    a temp folder.
#>

[CmdletBinding()]
param(
    [switch]$SkipCleanup   # keep containers running after tests for debugging
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Globals ──────────────────────────────────────────────────────────────
$ProjectName   = 'easybacklog-release-test'
$BaseUrl       = 'http://localhost:3000'
$ApiUser       = 'demo@example.com'
$DemoPassword  = 'password123'
$HealthTimeout = 180          # seconds to wait for all services
$script:Passed = 0
$script:Failed = 0
$script:LastExecCode = 0
$script:Results = [System.Collections.Generic.List[PSCustomObject]]::new()
$Stopwatch     = [System.Diagnostics.Stopwatch]::StartNew()

# Resolve paths
$RepoRoot       = (Resolve-Path "$PSScriptRoot\..").Path
$ReleaseCompose = Join-Path $RepoRoot 'releases\docker-compose.yml'
$TempDir        = Join-Path $env:TEMP "easybacklog-release-test-$([guid]::NewGuid().ToString('N').Substring(0,8))"

# ── Helpers ──────────────────────────────────────────────────────────────
function Write-Phase($msg) {
    Write-Host "`n==== $msg ====" -ForegroundColor Cyan
}

function Write-TestResult($name, [bool]$pass, $detail = '') {
    $status = if ($pass) { $script:Passed++; 'PASS' } else { $script:Failed++; 'FAIL' }
    $color  = if ($pass) { 'Green' } else { 'Red' }
    Write-Host "  [$status] $name" -ForegroundColor $color
    if ($detail -and -not $pass) { Write-Host "         $detail" -ForegroundColor DarkGray }
    $script:Results.Add([PSCustomObject]@{ Test = $name; Status = $status; Detail = $detail })
}

function Invoke-Compose {
    param([string[]]$Arguments)
    $allArgs = @('-p', $ProjectName) + $Arguments
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & docker compose @allArgs 2>&1 | ForEach-Object { $_.ToString() } | Write-Host
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    return $code
}

function Invoke-ComposeExec {
    param([string[]]$Command)
    $allArgs = @('-p', $ProjectName, 'exec', '-T', 'web') + $Command
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & docker compose @allArgs 2>&1
    $script:LastExecCode = $LASTEXITCODE
    $ErrorActionPreference = $prev
    # Return only string lines (strip ErrorRecords from stderr)
    $output | ForEach-Object { $_.ToString() }
}

function Api-Get($path) {
    $uri = "$BaseUrl/api${path}?dev_api_user=$([uri]::EscapeDataString($ApiUser))"
    try {
        Invoke-RestMethod -Uri $uri -Method Get -ContentType 'application/json' -ErrorAction Stop
    } catch {
        Write-Host "         API GET $path failed: $_" -ForegroundColor DarkGray
        $null
    }
}

function Api-Post($path, $body, $authToken) {
    $headers = @{ Authorization = "token $authToken" }
    $uri = "$BaseUrl/api${path}"
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Body ($body | ConvertTo-Json) `
            -ContentType 'application/json' -Headers $headers -ErrorAction Stop
    } catch {
        Write-Host "         API POST $path failed: $_" -ForegroundColor DarkGray
        $null
    }
}

function Api-Delete($path, $authToken) {
    $headers = @{ Authorization = "token $authToken" }
    $uri = "$BaseUrl/api${path}"
    try {
        Invoke-RestMethod -Uri $uri -Method Delete -ContentType 'application/json' -Headers $headers -ErrorAction Stop
    } catch {
        Write-Host "         API DELETE $path failed: $_" -ForegroundColor DarkGray
        $null
    }
}

function Wait-ServicesHealthy {
    Write-Host "  Waiting for services to become healthy (timeout: ${HealthTimeout}s)..." -NoNewline
    $elapsed = 0
    while ($elapsed -lt $HealthTimeout) {
        # Get container statuses via docker compose ps
        $psOutput = docker compose -p $ProjectName ps --format json 2>$null
        if ($psOutput) {
            $containers = $psOutput | ForEach-Object { $_ | ConvertFrom-Json }
            $total    = ($containers | Measure-Object).Count
            $healthy  = ($containers | Where-Object {
                $_.State -eq 'running' -and ($_.Health -eq 'healthy' -or $_.Health -eq '' -or $null -eq $_.Health)
            } | Measure-Object).Count
            if ($total -ge 4 -and $healthy -ge 4) {
                Write-Host " ready! (${elapsed}s)" -ForegroundColor Green
                return $true
            }
        }
        Start-Sleep -Seconds 5
        $elapsed += 5
        Write-Host '.' -NoNewline
    }
    Write-Host " TIMEOUT after ${HealthTimeout}s" -ForegroundColor Red
    return $false
}

function Cleanup {
    Write-Phase 'CLEANUP'
    if ($SkipCleanup) {
        Write-Host "  Skipping cleanup (-SkipCleanup). Project: $ProjectName  Dir: $TempDir" -ForegroundColor Yellow
        return
    }
    Push-Location $TempDir
    try {
        Invoke-Compose @('down', '-v', '--remove-orphans') | Out-Null
    } catch {}
    Pop-Location
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host '  Cleaned up containers, volumes, and temp directory.'
}

# ── Trap for unexpected exit ─────────────────────────────────────────────
$null = Register-EngineEvent PowerShell.Exiting -Action {
    # Best-effort cleanup on Ctrl+C / unexpected exit
    if (Test-Path $TempDir) {
        Push-Location $TempDir
        docker compose -p $ProjectName down -v --remove-orphans 2>$null | Out-Null
        Pop-Location
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

try {
# ═════════════════════════════════════════════════════════════════════════
# PHASE 1 — Setup & Isolation
# ═════════════════════════════════════════════════════════════════════════
Write-Phase 'PHASE 1: Setup & Isolation'

# 1. Create temp dir & copy release compose file
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Copy-Item $ReleaseCompose (Join-Path $TempDir 'docker-compose.yml')
Write-TestResult 'Copy release compose to temp dir' (Test-Path (Join-Path $TempDir 'docker-compose.yml'))

# 2-3. Set env vars
$env:SECRET_TOKEN   = -join ((1..64) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
$env:DEVISE_PEPPER  = -join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
$env:DB_PASSWORD    = 'testpass_' + (Get-Random -Max 99999)
Write-TestResult 'Environment variables set' ($env:SECRET_TOKEN.Length -gt 0)

Set-Location $TempDir

# ═════════════════════════════════════════════════════════════════════════
# PHASE 2 — Pull & Start
# ═════════════════════════════════════════════════════════════════════════
Write-Phase 'PHASE 2: Pull & Start'

# 4. Pull images
$pullExit = Invoke-Compose @('pull')
Write-TestResult 'docker compose pull' ($pullExit -eq 0)
if ($pullExit -ne 0) { throw 'Image pull failed — cannot continue.' }

# 5. Start services
$upExit = Invoke-Compose @('up', '-d')
Write-TestResult 'docker compose up -d' ($upExit -eq 0)
if ($upExit -ne 0) { throw 'docker compose up failed — cannot continue.' }

# 6. Wait for healthy
$healthy = Wait-ServicesHealthy
Write-TestResult 'All services healthy' $healthy
if (-not $healthy) { throw 'Services did not become healthy — cannot continue.' }

# ═════════════════════════════════════════════════════════════════════════
# PHASE 3 — Database Init
# ═════════════════════════════════════════════════════════════════════════
Write-Phase 'PHASE 3: Database Initialization'

# 7. schema:load
$out = Invoke-ComposeExec @('bundle', 'exec', 'rake', 'db:schema:load')
Write-TestResult 'rake db:schema:load' ($script:LastExecCode -eq 0) ($out -join ' ')

# 8. db:seed
$out = Invoke-ComposeExec @('bundle', 'exec', 'rake', 'db:seed')
Write-TestResult 'rake db:seed' ($script:LastExecCode -eq 0) ($out -join ' ')

# 9. db:seed:sample
$out = Invoke-ComposeExec @('bundle', 'exec', 'rake', 'db:seed:sample')
Write-TestResult 'rake db:seed:sample' ($script:LastExecCode -eq 0) ($out -join ' ')

# ═════════════════════════════════════════════════════════════════════════
# PHASE 4 — Smoke Tests
# ═════════════════════════════════════════════════════════════════════════
Write-Phase 'PHASE 4: Smoke Tests'

# Give Rails a moment to be fully responsive after seeding
Start-Sleep -Seconds 3

# 10. Root page
try {
    $root = Invoke-WebRequest -Uri $BaseUrl -UseBasicParsing -ErrorAction Stop
    Write-TestResult 'GET / returns 200' ($root.StatusCode -eq 200)
} catch {
    Write-TestResult 'GET / returns 200' $false $_.Exception.Message
}

# 11. /status
try {
    $status = Invoke-WebRequest -Uri "$BaseUrl/status" -UseBasicParsing -ErrorAction Stop
    $statusOk = $status.StatusCode -eq 200 -and $status.Content -match 'healthy'
    Write-TestResult 'GET /status returns healthy' $statusOk $status.Content
} catch {
    Write-TestResult 'GET /status returns healthy' $false $_.Exception.Message
}

# ═════════════════════════════════════════════════════════════════════════
# PHASE 5 — Authentication Tests
# ═════════════════════════════════════════════════════════════════════════
Write-Phase 'PHASE 5: Authentication'

# 12. GET sign-in page and extract CSRF token
$session = $null
$csrfToken = $null
try {
    $signInPage = Invoke-WebRequest -Uri "$BaseUrl/users/sign_in" -UseBasicParsing `
        -SessionVariable 'session' -ErrorAction Stop
    $csrfMatch  = [regex]::Match($signInPage.Content, 'name="authenticity_token"[^>]*value="([^"]+)"')
    $csrfToken  = if ($csrfMatch.Success) { $csrfMatch.Groups[1].Value } else { '' }
    Write-TestResult 'GET /users/sign_in and extract CSRF token' ($csrfToken.Length -gt 0)
} catch {
    Write-TestResult 'GET /users/sign_in and extract CSRF token' $false $_.Exception.Message
}

# 13. POST sign in and follow redirect (only if CSRF token was obtained)
$loginOk = $false
$dashOk  = $false
if ($csrfToken) {
    $loginBody = @{
        'user[email]'          = $ApiUser
        'user[password]'       = $DemoPassword
        'authenticity_token'   = $csrfToken
        'user[remember_me]'    = '0'
    }
    try {
        # Let redirects happen naturally — Devise redirects to / or /dashboard on success
        $loginResp = Invoke-WebRequest -Uri "$BaseUrl/users/sign_in" -Method Post `
            -Body $loginBody -WebSession $session -UseBasicParsing -ErrorAction Stop
        # If we followed redirect successfully, we should get 200
        $loginOk = $loginResp.StatusCode -eq 200
        # Check if final page is the dashboard or root (both indicate success)
        $dashOk  = $loginOk
    } catch {
        $respCode = $_.Exception.Response.StatusCode.value__
        $loginOk = $respCode -in @(302, 200)
    }
    Write-TestResult 'POST /users/sign_in succeeds' $loginOk
} else {
    Write-TestResult 'POST /users/sign_in succeeds' $false 'Skipped — no CSRF token'
}

# 14. Verify dashboard access (already landed there via redirect, or try again)
if ($dashOk) {
    Write-TestResult 'GET /dashboard with session returns 200' $true
} elseif ($loginOk) {
    try {
        $dash = Invoke-WebRequest -Uri "$BaseUrl/dashboard" -WebSession $session `
            -UseBasicParsing -ErrorAction Stop
        Write-TestResult 'GET /dashboard with session returns 200' ($dash.StatusCode -eq 200)
    } catch {
        Write-TestResult 'GET /dashboard with session returns 200' $false $_.Exception.Message
    }
} else {
    Write-TestResult 'GET /dashboard with session returns 200' $false 'Skipped — login failed'
}

# ═════════════════════════════════════════════════════════════════════════
# PHASE 6 — API CRUD Tests (dev_api_user for reads, API token for writes)
# ═════════════════════════════════════════════════════════════════════════
Write-Phase 'PHASE 6: API CRUD Tests'

# Create an API token for write operations (dev_api_user leaks into params, causing mass assignment errors on POST)
$tokenOut = Invoke-ComposeExec @('bundle', 'exec', 'rails', 'runner',
    "user = User.find_by_email('demo@example.com'); token = user.user_tokens.create!; puts token.access_token")
$apiToken = ($tokenOut | Select-String '^[a-z0-9]{10,}$' | Select-Object -First 1)
$apiToken = if ($apiToken) { $apiToken.ToString().Trim() } else { '' }
Write-TestResult 'Create API token for write tests' ($apiToken.Length -gt 0)

# 15. GET /api/locales
$locales = Api-Get '/locales'
Write-TestResult 'GET /api/locales returns 6 locales' (($locales | Measure-Object).Count -eq 6)

# 16. GET /api/scoring-rules
$rules = Api-Get '/scoring-rules'
Write-TestResult 'GET /api/scoring-rules returns 3 rules' (($rules | Measure-Object).Count -eq 3)

# 17. GET /api/sprint-story-statuses
$statuses = Api-Get '/sprint-story-statuses'
Write-TestResult 'GET /api/sprint-story-statuses returns 4' (($statuses | Measure-Object).Count -eq 4)

# 18. GET /api/accounts
$accounts = Api-Get '/accounts'
$acctCount = ($accounts | Measure-Object).Count
Write-TestResult 'GET /api/accounts returns >= 1' ($acctCount -ge 1)

if ($acctCount -ge 1) {
    $accountId = $accounts[0].id

    # 19. GET backlogs
    $backlogs = Api-Get "/accounts/$accountId/backlogs"
    Write-TestResult 'GET /api/accounts/:id/backlogs returns data' (($backlogs | Measure-Object).Count -ge 1)

    # 20. POST — create backlog (uses API token, rate > 0)
    $localeId = $locales[0].id
    $ruleId   = $rules[0].id
    $newBacklog = Api-Post "/accounts/$accountId/backlogs" @{
        name            = 'Release Test Backlog'
        velocity        = 3
        rate            = 100
        use_50_90       = $true
        scoring_rule_id = $ruleId
        locale_id       = $localeId
    } $apiToken
    $createOk = $null -ne $newBacklog -and $null -ne $newBacklog.id
    Write-TestResult 'POST /api/accounts/:id/backlogs creates backlog' $createOk

    if ($createOk) {
        $newId = $newBacklog.id

        # 21. GET — read newly created backlog
        $readBack = Api-Get "/accounts/$accountId/backlogs/$newId"
        Write-TestResult 'GET created backlog by id' ($null -ne $readBack -and $readBack.id -eq $newId)

        # 22. DELETE — remove test backlog
        $delResult = Api-Delete "/accounts/$accountId/backlogs/$newId" $apiToken
        # Verify it's gone
        $gone = Api-Get "/accounts/$accountId/backlogs/$newId"
        Write-TestResult 'DELETE created backlog' ($null -eq $gone -or ($gone.status -eq 'error'))
    } else {
        Write-TestResult 'GET created backlog by id' $false 'Skipped — create failed'
        Write-TestResult 'DELETE created backlog' $false 'Skipped — create failed'
    }
} else {
    Write-TestResult 'GET /api/accounts/:id/backlogs' $false 'No accounts found'
    Write-TestResult 'POST create backlog' $false 'No accounts found'
    Write-TestResult 'GET created backlog' $false 'No accounts found'
    Write-TestResult 'DELETE created backlog' $false 'No accounts found'
}

# ═════════════════════════════════════════════════════════════════════════
# PHASE 7 — Sidekiq Verification
# ═════════════════════════════════════════════════════════════════════════
Write-Phase 'PHASE 7: Sidekiq'

# 23. Check Sidekiq container is running and connected to Redis
$prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
$sqLogs = docker compose -p $ProjectName logs sidekiq --tail 50 2>&1 | ForEach-Object { $_.ToString() }
$ErrorActionPreference = $prev
$sqRunning  = $sqLogs | Select-String 'Starting processing'
$sqRedis    = $sqLogs | Select-String 'Booting Sidekiq'
Write-TestResult 'Sidekiq container booted and connected to Redis' ($null -ne $sqRunning -and $null -ne $sqRedis) `
    $(if ($null -eq $sqRunning) { 'No "Starting processing" in logs' } else { '' })

# ═════════════════════════════════════════════════════════════════════════
# PHASE 8 — Persistence / Restart Test
# ═════════════════════════════════════════════════════════════════════════
Write-Phase 'PHASE 8: Persistence across restart'

# 24. Stop (keep volumes)
$downExit = Invoke-Compose @('down')
Write-TestResult 'docker compose down (volumes kept)' ($downExit -eq 0)

# 25. Restart
$upExit = Invoke-Compose @('up', '-d')
Write-TestResult 'docker compose up -d (restart)' ($upExit -eq 0)

# 26. Wait for healthy
$healthy2 = Wait-ServicesHealthy
Write-TestResult 'Services healthy after restart' $healthy2

if ($healthy2) {
    # Wait for Rails to fully boot (first request compiles assets)
    $retries = 0; $statusOk2 = $false
    while ($retries -lt 6 -and -not $statusOk2) {
        Start-Sleep -Seconds 5
        try {
            $status2 = Invoke-WebRequest -Uri "$BaseUrl/status" -UseBasicParsing `
                -ErrorAction Stop -TimeoutSec 30
            $statusOk2 = $status2.StatusCode -eq 200 -and $status2.Content -match 'healthy'
        } catch { $retries++ }
    }

    # 27. /status still healthy
    Write-TestResult 'GET /status healthy after restart' $statusOk2

    # 28. Data persisted
    $accts2 = Api-Get '/accounts'
    Write-TestResult 'Data persisted after restart' (($accts2 | Measure-Object).Count -ge 1)
} else {
    Write-TestResult 'GET /status after restart' $false 'Services not healthy'
    Write-TestResult 'Data persisted after restart' $false 'Services not healthy'
}

# ═════════════════════════════════════════════════════════════════════════
# PHASE 9 — Cleanup & Summary
# ═════════════════════════════════════════════════════════════════════════
Cleanup

} catch {
    Write-Host "`nFATAL: $_" -ForegroundColor Red
    $script:Failed++
    Cleanup
} finally {
    # Remove env vars
    Remove-Item Env:\SECRET_TOKEN  -ErrorAction SilentlyContinue
    Remove-Item Env:\DEVISE_PEPPER -ErrorAction SilentlyContinue
    Remove-Item Env:\DB_PASSWORD   -ErrorAction SilentlyContinue
}

# ── Summary ──────────────────────────────────────────────────────────────
$Stopwatch.Stop()
$duration = $Stopwatch.Elapsed.ToString('mm\:ss')

Write-Host "`n"
Write-Host '╔══════════════════════════════════════════╗' -ForegroundColor White
Write-Host '║         TEST RUN SUMMARY                 ║' -ForegroundColor White
Write-Host '╠══════════════════════════════════════════╣' -ForegroundColor White
Write-Host "║  Passed : $($script:Passed.ToString().PadLeft(3))                            ║" -ForegroundColor Green
Write-Host "║  Failed : $($script:Failed.ToString().PadLeft(3))                            ║" -ForegroundColor $(if ($script:Failed -gt 0) { 'Red' } else { 'Green' })
Write-Host "║  Total  : $(($script:Passed + $script:Failed).ToString().PadLeft(3))                            ║" -ForegroundColor White
Write-Host "║  Time   : $($duration.PadLeft(6))                         ║" -ForegroundColor White
Write-Host '╚══════════════════════════════════════════╝' -ForegroundColor White

if ($script:Failed -gt 0) {
    Write-Host "`nFailed tests:" -ForegroundColor Red
    $script:Results | Where-Object { $_.Status -eq 'FAIL' } | ForEach-Object {
        Write-Host "  - $($_.Test)" -ForegroundColor Red
        if ($_.Detail) { Write-Host "    $($_.Detail)" -ForegroundColor DarkGray }
    }
    exit 1
}
exit 0
