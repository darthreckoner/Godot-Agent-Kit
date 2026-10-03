[CmdletBinding()]
param([Parameter(Mandatory)][string]$Target, [switch]$Force)
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path $PSScriptRoot -Parent
$targetRoot = [System.IO.Path]::GetFullPath($Target)
if (-not (Test-Path -LiteralPath (Join-Path $targetRoot 'project.godot') -PathType Leaf)) {
    throw 'Target must contain project.godot. Create an empty Godot 4.7 project first.'
}
$sourceKit = Join-Path $sourceRoot 'addons/agent_kit'
$targetKit = Join-Path $targetRoot 'addons/agent_kit'
if ($targetRoot -eq [System.IO.Path]::GetFullPath($sourceRoot)) { throw 'Choose another project as the target.' }
$manifestPath = Join-Path $targetKit 'install_manifest.json'
if ((Test-Path -LiteralPath $targetKit) -and -not $Force) {
    if (-not (Test-Path -LiteralPath $manifestPath)) { throw 'Target has an untracked kit. Use -Force only to replace its local files.' }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    foreach ($entry in $manifest.files.PSObject.Properties) {
        $path = Join-Path $targetRoot $entry.Name
        if (-not (Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.Value) {
            throw "Local edit detected in $($entry.Name). Installation refused; use -Force to replace it."
        }
    }
    foreach ($file in Get-ChildItem -LiteralPath $targetKit -Recurse -File) {
        $relative = [System.IO.Path]::GetRelativePath($targetRoot, $file.FullName).Replace('\','/')
        if ($relative -eq 'addons/agent_kit/install_manifest.json' -or $relative.EndsWith('.uid')) { continue }
        if (-not $manifest.files.PSObject.Properties[$relative]) { throw "Untracked kit file $relative. Use -Force to replace local files." }
    }
}
$targetWrapper = Join-Path $targetRoot 'tools/kit.ps1'
if ((Test-Path -LiteralPath $targetWrapper) -and -not (Test-Path -LiteralPath $manifestPath) -and -not $Force) {
    throw 'Target tools/kit.ps1 already exists without a kit manifest. Use -Force to replace it.'
}
# Validate autoload collision before copying anything.
$projectPath = Join-Path $targetRoot 'project.godot'
$projectText = Get-Content -LiteralPath $projectPath -Raw
if ($projectText -match '(?m)^Kit=' -and $projectText -notmatch '(?m)^Kit="\*res://addons/agent_kit/kit.gd"\s*$') { throw 'Target already has a different Kit autoload.' }
New-Item -ItemType Directory -Path $targetKit -Force | Out-Null
foreach ($entry in Get-ChildItem -LiteralPath $sourceKit -Force) {
    Copy-Item -LiteralPath $entry.FullName -Destination $targetKit -Recurse -Force
}
New-Item -ItemType Directory -Path (Split-Path $targetWrapper -Parent) -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'kit.ps1') -Destination $targetWrapper -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'VERSION') -Destination (Join-Path $targetKit 'VERSION') -Force
$hashes = [ordered]@{}
foreach ($file in Get-ChildItem -LiteralPath $targetKit -Recurse -File | Sort-Object FullName) {
    if ($file.Name -eq 'install_manifest.json') { continue }
    $relative = [System.IO.Path]::GetRelativePath($targetRoot, $file.FullName).Replace('\','/')
    $hashes[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
}
$hashes['tools/kit.ps1'] = (Get-FileHash -LiteralPath $targetWrapper -Algorithm SHA256).Hash.ToLowerInvariant()
@{version=(Get-Content -LiteralPath (Join-Path $sourceRoot 'VERSION') -Raw).Trim(); files=$hashes} |
    ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
if ($projectText -notmatch '(?m)^Kit=') {
    if ($projectText -match '(?m)^\[autoload\]\s*$') {
        $projectText = $projectText -replace '(?m)^\[autoload\][ \t]*\r?$', "[autoload]`nKit=`"*res://addons/agent_kit/kit.gd`""
        Set-Content -LiteralPath $projectPath -Value $projectText -Encoding utf8
    }
    else {
        Add-Content -LiteralPath $projectPath -Value "`n[autoload]`nKit=`"*res://addons/agent_kit/kit.gd`"" -Encoding utf8
    }
}
Write-Output "Installed Godot Agent Kit into $targetRoot. Import the project with Godot 4.7, then boot it."
