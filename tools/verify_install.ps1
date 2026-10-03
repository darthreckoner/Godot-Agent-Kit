[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path $PSScriptRoot -Parent
$godotBin = $env:GODOT_BIN
if (-not $godotBin) { $godotBin = (Get-Content -LiteralPath (Join-Path $sourceRoot 'kit.local.json') -Raw | ConvertFrom-Json).godot_bin }
$testRoot = Join-Path $sourceRoot ("reports/install-smoke/" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
@'
config_version=5
[application]
config/name="Kit Install Smoke"
run/main_scene="res://smoke.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")
[rendering]
renderer/rendering_method="gl_compatibility"
'@ | Set-Content -LiteralPath (Join-Path $testRoot 'project.godot') -Encoding utf8
@'
extends Node
func _ready() -> void:
    var services: Array = [Kit.world, Kit.actions, Kit.events, Kit.log, Kit.rng, Kit.clock, Kit.tuning, Kit.feel, Kit.save]
    for service: Variant in services:
        if service == null:
            get_tree().quit(1)
            return
    Kit.clock.mode = KitClock.Mode.MANUAL_TURN
    Kit.clock.advance()
    if Kit.clock.tick != 1 or get_node_or_null("/root/Kit") == null:
        get_tree().quit(1)
        return
    print("INSTALL PASS: Kit booted with all nine services and manual clock.")
    get_tree().quit(0)
'@ | Set-Content -LiteralPath (Join-Path $testRoot 'smoke.gd') -Encoding utf8
@'
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://smoke.gd" id="1"]
[node name="Smoke" type="Node"]
script = ExtResource("1")
'@ | Set-Content -LiteralPath (Join-Path $testRoot 'smoke.tscn') -Encoding utf8
& (Join-Path $PSScriptRoot 'install_kit.ps1') -Target $testRoot
# An unchanged reinstall must be safe.
& (Join-Path $PSScriptRoot 'install_kit.ps1') -Target $testRoot
$targetFile = Join-Path $testRoot 'addons/agent_kit/core/clock.gd'
Add-Content -LiteralPath $targetFile -Value '# local edit used to verify refusal'
$refused = $false
try { & (Join-Path $PSScriptRoot 'install_kit.ps1') -Target $testRoot } catch { $refused = $_.Exception.Message -match 'Local edit detected' }
if (-not $refused) { throw 'Installer did not refuse a modified target.' }
& (Join-Path $PSScriptRoot 'install_kit.ps1') -Target $testRoot -Force
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $testRoot 'profile'
    New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
    $import = & $godotBin --headless --path $testRoot --editor --import --quit 2>&1
    $import | Set-Content -LiteralPath (Join-Path $testRoot 'import.log') -Encoding utf8
    if ($LASTEXITCODE -ne 0 -or ($import -join "`n") -match 'SCRIPT ERROR:|Parse Error:') { throw 'Installed project failed to import.' }
    $boot = & $godotBin --headless --path $testRoot 2>&1
    $boot | Set-Content -LiteralPath (Join-Path $testRoot 'boot.log') -Encoding utf8
    $boot | Write-Output
    if ($LASTEXITCODE -ne 0 -or ($boot -join "`n") -notmatch 'INSTALL PASS' -or ($boot -join "`n") -match 'SCRIPT ERROR:|Parse Error:') { throw 'Installed project failed to boot with Kit.' }
    # Import-created UID files must not be treated as game edits.
    & (Join-Path $PSScriptRoot 'install_kit.ps1') -Target $testRoot
    @{passed=$true; target=$testRoot; checks=@('clean install','unchanged reinstall','modified-file refusal','forced reinstall','headless import','all-service boot','manual turn','reinstall after import')} |
        ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $testRoot 'verification.json') -Encoding utf8
}
finally { $env:APPDATA = $previousAppData }
Write-Output "Install verification passed: $testRoot"
