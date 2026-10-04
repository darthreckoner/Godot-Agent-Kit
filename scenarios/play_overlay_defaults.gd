extends "res://scenarios/support/play_scenario.gd"
func _init() -> void:
	requires_play = true
	id = &"play_overlay_defaults"
	description = "Inspect every default F1 tab and empty-search F2 before filling panels; explain an input-driven refusal."
func setup() -> bool:
	_checks.clear()
	return start_from_launch()
func steps() -> Array[Dictionary]:
	return [
		{"command": "default_tabs"},
		{"command": "default_tuning"},
		{"command": "refuse"},
		{"command": "screenshot", "name": "refusal_explained"}
	]
func execute_custom(command: Dictionary, view: Node) -> bool:
	match str(command.command):
		"default_tabs":
			await key(KEY_F1)
			await key(KEY_F1, false)
			var panel: PanelContainer = Kit.overlay.get("_inspector")
			var tabs: TabContainer = panel.get_child(0).get_child(1)
			_checks.append(assertion("F1 opens on World with no prefilled selection.", panel.visible and tabs.current_tab == 0 and Kit.overlay.get("_selected") == &"dock:home"))
			for index: int in range(tabs.get_tab_count()):
				tabs.current_tab = index
				await Kit.get_tree().process_frame
				match index:
					0:
						var entities: ItemList = Kit.overlay.get("_entities")
						var fields: ItemList = Kit.overlay.get("_fields")
						_checks.append(assertion("Default World lists sorted entities and setup values.", entities.item_count == 32 and entities.get_item_text(0) == "dock:home" and entities.get_item_text(31) == "ship:player" and fields.item_count == 2))
					1:
						var why: RichTextLabel = Kit.overlay.get("_why")
						_checks.append(assertion("Default Why explains setup values and shows no false refusal.", why.get_parsed_text().contains("No recorded change.") and not Kit.overlay.get("_refusal_box").visible))
					2:
						_checks.append(assertion("Default Log explains its empty state with empty filters.", Kit.overlay.get("_action_filter").text.is_empty() and Kit.overlay.get("_outcome_filter").text.is_empty() and Kit.overlay.get("_timeline").get_parsed_text() == "No actions recorded yet."))
					3:
						_checks.append(assertion("Default Events explains its empty state.", Kit.overlay.get("_event_text").get_parsed_text().begins_with("No events recorded yet.")))
					4:
						_checks.append(assertion("Default Feel offers both cosmetic variants without any action history.", Kit.overlay.get("_a").item_count == 2 and Kit.overlay.get("_b").item_count == 2 and Kit.overlay.get("_b").get_item_text(1).contains("same damage")))
				_checks.append(assertion("Default %s screenshot saved." % tabs.get_tab_title(index), await shot("default_" + tabs.get_tab_title(index).to_lower())))
			await key(KEY_F1)
			await key(KEY_F1, false)
		"default_tuning":
			await key(KEY_F2)
			await key(KEY_F2, false)
			var rows: VBoxContainer = Kit.overlay.get("_knob_rows")
			var search: LineEdit = Kit.overlay.get("_search")
			var groups: int = 0
			for child: Node in rows.get_children():
				if child is Button and child.has_meta("tuning_group"):
					groups += 1
			_checks.append(assertion("Default F2 lists all groups, collapsed, with a visible focused empty search.", search.text.is_empty() and search.has_focus() and groups == Kit.tuning.sets.size() and search.size.y >= 30))
			_checks.append(assertion("Default F2 screenshot saved.", await shot("default_tuning")))
			await key(KEY_F2)
			await key(KEY_F2, false)
		"refuse":
			var clicked: bool = await click_rock(view, &"rock:000")
			await key(KEY_SPACE)
			Kit.clock.advance()
			await key(KEY_SPACE, false)
			await key(KEY_F1)
			await key(KEY_F1, false)
			var tabs: TabContainer = Kit.overlay.get("_inspector").get_child(0).get_child(1)
			tabs.current_tab = 1
			var text: Label = Kit.overlay.get("_refusal_text")
			_checks.append(assertion("A Space refusal is explained without changing the default dock selection.", clicked and Kit.overlay.get("_selected") == &"dock:home" and text.text.contains("mining.in_range") and Kit.overlay.get("_refusal_box").visible))
			_checks.append(assertion("The empty-filter Log and Events also show the input-driven refusal.", Kit.overlay.get("_timeline").get_parsed_text().contains("Refused by mining.in_range") and Kit.overlay.get("_event_text").get_parsed_text().contains("mine_rejected")))
	return true
