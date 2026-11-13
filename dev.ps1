#Requires -Version 7.0

<#
.SYNOPSIS
    Runs the whole ERE stack in development: SQL Server (Docker), the Resolution
    Engine API, and the Shiny Computing Machine UI.

.DESCRIPTION
    Starts the three dev dependencies in order and blocks until you stop it:

      1. ere-infra/docker-compose.yml    -> mcr.microsoft.com/mssql/server:2022 on :1433 (ere-db)
      2. ere-infra/resolution-engine     -> https://localhost:7150 + http://localhost:5250
                                            (dotnet run --launch-profile https)
      3. ere-infra/shiny-computing-machine -> https://localhost:4250 (npm start -- --ssl)

    Each service's output is interleaved into this one console with a color-coded
    [engine] / [ui] prefix; SQL Server logs to Docker, so it gets its own step output.

    Startup is gated on readiness, not on process spawn: SQL Server must answer
    sqlcmd (a rejected login also counts as ready - see Test-DbReady - because the
    data volume keeps the SA password from its first initialization; if the image
    ships no sqlcmd at all, a TCP accept on 1433 is used instead), the API must
    answer GET /api/htn/ping with Backend "Online" (proving Kestrel is up and the
    controller pipeline runs; the DB check it reports is informational, because the
    connection string is supplied per-request by the UI), and the UI must answer
    https on 4250. Only then is the ready banner printed.

    Stop with Ctrl+C or Q (Enter also stops); SQL Server is left running so the
    next start is fast. Pass -StopAll to bring the container down too.

.PARAMETER StopAll
    Also stop the SQL Server container when the script exits. The data volume is
    always kept; this is never a destructive reset.

.PARAMETER ExitAfterReady
    Shut down automatically once all readiness gates pass instead of waiting for a
    keypress. For smoke-testing the stack in a non-interactive session; exits 1 if
    any gate times out.

.EXAMPLE
    ./dev.ps1

.EXAMPLE
    ./dev.ps1 -StopAll

.EXAMPLE
    ./dev.ps1 -ExitAfterReady
#>
[CmdletBinding()]
param(
    [switch]$StopAll,
    [switch]$ExitAfterReady
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Mirrors ere-infra/resolution-engine/Properties/launchSettings.json (the "https"
# profile binds https://0.0.0.0:7150 and http://0.0.0.0:5250) and
# ere-infra/shiny-computing-machine/angular.json (serve.port 4250). The UI's
# APP_CONFIG.apiUrl points at http://localhost:5250/api, so the API gate polls the
# http listener of the "https" profile - the same one the browser uses.
$ApiPort = 5250
$ApiHttpsPort = 7150
$UiPort = 4250
$DbPort = 1433

$EreRoot = $PSScriptRoot
$Root = Split-Path -Parent $EreRoot
$ComposeFile = Join-Path $EreRoot 'docker-compose.yml'
$EngineProject = Join-Path $EreRoot 'resolution-engine'
$GuiDir = Join-Path $EreRoot 'shiny-computing-machine'
$ApiUrl = "http://localhost:$ApiPort"
$ApiHttpsUrl = "https://localhost:$ApiHttpsPort"
$UiUrl = "https://localhost:$UiPort"
$DbContainer = 'ere-db'

# Readiness budgets. The SQL Server budget has to cover InnoDB-style recovery of a
# clean shutdown plus, on first run, a multi-GB image pull that happens inside
# `docker compose up`. The API budget has to cover a cold `dotnet build`.
$DbReadyTimeoutSec = 240
$ApiReadyTimeoutSec = 180
$UiReadyTimeoutSec = 180

try { $Host.UI.RawUI.WindowTitle = 'ERE dev' } catch { }

function Write-Step {
    param([string]$Message)
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor DarkGray
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Yellow
}

function Fail {
    param([string]$Message)
    Write-Host ''
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-PortOwner {
    param([int]$Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -eq $connection) { return $null }
    $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
    $name = if ($null -eq $process) { 'unknown' } else { $process.ProcessName }
    return "pid $($connection.OwningProcess) ($name)"
}

function Assert-PortFree {
    param([Parameter(Mandatory)][int]$Port, [Parameter(Mandatory)][string]$Purpose)

    $owner = Get-PortOwner -Port $Port
    if ($null -eq $owner) { return }

    $hint = if ($Port -eq $DbPort) {
        'another SQL Server already owns it; stop it, or change the published 1433 in ere-infra/docker-compose.yml'
    }
    elseif ($Port -eq $ApiPort -or $Port -eq $ApiHttpsPort) {
        'the Resolution Engine is already running; stop it first'
    }
    else {
        'another dev server already owns it; stop it first'
    }
    Fail "Port $Port (needed for $Purpose) is already in use by $owner. $hint."
}

function Invoke-Native {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$WorkDir = $Root
    )

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $FilePath @Arguments 2>&1 | Out-String
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }
    return [pscustomobject]@{ Output = $output; ExitCode = $code }
}

# Resolves a tool to something Process.StartInfo can actually launch. npm/npx resolve
# to npm.ps1 on this machine, and Start-Process rejects a .ps1 with
# "%1 is not a valid Win32 application" - so prefer the sibling .cmd shim.
function Resolve-Launcher {
    param([Parameter(Mandatory)][string]$Name)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) { Fail "$Name is not on PATH." }

    if ($command.CommandType -eq 'Application') { return $command.Source }

    $candidate = Join-Path (Split-Path -Parent $command.Source) "$Name.cmd"
    if (Test-Path -LiteralPath $candidate) { return $candidate }
    return $command.Source
}

