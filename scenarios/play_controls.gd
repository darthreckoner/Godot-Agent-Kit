extends "res://scenarios/support/play_scenario.gd"
var _default_rule_hash: String

func _init() -> void:
	requires_play = true
	id = &"play_controls"
	description = "Rebind through F2; new keys fly, old keys stop, conflicts refuse, Discard/reset restore, and Apply persists project defaults."

func setup() -> bool:
	return super.setup()

func steps() -> Array[Dictionary]:
	return [{"command": "rebind"}, {"command": "fly"}, {"command": "restore"}, {"command": "persist"}]

func button(meta: String, value: Variant = true, slot_index: int = -1) -> Button:
	var rows: VBoxContainer = Kit.overlay.get("_knob_rows")
	for child: Node in rows.get_children():
		var nodes: Array[Node] = [child]
		nodes.append_array(child.get_children())
		for node: Node in nodes:
			if node is Button and node.has_meta(meta) and node.get_meta(meta) == value and (slot_index < 0 or node.get_meta("control_slot", -1) == slot_index):
				return node
	return null

func click_button(target: Button) -> bool:
	if target == null:
		return false
	# Let the rebuilt containers lay out, then click the actual visible GUI rectangle.
	await Kit.get_tree().process_frame
	await Kit.get_tree().process_frame
	var center: Vector2 = target.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = center
		event.pressed = pressed
		Input.parse_input_event(event)
		await Kit.get_tree().process_frame
	return true

func find_controls(query: String = "controls fly forward") -> void:
	var search: LineEdit = Kit.overlay.get("_search")
	search.text = query
	search.text_changed.emit(query)
	await Kit.get_tree().process_frame

func position() -> Array:
	return Kit.world.field(&"ship:player", "position")

