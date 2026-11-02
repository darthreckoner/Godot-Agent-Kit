extends "res://scenarios/support/play_scenario.gd"

func _init() -> void:
	requires_play = true
	id = &"play_tuning_side_panel"
	description = "Dock the tuning panel to the side with a real click; fly and drag a slider with it open; typing borrows the keyboard until Esc or a click on the game."

func setup() -> bool:
	_checks.clear()
	if Kit.overlay != null and Kit.overlay.is_tuning_docked():
		Kit.overlay.set_tuning_docked(false)
	return start_from_launch()

func steps() -> Array[Dictionary]:
	return [{"command": "dock"}, {"command": "fly_and_tune"}, {"command": "typing"}, {"command": "undock"}]

func click_at(point: Vector2) -> void:
	await Kit.get_tree().process_frame
	await Kit.get_tree().process_frame
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await Kit.get_tree().process_frame

func drag(from: Vector2, to: Vector2) -> void:
	await Kit.get_tree().process_frame
	await Kit.get_tree().process_frame
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = from
	press.pressed = true
	Input.parse_input_event(press)
	await Kit.get_tree().process_frame
	for step: int in range(1, 6):
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.position = from.lerp(to, step / 5.0)
		motion.relative = (to - from) / 5.0
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await Kit.get_tree().process_frame
	var release: InputEventMouseButton = press.duplicate()
	release.position = to
	release.pressed = false
	Input.parse_input_event(release)
	await Kit.get_tree().process_frame

func header(set_id: StringName) -> Button:
	for child: Node in Kit.overlay.get("_knob_rows").get_children():
		if child is Button and child.get_meta("tuning_group", &"") == set_id:
			return child
	return null

func slider(key: String) -> HSlider:
	for node: Node in Kit.overlay.get("_knob_rows").find_children("*", "HSlider", true, false):
		if node.get_meta("tuning_knob", "") == key:
			return node
	return null

func focus_owner() -> Control:
	return Kit.get_viewport().gui_get_focus_owner()

func ship() -> Array:
	return Kit.world.field(&"ship:player", "position")

func fly(ticks: int) -> void:
	await control(&"fly_forward")
	for index: int in range(ticks):
		Kit.clock.advance()
		await Kit.get_tree().process_frame
	await control(&"fly_forward", false)

func execute_custom(command: Dictionary, _view: Node) -> bool:
	var panel: PanelContainer = Kit.overlay.get("_tuning_panel")
	var view_size: Vector2 = Kit.get_viewport().get_visible_rect().size
	match str(command.command):
		"dock":
			await control(&"kit_tuning")
			await control(&"kit_tuning", false)
			_checks.append(assertion("Full screen stays the default and keeps the game's keys.", not Kit.overlay.is_tuning_docked() and Kit.overlay.captures_input() and focus_owner() == Kit.overlay.get("_search")))
			await click_at((Kit.overlay.get("_dock_button") as Button).get_global_rect().get_center())
			await Kit.get_tree().process_frame
			var rect: Rect2 = panel.get_global_rect()
			_checks.append(assertion("A real click on Side panel docks the panel to the right edge.", Kit.overlay.is_tuning_docked() and rect.position.x >= view_size.x * 0.5 and rect.end.x <= view_size.x and rect.position.y >= 0.0 and rect.end.y <= view_size.y, {"panel": rect, "window": view_size}))
			_checks.append(assertion("The side panel hands the keyboard back to the game.", not Kit.overlay.captures_input() and focus_owner() == null))
		"fly_and_tune":
			var before: Array = ship()
			var actions: int = Kit.log.records().size()
			await fly(8)
			_checks.append(assertion("The ship flies with the side panel open.", ship() != before and Kit.log.records().size() == actions + 8))
			await click_at(header(&"mining").get_global_rect().get_center())
			var cost: HSlider = slider("mining.energy_cost")
			_checks.append(assertion("Opening a group in the side panel shows its sliders.", cost != null and cost.is_visible_in_tree()))
			if cost == null:
				return true
			var original: float = float(Kit.tuning.value("mining.energy_cost"))
			var track: Rect2 = cost.get_global_rect()
			var grabber: Vector2 = Vector2(track.position.x + track.size.x * float((cost.value - cost.min_value) / (cost.max_value - cost.min_value)), track.get_center().y)
			await drag(grabber, grabber + Vector2(track.size.x * 0.2, 0.0))
			_checks.append(assertion("Dragging a slider in the side panel starts a trial.", Kit.tuning.is_trial(&"mining", "energy_cost") and float(Kit.tuning.value("mining.energy_cost")) > original, {"before": original, "after": Kit.tuning.value("mining.energy_cost")}))
			_checks.append(assertion("The slider does not keep the keyboard after a drag.", focus_owner() == null and not Kit.overlay.captures_input()))
			_checks.append(assertion("Side panel screenshot saved.", await shot("side_panel_trial")))
			before = ship()
			await fly(4)
			_checks.append(assertion("Flight keys still reach the game after tuning.", ship() != before))
			var discard: Button = null
			for node: Node in Kit.overlay.get("_knob_rows").find_children("*", "Button", true, false):
				if (node as Button).text == "Discard":
					discard = node
					break
			await click_at(discard.get_global_rect().get_center())
			_checks.append(assertion("Discard in the side panel restores the knob and leaves no focus behind.", is_equal_approx(float(Kit.tuning.value("mining.energy_cost")), original) and focus_owner() == null))
		"typing":
			var search: LineEdit = Kit.overlay.get("_search")
			await click_at(search.get_global_rect().get_center())
			_checks.append(assertion("Clicking the search box lets you type in the side panel.", focus_owner() == search and Kit.overlay.captures_input()))
			var before: Array = ship()
			await fly(4)
			_checks.append(assertion("While typing, flight keys do not move the ship.", ship() == before))
			await key(KEY_ESCAPE)
			await key(KEY_ESCAPE, false)
			_checks.append(assertion("Esc hands the keyboard back without closing the panel.", focus_owner() == null and panel.visible and not Kit.overlay.captures_input()))
			await click_at(search.get_global_rect().get_center())
			await click_at(Vector2(view_size.x * 0.2, view_size.y * 0.5))
			_checks.append(assertion("A click on the game hands the keyboard back.", focus_owner() == null and panel.visible and not Kit.overlay.captures_input()))
		"undock":
			await click_at((Kit.overlay.get("_dock_button") as Button).get_global_rect().get_center())
			await Kit.get_tree().process_frame
			_checks.append(assertion("Full screen returns and covers the game again.", not Kit.overlay.is_tuning_docked() and Kit.overlay.captures_input() and panel.get_global_rect().position.x <= 40.0))
			await control(&"kit_tuning")
			await control(&"kit_tuning", false)
			_checks.append(assertion("The tuning shortcut closes the panel.", not Kit.overlay.is_open()))
	return true
