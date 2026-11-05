[CmdletBinding()]
## Checks that a headless `--script` run in a game with the Kit autoload installed ends cleanly.
## Godot prints exit-time lines such as "resources still in use at exit", "Leaked instance" and
## "Pages in use exist at exit" when a script is still held after the run. A game's test runner that
## counts those as failures then fails every rule test, even though every assertion passed (K-8).
## The leak only shows when the game also has its own scripts loaded, so the throwaway project
## below keeps a game tuning script alive and calls every kit change factory the way a rule does.
## -KitRoot lets you point the check at another copy of the kit (for example an older version).
param([string]$KitRoot = '')
$ErrorActionPreference = 'Stop'
$sourceRoot = if ($KitRoot) { [System.IO.Path]::GetFullPath($KitRoot) } else { Split-Path $PSScriptRoot -Parent }
$godotBin = $env:GODOT_BIN
if (-not $godotBin) { $godotBin = (Get-Content -LiteralPath (Join-Path $sourceRoot 'kit.local.json') -Raw | ConvertFrom-Json).godot_bin }
if (-not $godotBin -or -not (Test-Path -LiteralPath $godotBin -PathType Leaf)) { throw 'Set GODOT_BIN or put a valid godot_bin path in kit.local.json.' }
# Windows PowerShell 5.1 turns each native stderr line into a terminating error under 'Stop'.
function Invoke-Godot([string[]]$Arguments) {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $lines = @(& $godotBin @Arguments 2>&1 | ForEach-Object { "$_" })
        return @{ Output = $lines; Exit = $LASTEXITCODE }
    }
    finally { $ErrorActionPreference = $previousPreference }
}
$testRoot = Join-Path $sourceRoot ("reports/exit-leak/" + [guid]::NewGuid().ToString('N'))
$reportsIgnore = Join-Path $sourceRoot 'reports/.gdignore'
if (-not (Test-Path -LiteralPath $reportsIgnore)) { New-Item -ItemType File -Path $reportsIgnore -Force | Out-Null }
New-Item -ItemType Directory -Path (Join-Path $testRoot 'data') -Force | Out-Null
@'
config_version=5
[application]
config/name="Kit Exit Leak Check"
config/features=PackedStringArray("4.7", "GL Compatibility")
[rendering]
renderer/rendering_method="gl_compatibility"
'@ | Set-Content -LiteralPath (Join-Path $testRoot 'project.godot') -Encoding ascii
# A game's own tuning script, like res://data/tuning.gd in a real game.
@'
class_name GameTuning
extends Resource
const PATH := "res://data/tuning.tres"
@export var values: Dictionary = {}
static func shared() -> GameTuning:
    return load(PATH) as GameTuning
'@ | Set-Content -LiteralPath (Join-Path $testRoot 'data/tuning.gd') -Encoding ascii
@'
[gd_resource type="Resource" script_class="GameTuning" load_steps=2 format=3]
[ext_resource type="Script" path="res://data/tuning.gd" id="1"]
[resource]
script = ExtResource("1")
values = {"speed": 4.0}
'@ | Set-Content -LiteralPath (Join-Path $testRoot 'data/tuning.tres') -Encoding ascii
# Probe 1 only loads the game's script, the way a rule test does. Probe 2 also builds every kind of
# change a rule can return. Both must end clean; the first is the one that exposed K-8.
@'
extends SceneTree
const TUNING := preload("res://data/tuning.tres")
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var kit: Node = root.get_node_or_null("Kit")
    if kit == null or TUNING == null or GameTuning.shared() == null:
        print("EXIT LEAK PROBE FAILED: Kit autoload or game script missing.")
        quit(1)
        return
    print("EXIT LEAK PROBE OK: Kit loaded beside game script %s." % TUNING.get_script().resource_path)
    quit(0)
'@ | Set-Content -LiteralPath (Join-Path $testRoot 'probe_game_script.gd') -Encoding ascii
@'
extends SceneTree
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var game_tuning: GameTuning = GameTuning.shared()
    var changes: Array = [
        KitResourceDelta.make(&"unit:a", "energy", -1.0, "probe"),
        KitSetField.make(&"unit:a", "health", 3.0, "probe"),
        KitRecordChange.add(&"unit:b", &"unit", {}, "probe"),
        KitRecordChange.remove_id(&"unit:b", "probe"),
        KitCheckResult.make(&"probe", true, "ok"),
    ]
    if root.get_node_or_null("Kit") == null or game_tuning == null or changes.size() != 5:
        print("EXIT LEAK PROBE FAILED: Kit autoload, game script or changes missing.")
        quit(1)
        return
    print("EXIT LEAK PROBE OK: %d changes built beside game script %s." % [changes.size(), game_tuning.get_script().resource_path])
    quit(0)
'@ | Set-Content -LiteralPath (Join-Path $testRoot 'probe_changes.gd') -Encoding ascii
& (Join-Path $sourceRoot 'tools/install_kit.ps1') -Target $testRoot | Out-Null
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $testRoot 'profile'
    New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
    $importRun = Invoke-Godot @('--headless', '--path', $testRoot, '--editor', '--import', '--quit')
    if ($importRun.Exit -ne 0 -or ($importRun.Output -join "`n") -match 'SCRIPT ERROR:|Parse Error:') { $importRun.Output | Write-Output; throw 'Exit-leak check project failed to import.' }
    $failed = $false
    foreach ($probe in @('probe_game_script', 'probe_changes')) {
        $run = Invoke-Godot @('--headless', '--path', $testRoot, '--script', "res://$probe.gd")
        $run.Output | Set-Content -LiteralPath (Join-Path $testRoot "$probe.log") -Encoding utf8
        $run.Output | Write-Output
        $leakLines = @($run.Output | Where-Object { $_ -match '(?i)still in use at exit|leaked|pages in use|SCRIPT ERROR:|Parse Error:' })
        if ($leakLines.Count) {
            Write-Output "EXIT LEAK CHECK FAILED in ${probe}: the run printed $($leakLines.Count) exit-time problem line(s):"
            $leakLines | ForEach-Object { Write-Output "  $_" }
            Write-Output "Full log: $(Join-Path $testRoot "$probe.log")"
            $failed = $true
        }
        elseif ($run.Exit -ne 0 -or ($run.Output -join "`n") -notmatch 'EXIT LEAK PROBE OK') {
            Write-Output "EXIT LEAK CHECK FAILED in ${probe}: exit code $($run.Exit) without the OK line."
            $failed = $true
        }
    }
    if ($failed) { exit 1 }
}
finally { $env:APPDATA = $previousAppData }
Write-Output "EXIT LEAK CHECK PASS: both probes ended with no leak or still-in-use lines. Logs: $testRoot"
