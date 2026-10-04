[CmdletBinding()]
param(
    [Parameter(Position=0)][ValidateSet('test','scenario','compare','dump','map','lint')][string]$Command = 'test',
    [Parameter(Position=1)][string]$Name = '',
    [Parameter(Position=2)][string]$VariantA = '',
    [Parameter(Position=3)][string]$VariantB = '',
    [switch]$Render,
    [switch]$Play
)
$ErrorActionPreference = 'Stop'
if ($Render -and $Play) { throw 'Choose either -Render (rule screenshots) or -Play (physical input scenarios).' }
$projectRoot = Split-Path $PSScriptRoot -Parent
if ($Command -eq 'lint') {
    Write-Output 'Heuristic regex lint (not a proof of correctness).'
    $findings = @()
    $rulesRoot = Join-Path $projectRoot 'game/rules'
    if (Test-Path -LiteralPath $rulesRoot) {
        foreach ($file in Get-ChildItem -LiteralPath $rulesRoot -Recurse -File -Filter '*.gd') {
            $lineNumber = 0
            foreach ($line in Get-Content -LiteralPath $file.FullName) {
                $lineNumber++
                if ($line.TrimStart().StartsWith('#')) { continue }
                if ($line -match '(?<![\w.])(?:randf|randi|randf_range|randi_range|randomize)\s*\(' -or
                    $line -match '\b(?:Audio\w*|CPUParticles\w*|GPUParticles\w*|Camera\w*|Tween|Control|CanvasLayer|UI)\b' -or
                    $line -match '\bvar\s+\w+\s*=(?!=)' -or $line -match '\.cosmetic\b') {
                    $findings += "$($file.FullName):$lineNumber : $line"
                }
            }
        }
    }
    foreach ($folder in @('game','addons/agent_kit')) {
        $folderPath = Join-Path $projectRoot $folder
        if (-not (Test-Path -LiteralPath $folderPath)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $folderPath -Recurse -File -Filter '*.gd') {
            $lineNumber = 0
            foreach ($line in Get-Content -LiteralPath $file.FullName) {
                $lineNumber++
                if ($line.TrimStart().StartsWith('#')) { continue }
                if ($folder -eq 'addons/agent_kit' -and $line -match '\bvar\s+\w+\s*=(?!=)') {
                    $findings += "$($file.FullName):$lineNumber : untyped kit variable"
                }
                if ($folder -eq 'game' -and $line -match '(?:FileAccess\.(?:open|WRITE)|ResourceSaver\.save|DirAccess\.(?:remove|rename|copy)|store_\w+).*(?:res://)?addons[/\\]agent_kit') {
                    $findings += "$($file.FullName):$lineNumber : game code writes kit files"
                }
            }
        }
    }
    $manifestPath = Join-Path $projectRoot 'addons/agent_kit/install_manifest.json'
    if (Test-Path -LiteralPath $manifestPath) {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        foreach ($entry in $manifest.files.PSObject.Properties) {
            $filePath = Join-Path $projectRoot $entry.Name
            if (-not (Test-Path -LiteralPath $filePath) -or (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.Value) {
                $findings += "Installed kit file differs from its manifest: $($entry.Name)"
            }
        }
    }
    if ($findings.Count) { $findings | Write-Output; exit 1 }
    Write-Output 'PASS: no heuristic violations found.'
    exit 0
}
$godotBin = $env:GODOT_BIN
$localConfig = Join-Path $projectRoot 'kit.local.json'
if (-not $godotBin -and (Test-Path -LiteralPath $localConfig)) {
    $godotBin = (Get-Content -LiteralPath $localConfig -Raw | ConvertFrom-Json).godot_bin
}
if (-not $godotBin -or -not (Test-Path -LiteralPath $godotBin -PathType Leaf)) {
    throw 'Set GODOT_BIN or put a valid godot_bin path in kit.local.json (see kit.local.example.json).'
}
# Windows PowerShell 5.1 turns each line a native program writes to stderr into a terminating
# error under 'Stop'. Godot prints harmless warnings there, so run it under 'Continue', keep every
# line as plain text and let the checks below decide what counts as a failure.
function Invoke-Godot([string[]]$Arguments) {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $lines = @(& $godotBin @Arguments 2>&1 | ForEach-Object { "$_" })
        return @{ Output = $lines; Exit = $LASTEXITCODE }
    }
    finally { $ErrorActionPreference = $previousPreference }
}
$profilePath = Join-Path $projectRoot 'reports/engine-profile'
New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
# Reports hold screenshots and install-smoke projects; Godot must not import or scan them.
$reportsIgnore = Join-Path $projectRoot 'reports/.gdignore'
if (-not (Test-Path -LiteralPath $reportsIgnore)) { New-Item -ItemType File -Path $reportsIgnore -Force | Out-Null }
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $profilePath
    $import = Invoke-Godot @('--headless', '--path', $projectRoot, '--editor', '--import', '--quit')
    $importOutput = $import.Output
    $importExit = $import.Exit
    $importOutput | Set-Content -LiteralPath (Join-Path $profilePath 'import.log') -Encoding utf8
    if ($importExit -ne 0 -or ($importOutput -join "`n") -match 'SCRIPT ERROR:|Parse Error:|Failed to load script') {
        $importOutput | Write-Output
        exit 1
    }
    $engineArgs = @('--path', $projectRoot)
    if (-not ($Render -or $Play)) { $engineArgs += '--headless' }
    $engineArgs += @('res://addons/agent_kit/runner/run.tscn', '--', $Command)
    if ($Name) { $engineArgs += @('--scenario', $Name) }
    if ($Render) { $engineArgs += @('--mode', 'render') }
    if ($Play) { $engineArgs += @('--mode', 'play') }
    if ($Command -in @('scenario','compare')) { $engineArgs += @('--repeat','--save-reload') }
    if ($Command -eq 'compare') {
        if (-not $VariantA -or -not $VariantB) { throw 'compare needs scenario, variant A, and variant B.' }
        $engineArgs += @('--a', $VariantA, '--b', $VariantB)
    }
    $run = Invoke-Godot $engineArgs
    $runOutput = $run.Output
    $runExit = $run.Exit
    $runOutput | Write-Output
    $runOutput | Set-Content -LiteralPath (Join-Path $profilePath "$Command.log") -Encoding utf8
    # A sandbox certificate-store warning does not affect offline tests; every other engine error fails.
    $unexpectedErrors = @($runOutput | Where-Object { [string]$_ -match '^ERROR:|SCRIPT ERROR:|Parse Error:' -and [string]$_ -notmatch '^ERROR: Failed to read the root certificate store\.' })
    if ($unexpectedErrors.Count) { exit 1 }
    if ($runExit -eq 0 -and $Command -eq 'test' -and -not ($Render -or $Play)) {
        Write-Output 'Running windowed play scenarios (physical input, camera, default panels and screenshots).'
        $playRun = Invoke-Godot @('--path', $projectRoot, 'res://addons/agent_kit/runner/run.tscn', '--', 'test', '--mode', 'play')
        $playRun.Output | Write-Output
        $playRun.Output | Set-Content -LiteralPath (Join-Path $profilePath 'play.log') -Encoding utf8
        $playErrors = @($playRun.Output | Where-Object { [string]$_ -match '^ERROR:|SCRIPT ERROR:|Parse Error:' -and [string]$_ -notmatch '^ERROR: Failed to read the root certificate store\.' })
        if ($playErrors.Count) { exit 1 }
        exit $playRun.Exit
    }
    exit $runExit
}
finally { $env:APPDATA = $previousAppData }