# 'compose' must precede its subcommand and own the global flags: `docker --file ...
# compose up` is not accepted by the compose CLI, and bare `docker up` is not a thing.
function Invoke-Compose {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $result = Invoke-Native -FilePath 'docker' `
        -Arguments (@('compose', '--file', $ComposeFile) + $Arguments)
    if ($result.ExitCode -ne 0) {
        Write-Host $result.Output -ForegroundColor DarkRed
        Fail "docker compose $($Arguments -join ' ') failed with exit code $($result.ExitCode)."
    }
    return $result
}

# --- Service processes ------------------------------------------------------
#
# Each child is launched with redirected pipes and its output is prefixed live by a
# small C# pump (see Add-Type below).
#
# The obvious PowerShell version of this - a DataReceivedEventHandler scriptblock
# calling Write-Host - cannot work: those callbacks fire on threadpool threads with no
# PowerShell runspace, so Write-Host throws an unhandled PSInvalidOperationException
# and takes the whole script down. Doing the writing in C# sidesteps the runspace
# entirely. Redirecting to files and tailing them also fails, because Start-Process
# holds those files exclusively for the child's lifetime.

Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;

public static class EreStreamPump
{
    private static readonly object Gate = new object();

    public static void Attach(Process process, string tag, ConsoleColor outColor, ConsoleColor errColor)
    {
        process.OutputDataReceived += (sender, args) => { if (args.Data != null) WriteLine(tag, args.Data, outColor); };
        process.ErrorDataReceived += (sender, args) => { if (args.Data != null) WriteLine(tag, args.Data, errColor); };
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();
    }

    private static void WriteLine(string tag, string line, ConsoleColor color)
    {
        lock (Gate)
        {
            ConsoleColor previous = Console.ForegroundColor;
            try
            {
                Console.ForegroundColor = color;
                Console.Out.WriteLine("[" + tag + "] " + line);
                Console.Out.Flush();
            }
            finally
            {
                Console.ForegroundColor = previous;
            }
        }
    }
}
'@

$script:Services = [System.Collections.Generic.List[object]]::new()

function Start-ServiceProcess {
    param(
        [Parameter(Mandatory)][string]$Tag,
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkDir,
        [Parameter(Mandatory)][ConsoleColor]$Color
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = Resolve-Launcher -Name $FilePath
    $startInfo.WorkingDirectory = $WorkDir
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $startInfo.ArgumentList.Add($argument) }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $process.EnableRaisingEvents = $true

    if (-not $process.Start()) {
        $process.Dispose()
        Fail "Could not start [$Tag] ($FilePath)."
    }

    # Registered before pumping: from here on this is a live child that the finally
    # block must be able to kill. `dotnet run` and `ng serve` each spawn a grandchild
    # (ResolutionEngine.exe, node) that survives killing only the parent, so losing
    # track of it would lock bin/ and break the next `dotnet build`.
    $service = [pscustomobject]@{
        Tag     = $Tag
        Process = $process
        Color   = $Color
    }
    $script:Services.Add($service)

    [EreStreamPump]::Attach($process, $Tag, $Color, [ConsoleColor]::DarkYellow)
}

function Stop-ServiceProcess {
    param([Parameter(Mandatory)][object]$Service)

    $process = $Service.Process
    if ($process.HasExited) { return }

    Write-Host "[$($Service.Tag)] stopping..." -ForegroundColor $Service.Color
    # /T matters: `dotnet run` and `ng serve` each spawn a child (ResolutionEngine.exe,
    # node) that survives killing only the parent.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        & taskkill.exe /PID $process.Id /T /F | Out-Null
    }
    finally {
        $ErrorActionPreference = $previous
    }

    try { $process.WaitForExit(10000) | Out-Null } catch { }
}

function Stop-AllServices {
    foreach ($service in $script:Services) { Stop-ServiceProcess -Service $service }
    $script:Services.Clear()
}

# Both readiness gates share this: a service that died mid-wait must not be
# mistaken for "still starting".
function Assert-ServiceAlive {
    param([Parameter(Mandatory)][string]$Tag)

    $code = 0
    foreach ($service in $script:Services) {
        if ($service.Tag -eq $Tag) { $code = $service.Process.ExitCode }
    }
    Fail "[$Tag] exited (exit code $code) during startup. See the [$Tag] lines above."
}

function Wait-ApiHealthy {
    param([Parameter(Mandatory)][string]$Tag, [int]$TimeoutSec)

    $url = "$ApiUrl/api/htn/ping"
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $lastError = $null
    while ((Get-Date) -lt $deadline) {
        foreach ($service in $script:Services) {
            if ($service.Tag -eq $Tag -and $service.Process.HasExited) { Assert-ServiceAlive -Tag $Tag }
        }
        try {
            # 20s per attempt: the ping handler runs EnsureCreated/CanConnect before it
            # answers, so a per-request timeout shorter than the SQL login timeout would
            # abort every poll while the server is perfectly healthy.
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 20 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $payload = $response.Content | ConvertFrom-Json
                $backend = $payload.PSObject.Properties['Backend']
                if ($null -ne $backend -and $backend.Value -eq 'Online') { return $true }
                $lastError = if ($null -eq $backend) { 'no Backend field' } else { "Backend=$($backend.Value)" }
            }
            else {
                $lastError = "HTTP $($response.StatusCode)"
            }
        }
        catch {
            $lastError = $_.Exception.Message
        }
        Start-Sleep -Seconds 2
    }
    Write-Warn "[$Tag] never answered $url within ${TimeoutSec}s (last: $lastError)."
    return $false
}

function Wait-HttpOk {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][int]$TimeoutSec,
        [Parameter(Mandatory)][string]$Tag
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $lastError = $null
    while ((Get-Date) -lt $deadline) {
        foreach ($service in $script:Services) {
            if ($service.Tag -eq $Tag -and $service.Process.HasExited) { Assert-ServiceAlive -Tag $Tag }
        }
        try {
            # The dev server serves a self-signed certificate because of --ssl.
            $response = Invoke-WebRequest -Uri $Url -TimeoutSec 5 -SkipCertificateCheck -ErrorAction Stop
            if ($response.StatusCode -eq 200) { return $true }
            $lastError = "HTTP $($response.StatusCode)"
        }
        catch {
            $lastError = $_.Exception.Message
        }
        Start-Sleep -Seconds 2
    }
    Write-Warn "[$Tag] did not answer $Url within ${TimeoutSec}s (last: $lastError)."
    return $false
}

# --- SQL Server readiness ---------------------------------------------------
#
# The 2022 image ships sqlcmd under /opt/mssql-tools18 (ODBC 18, needs -C to trust
# the self-signed server cert); older layers ship /opt/mssql-tools (ODBC 17, no -C
# flag). Probe once, then keep using whichever path exists. If the image ships
# neither, fall back to "port 1433 accepts TCP", which still catches the two
# failures that matter here: container not running and SQL not yet listening.
#
# Readiness means "the server processed a login", not "our guessed password is
# right": MSSQL_SA_PASSWORD is only applied when the volume is first initialized,
# so a pre-existing ere-db can legitimately reject the password compose would set
# today. Login failures therefore open the gate and set $script:DbAuthMismatch.

$script:SqlCmdPath = $null
$script:SqlCmdResolved = $false
$script:DbAuthMismatch = $false

function Resolve-SqlCmd {
    if ($script:SqlCmdResolved) { return $script:SqlCmdPath }
    foreach ($candidate in @('/opt/mssql-tools18/bin/sqlcmd', '/opt/mssql-tools/bin/sqlcmd')) {
        $result = Invoke-Native -FilePath 'docker' -Arguments @('exec', $DbContainer, 'test', '-x', $candidate)
        if ($result.ExitCode -eq 0) {
            $script:SqlCmdPath = $candidate
            break
        }
    }
    $script:SqlCmdResolved = $true
    if ($null -eq $script:SqlCmdPath) {
        Write-Warn 'sqlcmd not found in the image; falling back to a TCP readiness probe on 1433.'
    }
    return $script:SqlCmdPath
}

function Test-DbReady {
    param([Parameter(Mandatory)][string]$SaPassword)

    $sqlCmd = Resolve-SqlCmd
    if ($null -ne $sqlCmd) {
        $arguments = @('exec', $DbContainer, $sqlCmd, '-S', 'localhost', '-U', 'sa', '-P', $SaPassword,
            '-Q', 'SELECT 1', '-b', '-r', '1')
        if ($sqlCmd -like '/opt/mssql-tools18/*') { $arguments += '-C' }
        $result = Invoke-Native -FilePath 'docker' -Arguments $arguments
        if ($result.ExitCode -eq 0) { return $true }

        # A rejected login still proves the server is fully up: it parsed the TDS
        # handshake and ran the auth pipeline. That happens when the data volume
        # was initialized with a different SA password than the one compose would
        # set today (MSSQL_SA_PASSWORD only applies on first initialization), so
        # treat it as ready but record the mismatch for the banner.
        if ($result.Output -match '18456|Login failed') {
            $script:DbAuthMismatch = $true
            return $true
        }
        return $false
    }

    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        try {
            return $client.ConnectAsync('127.0.0.1', $DbPort).Wait(2000)
        }
        finally {
            $client.Dispose()
        }
    }
    catch {
        return $false
    }
}

# The SA password has to be the one compose actually uses: shell env wins over the
# .env file, which wins over the default baked into docker-compose.yml.
function Get-SaPassword {
    if (-not [string]::IsNullOrEmpty($env:MSSQL_SA_PASSWORD)) { return $env:MSSQL_SA_PASSWORD }
    $envFile = Join-Path $EreRoot '.env'
    if (Test-Path -LiteralPath $envFile) {
        foreach ($line in (Get-Content -LiteralPath $envFile)) {
            if ($line -match '^\s*MSSQL_SA_PASSWORD\s*=\s*(?<value>.*)\s*$') {
                return $Matches.value.Trim("'`"")
            }
        }
    }
    return 'Password123!'
}