func execute_custom(command: Dictionary, view: Node) -> bool:
	match str(command.command):
		"rebind":
			_default_rule_hash = Kit.simulation_hash()
			await control(&"kit_tuning")
			await control(&"kit_tuning", false)
			_checks.append(assertion("F2 starts with Controls at the top.", button("controls_group") != null))
			await click_button(button("controls_group"))
			var panel: PanelContainer = Kit.overlay.get("_tuning_panel")
			var scroll: ScrollContainer = Kit.overlay.get("_knob_rows").get_parent()
			_checks.append(assertion("Expanded Controls fits the window and scrolls its list.", panel.get_global_rect().end.y <= 720 and scroll.get_v_scroll_bar().visible, {"panel": panel.size, "minimum": panel.get_combined_minimum_size(), "scroll": scroll.size, "scroll_minimum": scroll.get_combined_minimum_size(), "mode": scroll.vertical_scroll_mode}))
			_checks.append(assertion("Controls screenshot saved.", await shot("controls_group")))
			await find_controls()
			await click_button(button("control_action", &"fly_forward", 0))
			await key(KEY_K)
			await key(KEY_K, false)
			_checks.append(assertion("A physical slot click and K press start a forward trial.", Kit.controls.slot(&"fly_forward").get("key") == KEY_K and Kit.controls.is_trial(&"fly_forward")))
			_checks.append(assertion("Rebinding changes hints immediately and leaves rules/timing alone.", str(view.get("_hints").text).contains("K: fly forward") and _default_rule_hash == Kit.simulation_hash()))
			_checks.append(assertion("Trial screenshot saved.", await shot("controls_trial")))
			await click_button(button("control_action", &"fly_forward", 0))
			await control(&"drill")
			await control(&"drill", false)
			_checks.append(assertion("A conflicting Space rebind is refused with its action named.", Kit.controls.slot(&"fly_forward").get("key") == KEY_K and str(Kit.overlay.get("_status").text) == "Space is already drill selected target."))
			_checks.append(assertion("Conflict screenshot saved.", await shot("controls_conflict")))
			await control(&"kit_tuning")
			await control(&"kit_tuning", false)
		"fly":
			var before: Array = position()
			await key(KEY_W)
			Kit.clock.advance(8)
			await key(KEY_W, false)
			_checks.append(assertion("The old W key no longer flies.", position() == before and Kit.log.records().is_empty()))
			await control(&"fly_forward")
			for index: int in range(8):
				Kit.clock.advance()
				await Kit.get_tree().process_frame
			await control(&"fly_forward", false)
			_checks.append(assertion("The currently bound K key flies through the real clock callback.", position() != before and Kit.log.records().size() == 8))
			_checks.append(assertion("Updated hints screenshot saved.", await shot("rebound_flight_hints")))
			var hints: Label = view.get("_hints")
			_checks.append(assertion("Generated hints stay inside the viewport.", hints.get_global_rect().position.x >= 0 and hints.get_global_rect().position.y >= 0 and hints.get_global_rect().end.x <= 1280 and hints.get_global_rect().end.y <= 720 and hints.is_visible_in_tree() and hints.get_line_count() > 0, {"rect": hints.get_global_rect(), "lines": hints.get_line_count(), "visible_lines": hints.get_visible_line_count(), "text": hints.text}))
		"restore":
			await control(&"kit_tuning")
			await control(&"kit_tuning", false)
			await find_controls()
			await click_button(button("controls_discard"))
			_checks.append(assertion("Discard restores W and its hints.", Kit.controls.slot(&"fly_forward").get("key") == KEY_W and not Kit.controls.is_trial(&"fly_forward") and str(view.get("_hints").text).contains("W: fly forward")))
			await click_button(button("control_action", &"fly_forward", 1))
			var mouse: InputEventMouseButton = InputEventMouseButton.new()
			mouse.button_index = MOUSE_BUTTON_MIDDLE
			mouse.position = Vector2(900, 600)
			mouse.pressed = true
			Input.parse_input_event(mouse)
			await Kit.get_tree().process_frame
			mouse = mouse.duplicate()
			mouse.pressed = false
			Input.parse_input_event(mouse)
			await Kit.get_tree().process_frame
			_checks.append(assertion("A second slot accepts a mouse button.", Kit.controls.slot(&"fly_forward", 1).get("mouse") == MOUSE_BUTTON_MIDDLE and InputMap.action_get_events(&"fly_forward").size() == 2))
			await click_button(button("controls_reset"))
			_checks.append(assertion("Reset restores declared defaults as a trial against saved controls.", Kit.controls.slot(&"fly_forward").get("key") == KEY_W and Kit.controls.slot(&"fly_forward", 1).is_empty()))
			await find_controls("controls open tuning")
			await click_button(button("control_action", &"kit_tuning", 0))
			await key(KEY_F4)
			await key(KEY_F4, false)
			_checks.append(assertion("Kit shortcuts use the same editable list and hint source.", Kit.controls.slot(&"kit_tuning").get("key") == KEY_F4 and str(view.get("_hints").text).contains("F4: open tuning")))
			await control(&"kit_tuning")
			await control(&"kit_tuning", false)
			_checks.append(assertion("The rebound F4 shortcut closes F2.", not Kit.overlay.is_open()))
			await control(&"kit_tuning")
			await control(&"kit_tuning", false)
			await click_button(button("controls_discard"))
			_checks.append(assertion("Discard also restores the kit shortcut.", Kit.controls.slot(&"kit_tuning").get("key") == KEY_F2))
		"persist":
			await find_controls()
			await click_button(button("control_action", &"fly_forward", 0))
			await key(KEY_K)
			await key(KEY_K, false)
			var original_path: String = Kit.controls.path
			var report_path: String = report_dir.path_join("controls.tres")
			if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(report_dir)) != OK:
				return false
			# Exercise Apply against an evidence copy, preserving the designer's project file.
			Kit.controls.path = report_path
			await click_button(button("controls_apply"))
			var applied: KitControlSet = ResourceLoader.load(report_path, "", ResourceLoader.CACHE_MODE_IGNORE)
			_checks.append(assertion("Apply writes readable controls and clears the trial.", applied != null and not Kit.controls.is_trial(&"fly_forward") and applied.bindings[&"fly_forward"][0].key == KEY_K))
			if applied == null:
				return false
			Kit.controls.clear()
			var restored: bool = Kit.controls.register(load("res://addons/agent_kit/controls/kit.tres")) and Kit.controls.register(applied, report_path)
			_checks.append(assertion("A fresh registration uses the project's saved key.", restored and Kit.controls.slot(&"fly_forward").get("key") == KEY_K))
			Kit.controls.reset_defaults()
			_checks.append(assertion("Reset after Apply is a trial; Discard returns to the applied K.", Kit.controls.is_trial(&"fly_forward") and Kit.controls.slot(&"fly_forward").get("key") == KEY_W))
			Kit.controls.discard()
			_checks.append(assertion("Discard restores the applied binding.", Kit.controls.slot(&"fly_forward").get("key") == KEY_K))
			_checks.append(assertion("Save payloads omit controls.", not Kit.snapshot().has("controls") and not Kit.snapshot().has("bindings")))
			Kit.controls.clear()
			var defaults: bool = Kit.controls.register(load("res://addons/agent_kit/controls/kit.tres")) and Kit.controls.register(applied, original_path, true)
			_checks.append(assertion("Scenario registration ignores saved rebinds and starts from declared defaults.", defaults and Kit.controls.slot(&"fly_forward").get("key") == KEY_W))
			Kit.overlay._refresh_tuning()
	return true
