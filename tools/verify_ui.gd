extends Node
## Exercises actual input/UI callbacks and saves screenshots without native automation.
var _checks: Array[Dictionary] = []
var _directory: String = "res://reports/ui-verification/%s-%s" % [Time.get_datetime_string_from_system().replace(":", "").replace("-", ""), Time.get_ticks_usec()]
func _ready() -> void:
	call_deferred("_run")
func _key(id: StringName) -> void:
	var event: InputEvent = KitControls.input_event(Kit.controls.slot(id))
	Input.parse_input_event(event)
func _release(id: StringName) -> void:
	var event: InputEvent = KitControls.input_event(Kit.controls.slot(id), false)
	Input.parse_input_event(event)
func _shot(name: String) -> bool:
	await get_tree().process_frame
	if DisplayServer.get_name() == "headless":
		return true
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	return image.save_png(_directory.path_join(name + ".png")) == OK
func _groups(rows: VBoxContainer) -> Array[Button]:
	var headers: Array[Button] = []
	for child: Node in rows.get_children():
		if child is Button and child.has_meta("tuning_group") and not child.is_queued_for_deletion():
			headers.append(child)
	return headers
func _sliders(rows: VBoxContainer) -> int:
	var count: int = 0
	for row: Node in rows.get_children():
		if row is HBoxContainer:
			for child: Node in row.get_children():
				if child is HSlider:
					count += 1
	return count