# --- Preflight --------------------------------------------------------------

Write-Host 'ERE - development stack' -ForegroundColor White
Write-Info $Root

Write-Step 'Preflight'

if (-not (Test-Command 'dotnet')) { Fail 'dotnet is not on PATH. Install the .NET 9 SDK.' }
if (-not (Test-Command 'docker')) { Fail 'docker is not on PATH. Install Docker Desktop.' }
if (-not (Test-Command 'node')) { Fail 'node is not on PATH. Install Node.js.' }
if (-not (Test-Command 'npm')) { Fail 'npm is not on PATH. npm ships with Node.js.' }
Write-Ok 'dotnet, docker, node, npm found'

if (-not (Test-Path -LiteralPath $ComposeFile)) { Fail "compose file not found: $ComposeFile" }
if (-not (Test-Path -LiteralPath $EngineProject)) { Fail "engine project not found: $EngineProject" }
if (-not (Test-Path -LiteralPath (Join-Path $EngineProject 'ResolutionEngine.csproj'))) {
    Fail "ResolutionEngine.csproj not found in $EngineProject"
}
if (-not (Test-Path -LiteralPath $GuiDir)) { Fail "UI directory not found: $GuiDir" }

$engine = Invoke-Native -FilePath 'docker' -Arguments @('version', '--format', '{{.Server.Version}}')
if ($engine.ExitCode -ne 0) {
    Fail @'
The Docker daemon is not reachable, so SQL Server cannot start.
Start Docker Desktop and wait until it reports "Engine running", then re-run this script.
'@
}
Write-Ok "Docker engine $($engine.Output.Trim())"

