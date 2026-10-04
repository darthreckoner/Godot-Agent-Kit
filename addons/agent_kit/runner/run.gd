extends Node
var _report_dir: String
var _mode: String = "sim"
var _repeat: bool = false
var _save_reload: bool = false
var _all_passed: bool = true
var _held_keys: Dictionary = {}
var _held_buttons: Dictionary = {}

func _ready() -> void:
	call_deferred("_entry")

func _argument(args: PackedStringArray, key: String, fallback: String = "") -> String:
	var index: int = args.find(key)
	return args[index + 1] if index >= 0 and index + 1 < args.size() else fallback

func _scenario_paths() -> Array[String]:
	var result: Array[String] = []
	if not DirAccess.dir_exists_absolute("res://scenarios"):
		return result
	for path: String in KitMap.paths("res://scenarios", "gd"):
		var script: Script = load(path)
		if script == null or not script.can_instantiate():
			_all_passed = false
			continue
		var instance: RefCounted = script.new()
		if instance is KitScenario and not instance.id.is_empty():
			result.append(path)
	return result

func _entry() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var command: String = args[0] if not args.is_empty() else "test"
	_mode = _argument(args, "--mode", "sim")
	_repeat = args.has("--repeat") or command == "test"
	_save_reload = args.has("--save-reload") or command == "test"
	if command == "map":
		var error: Error = KitMap.generate()
		print("Game map generated." if error == OK else "Map failed: " + error_string(error))
		get_tree().quit(0 if error == OK else 1)
		return
	if _mode in ["render", "play"] and DisplayServer.get_name() == "headless":
		push_error("Render and play modes need a windowed Godot process.")
		get_tree().quit(1)
		return
	var paths: Array[String] = _scenario_paths()
	if paths.is_empty():
		push_error("No declared scenarios were found.")
		get_tree().quit(1)
		return
	var selected: String = _argument(args, "--scenario", paths[0].get_file().get_basename())
	if command == "dump":
		var scenario: KitScenario = load("res://scenarios/%s.gd" % selected).new()
		if not scenario.setup():
			get_tree().quit(1)
			return
		print(JSON.stringify(Kit.world.dump(), "  "))
		get_tree().quit(0)
		return
	if command != "test":
		paths = ["res://scenarios/%s.gd" % selected]
	for path: String in paths:
		if not ResourceLoader.exists(path):
			push_error("Scenario not found: " + path)
			_all_passed = false
			continue
		var scenario: KitScenario = load(path).new()
		if scenario.requires_play != (_mode == "play"):
			if command != "test":
				push_error("This scenario needs %s mode." % ("play (-Play)" if scenario.requires_play else "sim or render"))
				_all_passed = false
			else:
				print("SKIP %s in %s mode; covered by %s mode." % [scenario.id, _mode, "play" if scenario.requires_play else "sim"])
			continue
		var timestamp: String = Time.get_datetime_string_from_system().replace("-", "").replace(":", "").replace("T", "-")
		var suffix: String = str(Time.get_ticks_usec())
		_report_dir = "res://reports/%s/%s-%s" % [scenario.id, timestamp, suffix]
		var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_report_dir))
		if error != OK:
			push_error("Cannot create the report directory: " + error_string(error))
			_all_passed = false
			continue
		var variants: Array[String] = scenario.comparison_variants()
		if command == "compare":
			variants = [_argument(args, "--a"), _argument(args, "--b")]
		elif command != "test" and not _argument(args, "--variant").is_empty():
			variants = [_argument(args, "--variant")]
		if variants.is_empty():
			variants = [""]
		var runs: Array[Dictionary] = []
		var checks: Array[Dictionary] = []
		for index: int in range(variants.size()):
			var baseline: Dictionary = await _run_one(path, variants[index], false, _mode in ["render", "play"], "variant_%d" % index)
			runs.append(baseline)
			checks.append(KitScenario.assertion("Variant %d assertions" % index, baseline.get("passed", false)))
			if _repeat:
				var repeat_run: Dictionary = await _run_one(path, variants[index], false, false, "repeat_%d" % index)
				checks.append(KitScenario.assertion("Variant %d repeats exactly" % index, repeat_run.get("passed", false) and baseline.get("hash") == repeat_run.get("hash"), repeat_run.get("hash"), baseline.get("hash")))
				baseline["repeat_evidence"] = repeat_run
			if _save_reload:
				var reload_run: Dictionary = await _run_one(path, variants[index], true, false, "reload_%d" % index)
				checks.append(KitScenario.assertion("Variant %d save/reload continuation matches" % index, reload_run.get("passed", false) and baseline.get("hash") == reload_run.get("hash"), reload_run.get("hash"), baseline.get("hash")))
				baseline["reload_evidence"] = reload_run
		var diff: Dictionary = {}
		if runs.size() == 2:
			var a_constraints: Dictionary = runs[0].get("constraints", {})
			var b_constraints: Dictionary = runs[1].get("constraints", {})
			var same: bool = a_constraints == b_constraints
			checks.append(KitScenario.assertion("A/B constraints are identical", same, b_constraints, a_constraints))
			if not same:
				diff["constraints"] = {"a": a_constraints, "b": b_constraints}
			diff["numbers"] = {"a": runs[0].get("numbers", {}), "b": runs[1].get("numbers", {})}
			diff["variants"] = variants
		var passed: bool = true
		for check: Dictionary in checks:
			passed = passed and bool(check.passed)
		_all_passed = _all_passed and passed
		var report: Dictionary = {"scenario": str(scenario.id), "description": scenario.description, "mode": _mode, "passed": passed, "checks": checks, "runs": runs, "diff": diff}
		error = KitCanonical.write_text(_report_dir.path_join("report.json"), JSON.stringify(KitCanonical.normalize(report), "  "))
		var markdown: String = "# %s — %s\n\n%s\n\nMode: %s. Repeat: %s. Save/reload: %s.\n\n" % [scenario.id, "Passed" if passed else "Failed", scenario.description, _mode, _repeat, _save_reload]
		for check: Dictionary in checks:
			markdown += "- %s: %s\n" % ["PASS" if check.passed else "FAIL", check.label]
		for run: Dictionary in runs:
			markdown += "\n## Variant %s\n\nKey numbers: %s\n\n" % [run.get("variant", "default"), JSON.stringify(run.get("numbers", {}))]
			for shot: String in run.get("shots", []):
				markdown += "![%s](%s)\n\n" % [shot.get_file().get_basename().capitalize(), shot.trim_prefix(_report_dir + "/")]
			for assertion: Dictionary in run.get("assertions", []):
				markdown += "- %s: %s (actual %s; expected %s)\n" % ["PASS" if assertion.passed else "FAIL", assertion.label, str(assertion.actual), str(assertion.expected)]
			if not run.get("passed", false):
				markdown += "\nRecorded operations:\n\n~~~json\n%s\n~~~\n" % JSON.stringify(run.get("records", []), "  ")
		if error != OK or KitCanonical.write_text(_report_dir.path_join("report.md"), markdown) != OK:
			push_error("Report files could not be written.")
			_all_passed = false
		print("%s: %s · %s" % [scenario.id, "PASS" if passed else "FAIL", _report_dir.trim_prefix("res://")])
	get_tree().quit(0 if _all_passed else 1)

