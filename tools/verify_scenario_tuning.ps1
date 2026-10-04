[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path $PSScriptRoot -Parent
$godotBin = $env:GODOT_BIN
if (-not $godotBin) { $godotBin = (Get-Content -LiteralPath (Join-Path $sourceRoot 'kit.local.json') -Raw | ConvertFrom-Json).godot_bin }
if (-not $godotBin -or -not (Test-Path -LiteralPath $godotBin -PathType Leaf)) { throw 'Set GODOT_BIN or kit.local.json to a valid Godot executable.' }
$testRoot = Join-Path $sourceRoot ('reports/scenario-tuning/' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
# Apply is exercised in a complete copy. The designer's project resources stay untouched.
$before = @{}
foreach ($folder in @('addons','game','scenarios','tools')) {
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $sourceRoot $folder) -Recurse -File) {
        $before[$file.FullName] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
    Copy-Item -LiteralPath (Join-Path $sourceRoot $folder) -Destination $testRoot -Recurse
}
Copy-Item -LiteralPath (Join-Path $sourceRoot 'project.godot') -Destination $testRoot
New-Item -ItemType File -Path (Join-Path $sourceRoot 'reports/.gdignore') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $testRoot 'reports/engine-profile') -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $testRoot 'reports/.gdignore') -Force | Out-Null
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $testRoot 'reports/engine-profile'
    foreach ($phase in @('import','verify')) {
        $arguments = @('--headless','--path',$testRoot)
        if ($phase -eq 'import') { $arguments += @('--editor','--import','--quit') }
        else { $arguments += 'res://tools/verify_scenario_tuning.tscn' }
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $lines = @(& $godotBin @arguments 2>&1 | ForEach-Object {
                $line = "$_"
                if ($line -match '^TUNING INDEPENDENCE|^Tuning independence verification:') { Write-Host $line }
                $line
            })
            $engineExit = $LASTEXITCODE
        }
        finally { $ErrorActionPreference = $previousPreference }
        $lines | Set-Content -LiteralPath (Join-Path $testRoot ($phase + '.log')) -Encoding utf8
        $unexpected = @($lines | Where-Object { $_ -match '^ERROR:|SCRIPT ERROR:|Parse Error:' -and $_ -notmatch '^ERROR: Failed to read the root certificate store\.' })
        if ($engineExit -ne 0 -or $unexpected.Count) { $lines | Write-Output; throw "Tuning independence $phase failed. Evidence: $testRoot" }
    }
}
finally {
    $env:APPDATA = $previousAppData
    foreach ($path in $before.Keys) {
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $before[$path]) { throw "Verification changed a source file: $path" }
    }
}
$report = Get-Content -LiteralPath (Join-Path $testRoot 'verification.json') -Raw | ConvertFrom-Json
if (-not $report.passed -or $report.applied_cases -ne 24) { throw 'Tuning independence report is incomplete or failed.' }
Write-Output "Source files unchanged. Evidence: $testRoot/verification.json"