# The DB port is checked later, next to the container: when ere-db is already
# running, Docker's wslrelay owns 1433 on our behalf and a free-port check here
# would fail on the normal re-run case.
Assert-PortFree -Port $ApiPort -Purpose 'the API (http)'
Assert-PortFree -Port $ApiHttpsPort -Purpose 'the API (https)'
Assert-PortFree -Port $UiPort -Purpose 'the UI'
Write-Ok "ports $ApiPort, $ApiHttpsPort, $UiPort are free"

$saPassword = Get-SaPassword

# --- Bring the stack up, then hold it open ----------------------------------
#
# Everything from here is inside try/finally: Fail() calls exit, and an unhandled
# Ctrl+C unwinds the same way, so the API and UI are always torn down. Leaving a
# ResolutionEngine.exe behind locks bin/ and breaks the next `dotnet build`.
$smokeExit = $false
$exitCode = 0
try {
    Write-Step 'SQL Server (Docker)'

    # A running container means Docker already owns 1433 on our behalf, which is
    # the normal re-run case - only demand a free 1433 when we still have to bind it.
    $running = (& docker ps --filter "name=^/$DbContainer`$" --filter 'status=running' --format '{{.Names}}' 2>$null | Out-String).Trim()
    if ($running -eq $DbContainer) {
        Write-Ok "$DbContainer is already running (its data volume persists)"
    }
    else {
        Write-Info 'starting (the first run pulls mcr.microsoft.com/mssql/server:2022, which can take a while)'
        Invoke-Compose -Arguments @('up', '--detach', 'db') | Out-Null
        Write-Ok "$DbContainer started"
    }

    $dbReady = $false
    $dbDeadline = (Get-Date).AddSeconds($DbReadyTimeoutSec)
    while ((Get-Date) -lt $dbDeadline) {
        if (Test-DbReady -SaPassword $saPassword) { $dbReady = $true; break }
        Write-Info "waiting for SQL Server ($([int]($dbDeadline - (Get-Date)).TotalSeconds)s left)..."
        Start-Sleep -Seconds 3
    }
    if (-not $dbReady) { Fail "SQL Server did not become ready within ${DbReadyTimeoutSec}s." }
    if ($script:DbAuthMismatch) {
        Write-Warn "SQL Server is up on $DbPort, but it rejected the SA password this script guessed ('$saPassword')."
        Write-Info "MSSQL_SA_PASSWORD only applies the first time the volume is initialized, so ere-db keeps whatever it was created with."
        Write-Info 'Use that original password when filling in the connection string manager in the UI.'
    }
    else {
        Write-Ok "SQL Server accepting connections on $DbPort (server 'localhost,$DbPort', user 'sa')"
    }

    Write-Step 'Frontend dependencies'

    if (Test-Path -LiteralPath (Join-Path $GuiDir 'node_modules')) {
        Write-Ok 'node_modules present (skipped)'
    }
    else {
        Write-Info 'installing (npm ci; first run only)'
        $install = Invoke-Native -FilePath 'npm' -Arguments @('ci') -WorkDir $GuiDir
        if ($install.ExitCode -ne 0) {
            Write-Host $install.Output -ForegroundColor DarkRed
            Fail "npm ci failed with exit code $($install.ExitCode)."
        }
        Write-Ok 'dependencies installed'
    }

    Write-Step "API (:$ApiPort/:$ApiHttpsPort) and UI (:$UiPort)"

    Write-Info "API  $ApiUrl  (+ $ApiHttpsUrl)"
    Start-ServiceProcess -Tag 'engine' -FilePath 'dotnet' `
        -Arguments @('run', '--project', $EngineProject, '--launch-profile', 'https') `
        -WorkDir $Root -Color Cyan

    Write-Info "UI   $UiUrl"
    # npm start runs the package.json prestart hook (tools/build-script-index.mjs)
    # that a bare `ng serve` would skip, and already pins --port 4250.
    Start-ServiceProcess -Tag 'ui' -FilePath 'npm' `
        -Arguments @('start', '--', '--ssl') `
        -WorkDir $GuiDir -Color Magenta

    Write-Info 'waiting for both (first run also does a build)'

    $apiReady = Wait-ApiHealthy -Tag 'engine' -TimeoutSec $ApiReadyTimeoutSec
    $uiReady = Wait-HttpOk -Url $UiUrl -TimeoutSec $UiReadyTimeoutSec -Tag 'ui'

    # Drain whatever landed in the gap between the last poll and the banner, so the
    # gates can pass a moment before the final lines clear the pipes.
    Start-Sleep -Milliseconds 750

    Write-Host ''
    if ($apiReady -and $uiReady) {
        Write-Host 'Stack is up.' -ForegroundColor Green
        Write-Host "    UI       $UiUrl"
        Write-Host "    API      $ApiUrl"
        Write-Host "    API TLS  $ApiHttpsUrl"
        Write-Host "    Ping     $ApiUrl/api/htn/ping"
        if ($script:DbAuthMismatch) {
            Write-Host "    SQL      localhost,$DbPort  (user 'sa' - password is NOT the one this script guessed; use ere-db's original)" -ForegroundColor Yellow
        }
        else {
            Write-Host "    SQL      localhost,$DbPort  (user 'sa'; connection strings are set from the UI's connection string manager)" -ForegroundColor DarkGray
        }
    }
    else {
        if (-not $apiReady) { Write-Host 'The API never became healthy.' -ForegroundColor Red }
        if (-not $uiReady) { Write-Host "The UI never served https on $UiPort." -ForegroundColor Red }
        Write-Host 'Leaving the services up so you can read the logs above; press Q to stop.' -ForegroundColor DarkGray
    }

    if ($ExitAfterReady) {
        if ($apiReady -and $uiReady) {
            Write-Ok '-ExitAfterReady: both readiness gates passed'
        }
        else {
            # Let the finally block tear the services down first, then fail.
            $exitCode = 1
        }
        $smokeExit = $true
    }
    else {
        Write-Host ''
        Write-Host 'Press Ctrl+C or Q to stop the API and UI.' -ForegroundColor DarkGray
    }

    if (-not $smokeExit -and [Environment]::UserInteractive) {
        try {
            # Take over Ctrl+C so it arrives as a keypress we handle rather than a
            # hard kill that would skip the finally block.
            [Console]::TreatControlCAsInput = $true
            while ($true) {
                if (-not [Console]::KeyAvailable) { Start-Sleep -Milliseconds 200; continue }
                $key = [Console]::ReadKey($true)
                $isCtrlC = $key.Key -eq [ConsoleKey]::C -and $key.Modifiers -eq [ConsoleModifiers]::Control
                if ($isCtrlC -or $key.Key -eq [ConsoleKey]::Q -or $key.Key -eq [ConsoleKey]::Enter) { break }
            }
        }
        catch {
            # No usable console (redirected stdin): park and let the host stop us.
            while ($true) { Start-Sleep -Seconds 5 }
        }
    }
    elseif (-not $smokeExit) {
        while ($true) { Start-Sleep -Seconds 5 }
    }
}
finally {
    Write-Host ''
    Write-Step 'Shutting down'

    Stop-AllServices
    Write-Ok 'API and UI stopped'

    if ($StopAll) {
        Write-Info "stopping the $DbContainer container (data volume kept)"
        Invoke-Compose -Arguments @('down') | Out-Null
        Write-Ok 'SQL Server stopped'
    }
    else {
        Write-Info "$DbContainer left running; ./dev.ps1 -StopAll stops it too"
    }

    Write-Host ''
    Write-Host 'Done.' -ForegroundColor Green

    if ($exitCode -ne 0) { exit $exitCode }
}
