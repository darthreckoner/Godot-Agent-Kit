[CmdletBinding()]
## Install the kit into a throwaway copy of a real game and check it there: the game's own
## autoloads still load, a large tuning group stays usable in the tuning panel (screenshots for a
## person to inspect), Apply reaches a game save function, and test/map/lint work in a project
## laid out differently from the kit's testbed (kit.project.json). The source game is never written.
param(
    [Parameter(Mandatory)][string]$Source,
    [string[]]$Exclude = @(),
    [string]$Mutex = '',
    [int]$Knobs = 120
)
$ErrorActionPreference = 'Stop'
$kitRoot = Split-Path $PSScriptRoot -Parent
$sourceRoot = [System.IO.Path]::GetFullPath($Source)
if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'project.godot') -PathType Leaf)) { throw "Source must be a Godot project: $sourceRoot" }
$godotBin = $env:GODOT_BIN
if (-not $godotBin) { $godotBin = (Get-Content -LiteralPath (Join-Path $kitRoot 'kit.local.json') -Raw | ConvertFrom-Json).godot_bin }
if (-not $godotBin -or -not (Test-Path -LiteralPath $godotBin -PathType Leaf)) { throw 'Set GODOT_BIN or put a valid godot_bin path in kit.local.json.' }

# Some games share one GPU between agents through a named Windows mutex; hold it for each Godot run.
function Invoke-Locked([scriptblock]$Body) {
    if (-not $Mutex) { return & $Body }
    $handle = New-Object System.Threading.Mutex($false, $Mutex)
    $owned = $false
    try {
        while (-not $owned) {
            try { $owned = $handle.WaitOne([TimeSpan]::FromSeconds(30)) } catch [System.Threading.AbandonedMutexException] { $owned = $true }
            if (-not $owned) { Write-Output "Waiting for the $Mutex lock (another Godot run holds it)..." }
        }
        return & $Body
    }
    finally { if ($owned) { $handle.ReleaseMutex() }; $handle.Dispose() }
}
# Windows PowerShell 5.1 turns native stderr lines into terminating errors under 'Stop'.
function Invoke-Godot([string[]]$Arguments) {
    return Invoke-Locked {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $lines = @(& $godotBin @Arguments 2>&1 | ForEach-Object { "$_" })
            return @{ Output = $lines; Exit = $LASTEXITCODE }
        }
        finally { $ErrorActionPreference = $previousPreference }
    }
}
function Invoke-KitTool([string]$Root, [string[]]$Arguments) {
    return Invoke-Locked {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $lines = @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'tools/kit.ps1') @Arguments 2>&1 | ForEach-Object { "$_" })
            return @{ Output = $lines; Exit = $LASTEXITCODE }
        }
        finally { $ErrorActionPreference = $previousPreference }
    }
}

$runRoot = Join-Path $kitRoot ("reports/game-smoke/" + [guid]::NewGuid().ToString('N'))
$testRoot = Join-Path $runRoot 'project'
$reportsIgnore = Join-Path $kitRoot 'reports/.gdignore'
if (-not (Test-Path -LiteralPath $reportsIgnore)) { New-Item -ItemType File -Path $reportsIgnore -Force | Out-Null }
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$skip = @('.git', '.godot', '.claude', '.codex', '.agents', 'work', 'export', 'docs', 'reports') + $Exclude
Write-Output "Copying $sourceRoot (without $($skip -join ', ')) to $testRoot"
& robocopy $sourceRoot $testRoot /E /XD @skip /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Copying the game failed (robocopy exit $LASTEXITCODE)." }
$global:LASTEXITCODE = 0
$gameAutoloads = @()
$inAutoload = $false
foreach ($line in Get-Content -LiteralPath (Join-Path $testRoot 'project.godot')) {
    if ($line -match '^\[(.+)\]') { $inAutoload = $Matches[1] -eq 'autoload'; continue }
    if ($inAutoload -and $line -match '^(\w+)=') { $gameAutoloads += $Matches[1] }
}

