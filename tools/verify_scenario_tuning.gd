extends "res://addons/agent_kit/runner/run.gd"
## Run only in the report-local project made by verify_scenario_tuning.ps1.
var _matrix_checks: Array[Dictionary] = []
var _baseline_hashes: Dictionary = {}
var _cases: Array[Dictionary] = []

func _ready() -> void:
	call_deferred("_verify")

func _run_rules(paths: Array[String], label: String) -> bool:
	_report_dir = "res://reports/tuning-matrix/" + label
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_report_dir)) != OK:
		return false
	var passed: bool = true
	var results: Dictionary = {}
	for path: String in paths:
		var name: String = path.get_file().get_basename()
		var run: Dictionary = await _run_one(path, "", false, false, name)
		var matches: bool = bool(run.get("passed", false))
		if label == "baseline":
			_baseline_hashes[name] = run.get("hash", "")
		else:
			matches = matches and run.get("hash", "") == _baseline_hashes.get(name)
		results[name] = {"passed": matches, "hash": run.get("hash"), "tuning_pins": run.get("tuning_pins", {})}
		if not matches:
			results[name]["assertions"] = run.get("assertions", [])
			results[name]["error"] = run.get("error", "")
		passed = matches and passed
	_cases.append({"case": label, "passed": passed, "scenarios": results})
	return passed

func _verify() -> void:
	var root: String = ProjectSettings.globalize_path("res://").replace("\\", "/")
	if not root.contains("/reports/scenario-tuning/"):
		push_error("Tuning independence verification needs an isolated reports/scenario-tuning project.")
		get_tree().quit(1)
		return
	var original: MiningTuning = ResourceLoader.load("res://game/tuning/mining.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	var reference: Dictionary = KitCanonical.read_json("res://scenarios/fixtures/default_balance.json")
	if original == null or not reference.ok:
		get_tree().quit(1)
		return
	var paths: Array[String] = []
	for path: String in _scenario_paths():
		var scenario: KitScenario = load(path).new()
		if not scenario.requires_play and scenario.id != &"shipped_default_balance":
			paths.append(path)
	var passed: bool = await _run_rules(paths, "baseline")
	for knob: String in original.knobs():
		var metadata: Dictionary = original.metadata(knob)
		for edge: String in ["min", "max"]:
			var resource: MiningTuning = original.duplicate(true)
			Kit.tuning.register(resource, "res://game/tuning/mining.tres")
			var applied: bool = Kit.tuning.trial("mining." + knob, metadata[edge]) and Kit.tuning.apply(&"mining") == OK
			# Each scenario must see the just-applied file in this engine process.
			var shipped: MiningTuning = ResourceLoader.load("res://game/tuning/mining.tres", "", ResourceLoader.CACHE_MODE_REPLACE)
			applied = applied and shipped != null and KitScenario.close(float(shipped.get(knob)), float(metadata[edge]))
			var label: String = knob + "_" + edge
			var rules_passed: bool = applied and await _run_rules(paths, label)
			var notice: KitScenario = load("res://scenarios/shipped_default_balance.gd").new()
			var notice_ok: bool = notice.setup()
			var changed: bool = not KitScenario.close(float(reference.data["mining." + knob]), float(metadata[edge]))
			notice_ok = notice_ok and notice.numbers().default_changes.has("mining." + knob) == changed
			_matrix_checks.append(KitScenario.assertion("Applied mining.%s=%s: all %d rule scenarios pass with unchanged continuation hashes and the default-balance notice matches the applied value." % [knob, metadata[edge], paths.size()], rules_passed and notice_ok))
			passed = rules_passed and notice_ok and passed
			print("TUNING INDEPENDENCE %s: %s" % [label, "PASS" if rules_passed and notice_ok else "FAIL"])
			if ResourceSaver.save(original, "res://game/tuning/mining.tres") != OK:
				get_tree().quit(1)
				return
			ResourceLoader.load("res://game/tuning/mining.tres", "", ResourceLoader.CACHE_MODE_REPLACE)
	var report: Dictionary = {"passed": passed, "rule_scenarios": paths.size(), "knobs": original.knobs().size(), "applied_cases": _matrix_checks.size(), "checks": _matrix_checks, "cases": _cases}
	var error: Error = KitCanonical.write_text("res://verification.json", JSON.stringify(KitCanonical.normalize(report), "  "))
	if error != OK:
		passed = false
	print("Tuning independence verification: %s; %d applied boundary cases, %d rule scenarios per case." % ["PASS" if passed else "FAIL", _matrix_checks.size(), paths.size()])
	get_tree().quit(0 if passed else 1)