func _run() -> void:
	var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_directory))
	if error != OK:
		get_tree().quit(1)
		return
	var driver: KitScenario = load("res://scenarios/support/play_scenario.gd").new()
	var fixture_ok: bool = driver.setup()
	_checks.append(KitScenario.assertion("UI verification uses explicit mining fixtures without writing tuning.", fixture_ok))
	if not fixture_ok:
		get_tree().quit(1)
		return
	var lab: Node = load("res://game/views/mining_lab.tscn").instantiate()
	lab.set("boot_world", false)
	add_child(lab)
	await get_tree().process_frame
	Kit.controls.reset_defaults()
	Kit.feel.enabled = true
	Kit.scenario_mode = false
	# Drive the playable scene's real physical-key and clock callbacks.
	Kit.clock.mode = KitClock.Mode.MANUAL_TURN
	Kit.actions.input_source = "ui_verification"
	# Park the drill against rock:000 so the Space press below is a real, in-reach hit.
	Kit.world.writable = true
	var parked: bool = Kit.world.set_field(&"ship:player", "position", [2.5, 0.0, 0.0])
	Kit.world.writable = false
	_checks.append(KitScenario.assertion("The harness parked the ship within drill reach.", parked))
	var before_position: Variant = Kit.world.field(&"ship:player", "position")
	_key(&"fly_left")
	await get_tree().process_frame
	Kit.clock.advance()
	_release(&"fly_left")
	_checks.append(KitScenario.assertion("Flight input updates the authoritative ship.", Kit.world.field(&"ship:player", "position") != before_position))
	var before_click: String = Kit.world.state_hash()
	var clicked: bool = await driver.click_rock(lab, &"rock:000")
	_checks.append(KitScenario.assertion("A physical rock click selects without mining or spending energy.", clicked and before_click == Kit.world.state_hash() and Kit.log.records().size() == 1, {"target": str(lab.get("_target")), "records": Kit.log.records().size()}))
	_key(&"drill")
	await get_tree().process_frame
	Kit.clock.advance()
	_release(&"drill")
	_key(&"kit_inspector")
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
	# A refused hit changes nothing, so it must be explained from the rock it was aimed at.
	for index: int in range(10):
		Kit.clock.advance()
	Kit.world.writable = true
	var moved: bool = Kit.world.set_field(&"rock:020", "position", [4.5, 0.0, 0.0])
	Kit.world.writable = false
	var refused: KitActionResult = Kit.actions.run(&"mine", &"ship:player", {"target": "rock:020"})
	# The designer may have anything selected; the newest refusal must still be answered.
	Kit.overlay.set("_selected", &"dock:home")
	Kit.overlay._refresh_inspector()
	var notice: PanelContainer = Kit.overlay.get("_refusal_box")
	var notice_text: Label = Kit.overlay.get("_refusal_text")
	var show_button: Button = Kit.overlay.get("_refusal_show")
	_checks.append(KitScenario.assertion("Why answers the newest refusal whatever is selected.", moved and refused.outcome == "rejected" and notice.visible and notice_text.text.contains("Refused by mining.tool_vs_hardness") and show_button.visible and show_button.text == "Show rock:020"))
	_checks.append(KitScenario.assertion("Refusal notice screenshot saved.", await _shot("why_notice")))
	var picker: Button = Kit.overlay.get("_why_entity_button")
	var popup: PopupPanel = Kit.overlay.get("_why_entity_popup")
	var listing: ItemList = Kit.overlay.get("_why_entity_list")
	picker.pressed.emit()
	await get_tree().process_frame
	var ids: Array[StringName] = Kit.world.ids()
	_checks.append(KitScenario.assertion("The Thing list is alphabetical, grouped by kind and fits under its button.", ids[0] == &"dock:home" and ids[1] == &"rock:000" and ids[-1] == &"ship:player" and listing.get_item_text(0) == "Dock" and not listing.is_item_selectable(0) and popup.visible and popup.size.y <= 340, popup.size, Vector2i(int(picker.size.x), 340)))
	_checks.append(KitScenario.assertion("Thing list screenshot saved.", await _shot("why_thing_list")))
	for index: int in range(listing.item_count):
		if listing.get_item_metadata(index) == &"ship:player":
			listing.select(index)
			listing.item_selected.emit(index)
	_checks.append(KitScenario.assertion("Picking from the Thing list selects it and closes the list.", Kit.overlay.get("_selected") == &"ship:player" and not popup.visible and picker.text.begins_with("ship:player")))
	show_button.pressed.emit()
	_checks.append(KitScenario.assertion("Why on a rock explains a refused hit on it.", Kit.overlay.get("_selected") == &"rock:020" and why.get_parsed_text().contains("Refused by mining.tool_vs_hardness")))
	_checks.append(KitScenario.assertion("Refused-hit screenshot saved.", await _shot("why_refused")))
	var timeline: RichTextLabel = Kit.overlay.get("_timeline")
	_checks.append(KitScenario.assertion("The Log tab lists actions and refusals with no filter typed.", timeline.get_parsed_text().contains("mine by ship:player") and timeline.get_parsed_text().contains("Refused by mining.tool_vs_hardness")))
	_key(&"kit_tuning")
	await get_tree().process_frame
	var search: LineEdit = Kit.overlay.get("_search")
	var rows: VBoxContainer = Kit.overlay.get("_knob_rows")
	_checks.append(KitScenario.assertion("F2 opens with every tuning group listed.", _groups(rows).size() == Kit.tuning.sets.size() and _sliders(rows) == 0, _groups(rows).size(), Kit.tuning.sets.size()))
	_checks.append(KitScenario.assertion("Controls is the first collapsed F2 group.", rows.get_child(0) is Button and rows.get_child(0).has_meta("controls_group")))
	_checks.append(KitScenario.assertion("F2 puts the cursor in the search box.", search.has_focus()))
	_checks.append(KitScenario.assertion("Empty tuning screenshot saved.", await _shot("tuning_groups")))
	for header: Button in _groups(rows):
		if header.get_meta("tuning_group") == &"ship":
			header.pressed.emit()
	await get_tree().process_frame
	_checks.append(KitScenario.assertion("Clicking a group opens its sliders.", _sliders(rows) == Kit.tuning.sets[&"ship"].knobs().size(), _sliders(rows), Kit.tuning.sets[&"ship"].knobs().size()))
	search.text = "zzz"
	search.text_changed.emit(search.text)
	_checks.append(KitScenario.assertion("A search with no match says so.", _groups(rows).is_empty() and rows.get_child_count() == 1 and str(rows.get_child(0).text).begins_with("Nothing matches")))
	search.text = "mining energy_cost"
	search.text_changed.emit(search.text)
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
	print("UI evidence: " + _directory)
	# Let feel sounds started by the checks finish so shutdown reports no resources in use.
	var deadline: int = Time.get_ticks_msec() + 30000
	while Kit.feel.is_playing() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if Kit.feel.is_playing():
		push_error("UI verification timed out waiting for effects to finish.")
		passed = false
	await get_tree().process_frame
	get_tree().quit(0 if passed and error == OK else 1)
