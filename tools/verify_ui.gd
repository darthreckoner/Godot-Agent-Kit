extends Node
## Exercises actual input/UI callbacks and saves screenshots without native automation.
var _checks: Array[Dictionary] = []
var _directory: String = "res://reports/ui-verification"
func _ready() -> void:
	call_deferred("_run")
func _key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
func _release(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
func _shot(name: String) -> bool:
	await get_tree().process_frame
	if DisplayServer.get_name() == "headless":
		return true
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	return image.save_png(_directory.path_join(name + ".png")) == OK
func _run() -> void:
	var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_directory))
	if error != OK:
		get_tree().quit(1)
		return
	Kit.scenario_mode = true
	var lab: Node = load("res://game/views/mining_lab.tscn").instantiate()
	add_child(lab)
	await get_tree().process_frame
	# Drive the playable scene's real physical-key and clock callbacks.
	Kit.clock.mode = KitClock.Mode.MANUAL_TURN
	Kit.actions.input_source = "ui_verification"
	var before_position: Variant = Kit.world.field(&"ship:player", "position")
	_key(KEY_A)
	await get_tree().process_frame
	Kit.clock.advance()
	_release(KEY_A)
	_checks.append(KitScenario.assertion("Flight input updates the authoritative ship.", Kit.world.field(&"ship:player", "position") != before_position))
	_key(KEY_SPACE)
	await get_tree().process_frame
	Kit.clock.advance()
	_release(KEY_SPACE)
	_key(KEY_F1)
	await get_tree().process_frame
	_checks.append(KitScenario.assertion("F1 opens the inspector.", Kit.overlay.is_open()))
	Kit.overlay.set("_selected", &"ship:player")
	Kit.overlay._refresh_inspector()
	var fields: OptionButton = Kit.overlay.get("_why_fields")
	for index: int in range(fields.item_count):
		if fields.get_item_text(index) == "energy":
			fields.select(index)
	Kit.overlay._refresh_why()
	var why: RichTextLabel = Kit.overlay.get("_why")
	_checks.append(KitScenario.assertion("Why names the energy knob and input source.", why.get_parsed_text().contains("tuning/mining.energy_cost") and why.get_parsed_text().contains("ui_verification")))
	var inspector: PanelContainer = Kit.overlay.get("_inspector")
	var tabs: TabContainer = inspector.get_child(0).get_child(1)
	tabs.current_tab = 1
	_checks.append(KitScenario.assertion("Inspector screenshot saved.", await _shot("why")))
	_key(KEY_F2)
	await get_tree().process_frame
	var search: LineEdit = Kit.overlay.get("_search")
	search.text = "mining energy_cost"
	search.text_changed.emit(search.text)
	var rows: VBoxContainer = Kit.overlay.get("_knob_rows")
	var slider: HSlider
	for row: Node in rows.get_children():
		if row is HBoxContainer:
			for child: Node in row.get_children():
				if child is HSlider:
					slider = child
	if slider == null:
		_checks.append(KitScenario.assertion("Search finds energy slider.", false))
	else:
		var initial: float = float(Kit.tuning.value("mining.energy_cost"))
		slider.value = initial + 0.25
		_checks.append(KitScenario.assertion("Slider begins a live trial.", Kit.tuning.is_trial(&"mining", "energy_cost") and float(Kit.tuning.value("mining.energy_cost")) == initial + 0.25))
		_checks.append(KitScenario.assertion("Tuning screenshot saved.", await _shot("tuning_trial")))
		# Click actual Discard, Apply and Save as variant controls against a report copy.
		var original_path: String = Kit.tuning.paths[&"mining"]
		Kit.tuning.paths[&"mining"] = _directory.path_join("mining.tres")
		for row: Node in rows.get_children():
			if row is HBoxContainer:
				for child: Node in row.get_children():
					if child is Button and child.text == "Apply mining":
						child.pressed.emit()
		await get_tree().process_frame
		_checks.append(KitScenario.assertion("Apply writes through the panel.", FileAccess.file_exists(_directory.path_join("mining.tres"))))
		Kit.tuning.trial("mining.energy_cost", initial + 0.5)
		Kit.overlay._refresh_tuning()
		for row: Node in rows.get_children():
			if row is HBoxContainer:
				for child: Node in row.get_children():
					if child is Button and child.text == "Discard":
						child.pressed.emit()
		_checks.append(KitScenario.assertion("Discard returns to the applied value.", float(Kit.tuning.value("mining.energy_cost")) == initial + 0.25))
		Kit.overlay._refresh_tuning()
		for row: Node in rows.get_children():
			if row is HBoxContainer:
				for child: Node in row.get_children():
					if child is LineEdit:
						child.text = "ui_verified_" + str(Time.get_ticks_usec())
				for child: Node in row.get_children():
					if child is Button and child.text == "Save as variant":
						child.pressed.emit()
		_checks.append(KitScenario.assertion("Save as variant reports success.", str(Kit.overlay.get("_status").text) == "Variant saved."))
		Kit.tuning.paths[&"mining"] = original_path
	var before: String = Kit.world.state_hash()
	Kit.feel.time_scale = 0.25
	Kit.feel.replay()
	Kit.feel.skip()
	_checks.append(KitScenario.assertion("Slow/replay/skip leave rule state alone.", before == Kit.world.state_hash()))
	var passed: bool = true
	for check: Dictionary in _checks:
		passed = passed and bool(check.passed)
		print("%s: %s" % ["PASS" if check.passed else "FAIL", check.label])
	error = KitCanonical.write_text(_directory.path_join("report.json"), JSON.stringify({"passed": passed, "checks": _checks}, "  "))
	get_tree().quit(0 if passed and error == OK else 1)