func _run_one(path: String, variant: String, midpoint_reload: bool, rendering: bool, label: String) -> Dictionary:
	var scenario: KitScenario = load(path).new()
	scenario.variant = variant
	scenario.report_dir = _report_dir.path_join(label)
	scenario.render_mode = rendering
	if not scenario.setup():
		return {"passed": false, "error": "Scenario setup failed."}
	var view: Node
	if rendering or scenario.requires_play:
		Kit.feel.enabled = true
		var packed: PackedScene = scenario.render_scene()
		if packed == null:
			return {"passed": false, "error": "Scenario has no render scene."}
		view = packed.instantiate()
		if "boot_world" in view:
			view.set("boot_world", false)
		add_child(view)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if view.has_method("caption"):
			view.caption("%s · %s" % [scenario.description, variant])
	if scenario.requires_play:
		# Real _input/_unhandled_input and physical-key polling run; wall time cannot advance rules.
		Kit.scenario_mode = false
		Kit.clock.mode = KitClock.Mode.MANUAL_TURN
	var commands: Array[Dictionary] = scenario.steps()
	var command_checks: Array[Dictionary] = []
	var save_path: String = scenario.report_dir.path_join("midpoint.json")
	for index: int in range(commands.size()):
		var ok: bool = await _execute_command(commands[index], scenario, view)
		command_checks.append(KitScenario.assertion("Command %d: %s" % [index, commands[index].command], ok))
		if not ok:
			break
		if midpoint_reload and index == maxi(0, commands.size() / 2 - 1):
			var saved: bool = Kit.save.write(save_path)
			if saved:
				Kit.world.restore({})
				Kit.actions.pending.clear()
				Kit.rng.reset(999)
				Kit.clock.tick = 999
			var loaded: bool = saved and Kit.save.load_file(save_path)
			command_checks.append(KitScenario.assertion("Midpoint save/reload succeeded", loaded, Kit.save.last_message))
			if not loaded:
				break
	var assertions: Array[Dictionary] = scenario.expect()
	assertions.append_array(command_checks)
	var passed: bool = true
	for assertion: Dictionary in assertions:
		passed = passed and bool(assertion.passed)
	var result: Dictionary = {"passed": passed, "variant": variant if not variant.is_empty() else "default", "hash": Kit.simulation_hash(), "world_hash": Kit.world.state_hash(), "assertions": assertions, "numbers": scenario.numbers(), "constraints": scenario.constraints(), "records": Kit.log.records(), "events": Kit.events.history.duplicate(true)}
	result["shots"] = KitMap.paths(scenario.report_dir.path_join("shots"), "png") if DirAccess.dir_exists_absolute(scenario.report_dir.path_join("shots")) else []
	if view != null:
		_release_inputs()
		await get_tree().process_frame
		view.queue_free()
		await get_tree().process_frame
	Kit.feel.clear()
	Kit.scenario_mode = true
	return result