& (Join-Path $PSScriptRoot 'install_kit.ps1') -Target $testRoot

# Smoke content lives in its own folder and is named in kit.project.json, as a game would.
$smokeRoot = Join-Path $testRoot 'kit_smoke'
New-Item -ItemType Directory -Path $smokeRoot -Force | Out-Null
'{ "content_folders": ["res://kit_smoke"], "rules_folders": [], "scenario_folder": "res://kit_smoke/scenarios" }' |
    Set-Content -LiteralPath (Join-Path $testRoot 'kit.project.json') -Encoding ascii
$knobLines = @('extends KitTuningSet', 'const KNOBS: Dictionary = {')
$exportLines = @()
for ($index = 1; $index -le $Knobs; $index++) {
    $name = 'knob_{0:D3}' -f $index
    $knobLines += "`t`"$name`": {`"help`": `"Smoke knob $index of $Knobs; checks that a long group stays readable.`"$(if ($index % 10 -eq 0) { ', "restart": true' })},"
    $exportLines += "@export_range(0, 10, 0.01, `"suffix:m/s`") var ${name}: float = $([math]::Round(($index % 97) / 10.0, 2))"
}
$knobLines += '}'
(($knobLines + $exportLines) -join "`n") + "`n" | Set-Content -LiteralPath (Join-Path $smokeRoot 'big_tuning.gd') -Encoding ascii
@'
[gd_resource type="Resource" load_steps=2 format=3]
[ext_resource type="Script" path="res://kit_smoke/big_tuning.gd" id="1"]
[resource]
script = ExtResource("1")
id = &"smoke_handling"
description = "A large generated group, sized like a real vehicle sheet."
'@ | Set-Content -LiteralPath (Join-Path $smokeRoot 'big_tuning.tres') -Encoding ascii
$autoloadList = ($gameAutoloads | ForEach-Object { "&`"$_`"" }) -join ', '
@"
extends Node
const AUTOLOADS: Array[StringName] = [$autoloadList]
var results: Dictionary = {}
var stored: Array[Dictionary] = []

func check(name: String, passed: bool) -> void:
	results[name] = passed
	print(("PASS: " if passed else "FAIL: ") + name)

func shot(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	return image != null and image.save_png(ProjectSettings.globalize_path("res://kit_smoke/%s.png" % name)) == OK

func press(id: StringName) -> void:
	for pressed: bool in [true, false]:
		Input.parse_input_event(KitControls.input_event(Kit.controls.slot(id), pressed))
		await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	for id: StringName in AUTOLOADS:
		check("Game autoload %s still loads beside the kit." % id, get_node_or_null(NodePath("/root/" + str(id))) != null)
	check("Kit services are present.", Kit.tuning != null and Kit.controls != null and Kit.overlay != null)
	var path: String = "res://kit_smoke/big_tuning.tres"
	var resource: KitTuningSet = load(path)
	check("The generated group loads.", resource != null and resource.knobs().size() == $Knobs)
	if resource == null:
		get_tree().quit(1)
		return
	Kit.tuning.register(resource, path)
	check("A game save function attaches.", Kit.tuning.use_store(&"smoke_handling", func(_id: StringName, values: Dictionary) -> Error:
		stored.append(values.duplicate())
		return OK))
	check("A trial changes a knob live.", Kit.tuning.trial("smoke_handling.knob_060", 7.5) and is_equal_approx(float(Kit.tuning.value("smoke_handling.knob_060")), 7.5))
	check("Apply goes to the game save function and leaves the kit file alone.", Kit.tuning.apply(&"smoke_handling") == OK and stored.size() == 1 and stored[0].size() == $Knobs and is_equal_approx(float(stored[0].knob_060), 7.5) and not FileAccess.get_file_as_string(path).contains("knob_060"))
	await press(&"kit_tuning")
	var rows: VBoxContainer = Kit.overlay.get("_knob_rows")
	check("The tuning shortcut opens the panel in this game.", rows != null and rows.is_visible_in_tree())
	var started: int = Time.get_ticks_usec()
	Kit.overlay.get("_expanded")[&"smoke_handling"] = true
	Kit.overlay.call("_refresh_tuning")
	var build_ms: float = (Time.get_ticks_usec() - started) / 1000.0
	results["open_large_group_ms"] = build_ms
	check("Opening a $Knobs-knob group takes under 250 ms (%.1f ms)." % build_ms, build_ms < 250.0)
	await get_tree().process_frame
	await get_tree().process_frame
	check("Top of the large group screenshot saved.", await shot("panel_top"))
	var scroll: ScrollContainer = null
	var parent: Node = rows.get_parent()
	while parent != null and scroll == null:
		scroll = parent as ScrollContainer
		parent = parent.get_parent()
	check("The tuning list scrolls inside the panel.", scroll != null)
	if scroll != null:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await get_tree().process_frame
		await get_tree().process_frame
		var last: Control = rows.get_child(rows.get_child_count() - 1) as Control
		var visible_area: Rect2 = scroll.get_global_rect()
		check("The last knob can be scrolled into view.", last != null and visible_area.encloses(last.get_global_rect()))
		check("Bottom of the large group screenshot saved.", await shot("panel_bottom"))
	var search: LineEdit = Kit.overlay.get("_search")
	search.text = "knob_117"
	search.text_changed.emit(search.text)
	await get_tree().process_frame
	await get_tree().process_frame
	var titles: Array[String] = []
	for child: Node in rows.get_children():
		for label: Node in child.find_children("*", "Label", true, false):
			titles.append((label as Label).text)
	check("Search finds one knob in a large group.", " ".join(titles).contains("Knob 117") and not " ".join(titles).contains("Knob 116"))
	check("Search result screenshot saved.", await shot("panel_search"))
	var passed: bool = true
	for key: String in results:
		if results[key] is bool:
			passed = passed and bool(results[key])
	var file: FileAccess = FileAccess.open("res://kit_smoke/results.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write smoke results: " + error_string(FileAccess.get_open_error()))
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(results, "  "))
	file.close()
	print("GAME SMOKE PASS" if passed else "GAME SMOKE FAIL")
	get_tree().quit(0 if passed else 1)
"@ | Set-Content -LiteralPath (Join-Path $smokeRoot 'smoke.gd') -Encoding ascii
@'
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://kit_smoke/smoke.gd" id="1"]
[node name="KitSmoke" type="Node"]
script = ExtResource("1")
'@ | Set-Content -LiteralPath (Join-Path $smokeRoot 'smoke.tscn') -Encoding ascii

$checks = [ordered]@{}
$previousAppData = $env:APPDATA
$previousGodot = $env:GODOT_BIN
try {
    $env:APPDATA = Join-Path $runRoot 'profile'
    $env:GODOT_BIN = $godotBin
    New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
    Write-Output 'Importing the copied game (first import of a large game can take several minutes).'
    $import = Invoke-Godot @('--headless', '--path', $testRoot, '--editor', '--import', '--quit')
    $import.Output | Set-Content -LiteralPath (Join-Path $runRoot 'import.log') -Encoding utf8
    $kitImportErrors = @($import.Output | Where-Object { $_ -match 'SCRIPT ERROR:|Parse Error:' -and $_ -match 'agent_kit|kit_smoke' })
    $checks['import without kit script errors'] = ($kitImportErrors.Count -eq 0)
    $boot = Invoke-Godot @('--path', $testRoot, 'res://kit_smoke/smoke.tscn')
    $boot.Output | Set-Content -LiteralPath (Join-Path $runRoot 'smoke.log') -Encoding utf8
    $boot.Output | Where-Object { $_ -match '^(PASS|FAIL): |GAME SMOKE' } | Write-Output
    $kitBootErrors = @($boot.Output | Where-Object { $_ -match 'ERROR|Parse Error' -and $_ -match 'agent_kit|kit_smoke' })
    $checks['windowed smoke in the game'] = ($boot.Exit -eq 0 -and ($boot.Output -join "`n") -match 'GAME SMOKE PASS' -and $kitBootErrors.Count -eq 0)
    $otherErrors = @($boot.Output | Where-Object { $_ -match '^ERROR:|SCRIPT ERROR:' -and $_ -notmatch 'agent_kit|kit_smoke|root certificate store' })
    $test = Invoke-KitTool $testRoot @('test')
    $test.Output | Set-Content -LiteralPath (Join-Path $runRoot 'kit-test.log') -Encoding utf8
    $nothing = @($test.Output | Where-Object { $_ -match '^No kit scenarios in res://kit_smoke/scenarios' })
    $checks['kit test passes with no kit scenarios'] = ($test.Exit -eq 0 -and $nothing.Count -eq 2)
    $map = Invoke-KitTool $testRoot @('map')
    $map.Output | Set-Content -LiteralPath (Join-Path $runRoot 'kit-map.log') -Encoding utf8
    $gameMap = Join-Path $testRoot 'GAME_MAP.md'
    $checks['map lists tuning from kit.project.json folders'] = ($map.Exit -eq 0 -and (Test-Path -LiteralPath $gameMap) -and (Get-Content -LiteralPath $gameMap -Raw) -match 'smoke_handling' -and (Get-Content -LiteralPath $gameMap -Raw) -match 'knob_120')
    $lint = Invoke-KitTool $testRoot @('lint')
    $lint.Output | Set-Content -LiteralPath (Join-Path $runRoot 'kit-lint.log') -Encoding utf8
    $checks['lint passes in the game'] = ($lint.Exit -eq 0)
    '{ "content_folder": ["res://kit_smoke"] }' | Set-Content -LiteralPath (Join-Path $testRoot 'kit.project.json') -Encoding ascii
    $badLint = Invoke-KitTool $testRoot @('lint')
    $checks['a misspelled kit.project.json setting is refused by name'] = ($badLint.Exit -ne 0 -and ($badLint.Output -join "`n") -match 'unknown setting "content_folder"')
    $badMap = Invoke-Godot @('--headless', '--path', $testRoot, 'res://addons/agent_kit/runner/run.tscn', '--', 'map')
    $checks['the runner reports a misspelled setting as an error'] = (($badMap.Output -join "`n") -match 'unknown setting "content_folder"')
}
finally { $env:APPDATA = $previousAppData; $env:GODOT_BIN = $previousGodot }
$smokeResults = Join-Path $smokeRoot 'results.json'
$report = [ordered]@{
    passed = -not ($checks.Values -contains $false)
    source = $sourceRoot
    copy = $testRoot
    checks = $checks
    smoke = if (Test-Path -LiteralPath $smokeResults) { Get-Content -LiteralPath $smokeResults -Raw | ConvertFrom-Json } else { $null }
    screenshots = @(Get-ChildItem -LiteralPath $smokeRoot -Filter '*.png' | ForEach-Object { $_.FullName })
    game_errors_not_from_the_kit = $otherErrors
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runRoot 'verification.json') -Encoding utf8
foreach ($name in $checks.Keys) { Write-Output ("{0}: {1}" -f ($(if ($checks[$name]) { 'PASS' } else { 'FAIL' }), $name)) }
if ($otherErrors.Count) { Write-Output "Notice: the game printed $($otherErrors.Count) error line(s) that do not come from the kit; see smoke.log." }
Write-Output "Report: $(Join-Path $runRoot 'verification.json')"
if (-not $report.passed) { exit 1 }
Write-Output "Game install verification passed."