func _release_inputs() -> void:
	for code: int in _held_keys:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code as Key
		event.physical_keycode = code as Key
		Input.parse_input_event(event)
	for code: int in _held_buttons:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = code as MouseButton
		event.position = _held_buttons[code]
		Input.parse_input_event(event)
	_held_keys.clear()
	_held_buttons.clear()
	Input.flush_buffered_events()

func _execute_command(command: Dictionary, scenario: KitScenario, view: Node) -> bool:
	match str(command.command):
		"control":
			if not scenario.requires_play:
				return false
			var binding: Dictionary = Kit.controls.slot(StringName(command.action), int(command.get("slot", 0)))
			var mapped: InputEvent = KitControls.input_event(binding, bool(command.get("pressed", true)))
			if mapped == null:
				return false
			if mapped is InputEventKey:
				return await _execute_command({"command": "key", "key": int(mapped.physical_keycode), "pressed": mapped.pressed}, scenario, view)
			if mapped is InputEventMouseButton:
				return await _execute_command({"command": "mouse_button", "button": int(mapped.button_index), "position": command.get("position", [800, 350]), "pressed": mapped.pressed}, scenario, view)
			return false
		"key":
			if not scenario.requires_play:
				return false
			var event: InputEventKey = InputEventKey.new()
			event.keycode = int(command.key) as Key
			event.physical_keycode = event.keycode
			event.pressed = bool(command.get("pressed", true))
			if event.pressed:
				_held_keys[int(event.keycode)] = true
			else:
				_held_keys.erase(int(event.keycode))
			Input.parse_input_event(event)
			await get_tree().process_frame
		"mouse_button":
			if not scenario.requires_play:
				return false
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = int(command.button) as MouseButton
			var position: Array = command.position
			event.position = Vector2(float(position[0]), float(position[1]))
			event.pressed = bool(command.get("pressed", true))
			if event.pressed:
				_held_buttons[int(event.button_index)] = event.position
			else:
				_held_buttons.erase(int(event.button_index))
			Input.parse_input_event(event)
			await get_tree().process_frame
		"mouse_motion":
			if not scenario.requires_play:
				return false
			var event: InputEventMouseMotion = InputEventMouseMotion.new()
			var relative: Array = command.relative
			event.relative = Vector2(float(relative[0]), float(relative[1]))
			Input.parse_input_event(event)
			await get_tree().process_frame
		"input_ticks":
			if not scenario.requires_play:
				return false
			for index: int in range(int(command.get("ticks", 1))):
				Kit.clock.advance()
				await get_tree().process_frame
		"wait_presentation":
			if not scenario.requires_play:
				return false
			await get_tree().create_timer(float(command.get("seconds", 0.1))).timeout
		"run":
			Kit.actions.run(StringName(command.action), StringName(command.actor), command.get("params", {}), "scenario")
		"queue":
			Kit.actions.queue(StringName(command.action), StringName(command.actor), command.get("params", {}), "scenario")
		"advance":
			Kit.clock.advance(int(command.get("ticks", 1)))
		"tune":
			return Kit.tuning.trial(str(command.key), command.value)
		"save":
			return Kit.save.write(scenario.report_dir.path_join(str(command.get("name", "save")) + ".json"))
		"reload":
			return Kit.save.load_file(scenario.report_dir.path_join(str(command.get("name", "save")) + ".json"))
		"screenshot":
			if not scenario.render_mode:
				return true
			if command.has("stage"):
				var deadline: int = Time.get_ticks_msec() + 5000
				while Kit.feel.last_stage == null or Kit.feel.last_stage.stage_name != str(command.stage):
					if Time.get_ticks_msec() > deadline:
						push_error("The requested feel stage did not play: " + str(command.stage))
						return false
					await get_tree().process_frame
			await get_tree().create_timer(float(command.get("delay", 0.1))).timeout
			await RenderingServer.frame_post_draw
			var path: String = scenario.report_dir.path_join("shots/%s.png" % command.get("name", "shot"))
			var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			if error != OK:
				return false
			var image: Image = get_viewport().get_texture().get_image()
			error = image.save_png(path)
			return error == OK
		_:
			if scenario.has_method("execute_custom"):
				return await scenario.execute_custom(command, view)
			push_error("Unknown scenario command: " + str(command.command))
			return false
	return true
