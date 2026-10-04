class_name KitOverlay
extends CanvasLayer
var _inspector: PanelContainer
var _tuning_panel: PanelContainer
var _entities: ItemList
var _fields: ItemList
var _why_fields: OptionButton
var _why_entity_button: Button
var _why_entity_popup: PopupPanel
var _why_entity_list: ItemList
var _why: RichTextLabel
var _refusal_box: PanelContainer
var _refusal_text: Label
var _refusal_show: Button
var _refusal_target: StringName
var _theme: Theme
var _timeline: RichTextLabel
var _event_text: RichTextLabel
var _action_filter: LineEdit
var _outcome_filter: LineEdit
var _search: LineEdit
var _knob_rows: VBoxContainer
var _expanded: Dictionary = {}
var _status: Label
var _a: OptionButton
var _b: OptionButton
var _selected: StringName
var _refresh_time: float = 0.0
var _variant_sequences: Array[KitFeelSequence] = []

func _ready() -> void:
	layer = 80
	_theme = _build_theme()
	_build_inspector()
	_build_tuning()
	_inspector.hide()
	_tuning_panel.hide()

func add_feel_variant(sequence: KitFeelSequence) -> void:
	_variant_sequences.append(sequence)

func clear_feel_variants() -> void:
	_variant_sequences.clear()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_inspector.visible = not _inspector.visible
			_tuning_panel.hide()
			_refresh_inspector()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F2:
			_tuning_panel.visible = not _tuning_panel.visible
			_inspector.hide()
			_refresh_tuning()
			if _tuning_panel.visible:
				_search.grab_focus()
			get_viewport().set_input_as_handled()

func is_open() -> bool:
	return _inspector.visible or _tuning_panel.visible

const INK: Color = Color(0.035, 0.06, 0.10, 0.97)
const SURFACE: Color = Color(0.08, 0.12, 0.17)
const ACCENT: Color = Color(0.39, 0.89, 0.90)
const ACCENT_DIM: Color = Color(0.26, 0.55, 0.63)
const WARM: Color = Color(1.0, 0.73, 0.46)
const MUTED: Color = Color(0.66, 0.74, 0.80)

func _box(fill: Color, border: Color, width: int = 1, radius: int = 5, left_width: int = -1) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	if left_width >= 0:
		style.border_width_left = left_width
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

## One look for every overlay control: outlined buttons, a filled primary button, banded group
## headers, boxed inputs, muted help text and accent section labels.
func _build_theme() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font_size = 17
	theme.set_stylebox("normal", "Button", _box(Color(0.12, 0.24, 0.29), ACCENT_DIM))
	theme.set_stylebox("hover", "Button", _box(Color(0.17, 0.34, 0.40), ACCENT))
	theme.set_stylebox("pressed", "Button", _box(Color(0.08, 0.17, 0.21), ACCENT))
	theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), ACCENT, 2))
	theme.set_stylebox("disabled", "Button", _box(SURFACE, Color(0.2, 0.25, 0.3)))
	theme.set_color("font_color", "Button", Color(0.92, 0.97, 0.98))
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_type_variation(&"KitPrimary", &"Button")
	theme.set_stylebox("normal", "KitPrimary", _box(Color(0.30, 0.78, 0.80), ACCENT))
	theme.set_stylebox("hover", "KitPrimary", _box(Color(0.45, 0.92, 0.93), Color.WHITE))
	theme.set_stylebox("pressed", "KitPrimary", _box(Color(0.22, 0.62, 0.64), ACCENT))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(state, "KitPrimary", Color(0.02, 0.06, 0.09))
	theme.set_type_variation(&"KitHeader", &"Button")
	theme.set_stylebox("normal", "KitHeader", _box(Color(0.09, 0.14, 0.20), ACCENT, 0, 3, 5))
	theme.set_stylebox("hover", "KitHeader", _box(Color(0.13, 0.21, 0.29), ACCENT, 0, 3, 5))
	theme.set_stylebox("pressed", "KitHeader", _box(Color(0.07, 0.11, 0.16), ACCENT, 0, 3, 5))
	theme.set_font_size("font_size", "KitHeader", 18)
	theme.set_type_variation(&"KitHelp", &"Label")
	theme.set_color("font_color", "KitHelp", MUTED)
	theme.set_font_size("font_size", "KitHelp", 15)
	theme.set_type_variation(&"KitSection", &"Label")
	theme.set_color("font_color", "KitSection", ACCENT)
	theme.set_font_size("font_size", "KitSection", 15)
	theme.set_stylebox("normal", "LineEdit", _box(Color(0.11, 0.16, 0.23), ACCENT_DIM, 2, 4))
	theme.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0), ACCENT, 2, 4))
	theme.set_color("font_placeholder_color", "LineEdit", Color(0.62, 0.70, 0.76))
	theme.set_stylebox("panel", "ItemList", _box(SURFACE, Color(0.16, 0.24, 0.30), 1, 4))
	theme.set_stylebox("selected", "ItemList", _box(Color(0.17, 0.34, 0.40), ACCENT, 1, 3))
	theme.set_stylebox("selected_focus", "ItemList", _box(Color(0.17, 0.34, 0.40), ACCENT, 1, 3))
	theme.set_stylebox("normal", "RichTextLabel", _box(SURFACE, Color(0.16, 0.24, 0.30), 1, 4))
	theme.set_stylebox("tab_selected", "TabContainer", _box(Color(0.12, 0.24, 0.29), ACCENT, 0, 3))
	theme.get_stylebox("tab_selected", "TabContainer").border_width_top = 3
	theme.set_stylebox("tab_unselected", "TabContainer", _box(Color(0.06, 0.09, 0.13), Color(0.16, 0.24, 0.30), 1, 3))
	theme.set_stylebox("tab_hovered", "TabContainer", _box(Color(0.10, 0.18, 0.23), ACCENT_DIM, 1, 3))
	theme.set_stylebox("panel", "TabContainer", _box(Color(0, 0, 0, 0), Color(0.16, 0.24, 0.30), 1, 0))
	theme.set_color("font_unselected_color", "TabContainer", MUTED)
	theme.set_color("font_selected_color", "TabContainer", Color.WHITE)
	theme.set_type_variation(&"KitNotice", &"PanelContainer")
	theme.set_stylebox("panel", "KitNotice", _box(Color(0.20, 0.13, 0.06), WARM, 2, 5))
	return theme

func _panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 40
	panel.offset_right = -40
	panel.offset_top = 90
	panel.offset_bottom = -45
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.06, 0.10, 0.97)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.border_color = Color(0.26, 0.55, 0.63)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.theme = _theme
	add_child(panel)
	return panel

func _styled(control: Control, variation: StringName) -> Control:
	control.theme_type_variation = variation
	return control

func _label(text: String, parent: Node) -> Label:
	var label: Label = Label.new()
	label.text = text
	parent.add_child(label)
	return label

func _button(text: String, parent: Node, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _rich(parent: Node) -> RichTextLabel:
	var rich: RichTextLabel = RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(rich)
	return rich

func _build_inspector() -> void:
	_inspector = _panel()
	var column: VBoxContainer = VBoxContainer.new()
	_inspector.add_child(column)
	_label("F1 · Ask your game why", column).add_theme_font_size_override("font_size", 24)
	var tabs: TabContainer = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	var world_tab: HBoxContainer = HBoxContainer.new()
	world_tab.name = "World"
	tabs.add_child(world_tab)
	_entities = ItemList.new()
	_entities.custom_minimum_size.x = 270
	_entities.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world_tab.add_child(_entities)
	_entities.item_selected.connect(func(index: int) -> void:
		_selected = StringName(_entities.get_item_text(index))
		_refresh_fields())
	var field_column: VBoxContainer = VBoxContainer.new()
	field_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_tab.add_child(field_column)
	_styled(_label("Select a value to read its history in Why.", field_column), &"KitHelp")
	_fields = ItemList.new()
	_fields.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field_column.add_child(_fields)
	_fields.item_selected.connect(func(index: int) -> void:
		var field: String = str(_fields.get_item_metadata(index))
		for option: int in range(_why_fields.item_count):
			if _why_fields.get_item_text(option) == field:
				_why_fields.select(option)
		tabs.current_tab = 1
		_refresh_why())
	var why_tab: VBoxContainer = VBoxContainer.new()
	why_tab.name = "Why"
	tabs.add_child(why_tab)
	# The newest refusal is answered here whatever is selected: it is the most common "why".
	_refusal_box = PanelContainer.new()
	_styled(_refusal_box, &"KitNotice")
	why_tab.add_child(_refusal_box)
	var refusal_row: HBoxContainer = HBoxContainer.new()
	_refusal_box.add_child(refusal_row)
	_refusal_text = _label("", refusal_row)
	_refusal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refusal_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_refusal_show = _button("Show it", refusal_row, func() -> void:
		_selected = _refusal_target
		_refresh_inspector())
	_refusal_show.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pickers: HBoxContainer = HBoxContainer.new()
	why_tab.add_child(pickers)
	_label("Thing", pickers)
	# A short scrolling list under the button: long worlds must not cover the screen.
	_why_entity_button = _button("", pickers, func() -> void:
		var origin: Vector2 = _why_entity_button.get_screen_position() + Vector2(0, _why_entity_button.size.y + 2)
		_why_entity_popup.popup(Rect2i(Vector2i(origin), Vector2i(int(_why_entity_button.size.x), 340)))
		_why_entity_list.ensure_current_is_visible())
	_why_entity_button.custom_minimum_size.x = 260
	_why_entity_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_why_entity_popup = PopupPanel.new()
	_why_entity_button.add_child(_why_entity_popup)
	_why_entity_list = ItemList.new()
	_why_entity_popup.add_child(_why_entity_list)
	_why_entity_list.item_selected.connect(func(index: int) -> void:
		_why_entity_popup.hide()
		_selected = _why_entity_list.get_item_metadata(index)
		_refresh_inspector())
	_label("  Value", pickers)
	_why_fields = OptionButton.new()
	_why_fields.custom_minimum_size.x = 220
	pickers.add_child(_why_fields)
	_why_fields.item_selected.connect(func(_index: int) -> void: _refresh_why())
	_why = _rich(why_tab)
	var log_tab: VBoxContainer = VBoxContainer.new()
	log_tab.name = "Log"
	tabs.add_child(log_tab)
	var filters: HBoxContainer = HBoxContainer.new()
	log_tab.add_child(filters)
	_action_filter = LineEdit.new()
	_action_filter.placeholder_text = "Filter by action"
	_action_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(_action_filter)
	_outcome_filter = LineEdit.new()
	_outcome_filter.placeholder_text = "Filter by outcome"
	_outcome_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(_outcome_filter)
	_timeline = _rich(log_tab)
	_timeline.scroll_following = true
	var events_tab: VBoxContainer = VBoxContainer.new()
	events_tab.name = "Events"
	tabs.add_child(events_tab)
	_event_text = _rich(events_tab)
	var feel_tab: VBoxContainer = VBoxContainer.new()
	feel_tab.name = "Feel"
	tabs.add_child(feel_tab)
	_label("Replay presentation. Outcomes have already committed.", feel_tab)
	var controls: HBoxContainer = HBoxContainer.new()
	feel_tab.add_child(controls)
	_button("Replay last", controls, func() -> void: Kit.feel.replay())
	_button("0.25×", controls, func() -> void: Kit.feel.time_scale = 0.25)
	_button("1×", controls, func() -> void: Kit.feel.time_scale = 1.0)
	_button("Skip to final stage", controls, func() -> void: Kit.feel.skip())
	_a = OptionButton.new()
	_b = OptionButton.new()
	feel_tab.add_child(_a)
	_button("Play / use A", feel_tab, func() -> void: _play_variant(_a))
	feel_tab.add_child(_b)
	_button("Play / use B", feel_tab, func() -> void: _play_variant(_b))
	_label("A/B changes only the sequence subscribed to its event.", feel_tab)
	_button("Close inspector", column, func() -> void: _inspector.hide())

func _play_variant(picker: OptionButton) -> void:
	if picker.item_count == 0:
		return
	var sequence: KitFeelSequence = picker.get_item_metadata(picker.selected)
	Kit.feel.register(sequence)
	Kit.feel.play(sequence, Kit.feel.last_payload)

func _refresh_inspector() -> void:
	_entities.clear()
	_why_entity_list.clear()
	if _selected.is_empty() and not Kit.world.ids().is_empty():
		_selected = Kit.world.ids()[0]
	var kind: String = ""
	for id: StringName in Kit.world.ids():
		_entities.add_item(str(id))
		if id == _selected:
			_entities.select(_entities.item_count - 1)
		# Group the Why picker by record type, e.g. "Dock", "Rock", "Ship".
		if str(Kit.world.record(id).get("type", "")) != kind:
			kind = str(Kit.world.record(id).get("type", ""))
			var heading: int = _why_entity_list.add_item(kind.capitalize())
			_why_entity_list.set_item_selectable(heading, false)
			_why_entity_list.set_item_custom_fg_color(heading, ACCENT)
		var item: int = _why_entity_list.add_item("    " + str(id))
		_why_entity_list.set_item_metadata(item, id)
		if id == _selected:
			_why_entity_list.select(item)
	_why_entity_button.text = "%s  ▾" % _selected
	_refresh_fields()
	for picker: OptionButton in [_a, _b]:
		picker.clear()
		for sequence: KitFeelSequence in _variant_sequences:
			picker.add_item(sequence.description)
			picker.set_item_metadata(picker.item_count - 1, sequence)
	if _b.item_count > 1:
		_b.select(1)
	_refresh_log()

func _refresh_fields() -> void:
	var old_field: String = _why_fields.get_item_text(_why_fields.selected) if _why_fields.item_count > 0 else ""
	_fields.clear()
	_why_fields.clear()
	var data: Dictionary = Kit.world.record(_selected)
	var keys: Array = data.keys()
	keys.sort()
	for key: String in keys:
		_fields.add_item("%s: %s" % [key.capitalize(), str(data[key])])
		_fields.set_item_metadata(_fields.item_count - 1, key)
		var history: Array[Dictionary] = Kit.log.changes_for(_selected, key)
		for record: Dictionary in history:
			if not record.deltas.is_empty() and int(record.tick) >= Kit.clock.tick - int(Kit.clock.tick_rate):
				_fields.set_item_custom_fg_color(_fields.item_count - 1, Color(1, 0.8, 0.35))
		_why_fields.add_item(key)
		if key == old_field:
			_why_fields.select(_why_fields.item_count - 1)
	_refresh_why()

func _refresh_refusal() -> void:
	var records: Array[Dictionary] = Kit.log.records()
	records.reverse()
	for record: Dictionary in records:
		var reasons: Array[String] = _refusals(record)
		if reasons.is_empty():
			continue
		_refusal_target = &""
		for value: Variant in record.params.values():
			if (value is String or value is StringName) and not Kit.world.record(StringName(value)).is_empty():
				_refusal_target = StringName(value)
		_refusal_text.text = "Latest refused action · %s\n%s" % [_log_line(record), "\n".join(reasons)]
		_refusal_show.text = "Show %s" % _refusal_target
		_refusal_show.visible = not _refusal_target.is_empty() and _refusal_target != _selected
		_refusal_box.visible = true
		return
	_refusal_box.visible = false

func _refresh_why() -> void:
	_refresh_refusal()
	_why.clear()
	if _why_fields.item_count == 0:
		return
	var field: String = _why_fields.get_item_text(_why_fields.selected)
	_why.append_text("[b]%s · %s[/b]\n\n" % [_selected, field.capitalize()])
	var records: Array[Dictionary] = Kit.log.changes_for(_selected, field)
	if records.is_empty():
		_why.append_text("No recorded change. This value came from setup or a loaded save.")
	for record: Dictionary in records:
		_why.append_text("[b]%s · %s · tick %d · %s[/b]\n" % [record.action, record.outcome, record.tick, record.input_source])
		for delta: Dictionary in record.deltas:
			if delta.entity == str(_selected) and (delta.field == field or str(delta.field).begins_with(field + ".")):
				_why.append_text("%s: %s → %s\nReason: %s\n" % [delta.field, str(delta.before), str(delta.after), delta.reason])
				if delta.has("delta"):
					_why.append_text("Change: %+.2f\n" % float(delta.delta))
		for check: Dictionary in record.checks:
			if not check.passed:
				_why.append_text("[color=#ffba76]%s: %s[/color]\n" % [check.rule_id, check.message])
		_why.append_text("\n")
	# A refused action changes nothing, so it only shows up here, under the thing it was aimed at.
	var aimed: Array[Dictionary] = []
	for record: Dictionary in Kit.log.records():
		if record.actor != str(_selected) and record.params.values().has(str(_selected)):
			aimed.append(record)
	if aimed.is_empty():
		return
	_why.append_text("\n[b]Actions aimed at %s (newest first)[/b]\n\n" % _selected)
	aimed.reverse()
	for record: Dictionary in aimed.slice(0, 10):
		_why.append_text("%s\n" % _log_line(record))
		for reason: String in _refusals(record):
			_why.append_text("[color=#ffba76]%s[/color]\n" % reason)
		_why.append_text("\n")

func _append_run(run: Array[Dictionary]) -> void:
	if run.size() == 1:
		_timeline.append_text("%s\n" % _log_line(run[0]))
	elif run.size() > 1:
		_timeline.append_text("[color=#a8bdcc]Ticks %d–%d · %s by %s · %s ×%d[/color]\n" % [run[0].tick, run[-1].tick, run[0].action, run[0].actor, str(run[0].outcome).replace("_", " "), run.size()])

func _log_line(record: Dictionary) -> String:
	var line: String = "Tick %d · #%d · %s by %s" % [record.tick, record.seq, record.action, record.actor]
	for key: String in record.params:
		line += " · %s %s" % [key, str(record.params[key])]
	return line + " · %s · %s" % [record.outcome.replace("_", " "), record.input_source]

func _refusals(record: Dictionary) -> Array[String]:
	var reasons: Array[String] = []
	for check: Dictionary in record.checks:
		if not check.passed:
			reasons.append("Refused by %s: %s" % [check.rule_id, check.message])
	if record.outcome == "attempted_no_yield":
		reasons.append("Cost paid under the ON_ATTEMPT charge policy; the attempt yielded nothing.")
	return reasons

func _refresh_log() -> void:
	_timeline.clear()
	# Godot's contains("") is false, so an empty filter must be treated as "show all".
	# Runs of the same action, actor and outcome with nothing refused collapse to one line.
	var run: Array[Dictionary] = []
	for record: Dictionary in Kit.log.records():
		if not _action_filter.text.is_empty() and not str(record.action).contains(_action_filter.text):
			continue
		if not _outcome_filter.text.is_empty() and not str(record.outcome).contains(_outcome_filter.text):
			continue
		var reasons: Array[String] = _refusals(record)
		if not run.is_empty() and (not reasons.is_empty() or record.action != run[0].action or record.actor != run[0].actor or record.outcome != run[0].outcome):
			_append_run(run)
			run.clear()
		if reasons.is_empty():
			run.append(record)
			continue
		_timeline.append_text("%s\n" % _log_line(record))
		for reason: String in reasons:
			_timeline.append_text("    [color=#ffba76]%s[/color]\n" % reason)
	_append_run(run)
	_event_text.clear()
	for event: Dictionary in Kit.events.history:
		_event_text.append_text("Tick %d · %s\n%s\n\n" % [event.tick, event.name, JSON.stringify(event.payload)])

func _build_tuning() -> void:
	_tuning_panel = _panel()
	var column: VBoxContainer = VBoxContainer.new()
	_tuning_panel.add_child(column)
	_label("F2 · Try a tuning value", column).add_theme_font_size_override("font_size", 24)
	var search_row: HBoxContainer = HBoxContainer.new()
	column.add_child(search_row)
	_label("Search", search_row).add_theme_font_size_override("font_size", 18)
	_search = LineEdit.new()
	_search.placeholder_text = "Type to filter, e.g. range, energy, speed, camera"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_row.add_child(_search)
	_search.text_changed.connect(func(_text: String) -> void: _refresh_tuning())
	_button("Clear", search_row, func() -> void:
		_search.text = ""
		_refresh_tuning()
		_search.grab_focus())
	_styled(_label("Every knob is listed by group. Click a group to open it, or type to filter.", column), &"KitHelp")
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_knob_rows = VBoxContainer.new()
	_knob_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_knob_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(_knob_rows)
	_status = _styled(_label("Moving a slider is a live trial. Each open group has Apply (save to its file) and Discard (undo trials) at its top.", column), &"KitHelp")
	_button("Close tuning", column, func() -> void: _tuning_panel.hide())

## Empty search lists every group collapsed; a search opens each group with a match.
func _refresh_tuning() -> void:
	for child: Node in _knob_rows.get_children():
		_knob_rows.remove_child(child)
		child.queue_free()
	var words: PackedStringArray = _search.text.to_lower().split(" ", false)
	# Game and kit settings first, then feel stages; each section alphabetical.
	var ids: Array = Kit.tuning.sets.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		var a_feel: bool = Kit.tuning.sets[a] is KitFeelStage
		var b_feel: bool = Kit.tuning.sets[b] is KitFeelStage
		return a_feel != b_feel and b_feel or a_feel == b_feel and str(a) < str(b))
	var section: String = ""
	for id: StringName in ids:
		var resource: KitTuningSet = Kit.tuning.sets[id]
		var rows: Array[String] = []
		var trials: int = 0
		for knob: String in resource.knobs():
			var metadata: Dictionary = resource.metadata(knob)
			var haystack: String = ("%s %s %s %s %s" % [id, resource.description, knob, knob.capitalize(), metadata.get("help", "")]).to_lower()
			var matched: bool = true
			for word: String in words:
				matched = matched and haystack.contains(word)
			if matched:
				rows.append(knob)
			if Kit.tuning.is_trial(id, knob):
				trials += 1
		if rows.is_empty():
			continue
		var next_section: String = "Feel stages · look and sound only, never rule outcomes" if resource is KitFeelStage else "Game and kit settings"
		if next_section != section:
			section = next_section
			_styled(_label(section.to_upper(), _knob_rows), &"KitSection")
		var open: bool = not words.is_empty() or bool(_expanded.get(id, false))
		var count: String = "%d knobs" % rows.size() if words.is_empty() else "%d of %d knobs match" % [rows.size(), resource.knobs().size()]
		var header: Button = _button("%s %s — %s · %s%s" % ["▾" if open else "▸", str(id).capitalize(), resource.description, count, " · %d on trial" % trials if trials > 0 else ""], _knob_rows, func() -> void:
			_expanded[id] = not bool(_expanded.get(id, false))
			_refresh_tuning())
		header.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_styled(header, &"KitHeader")
		header.set_meta("tuning_group", id)
		if not open:
			continue
		# Apply/Discard sit at the top of the group so they stay in view on long groups.
		var buttons: HBoxContainer = HBoxContainer.new()
		_knob_rows.add_child(buttons)
		_styled(_button("Apply " + str(id), buttons, func() -> void:
			var error: Error = Kit.tuning.apply(id)
			_status.text = "Saved " + str(id) if error == OK else "Could not save: " + error_string(error)
			_refresh_tuning()), &"KitPrimary")
		_button("Discard", buttons, func() -> void:
			Kit.tuning.discard(id)
			_refresh_tuning())
		var variant: LineEdit = LineEdit.new()
		variant.placeholder_text = "Variant name"
		variant.custom_minimum_size.x = 170
		buttons.add_child(variant)
		_button("Save as variant", buttons, func() -> void:
			var error: Error = Kit.tuning.save_variant(id, variant.text)
			_status.text = "Variant saved." if error == OK else "Could not save variant: " + error_string(error))
		for knob: String in rows:
			var metadata: Dictionary = resource.metadata(knob)
			var row: HBoxContainer = HBoxContainer.new()
			_knob_rows.add_child(row)
			var title: Label = _label("%s (%s)" % [knob.capitalize(), metadata.get("unit", "")], row)
			title.custom_minimum_size.x = 265
			var slider: HSlider = HSlider.new()
			slider.min_value = metadata.min
			slider.max_value = metadata.max
			slider.step = metadata.step
			slider.value = float(resource.get(knob))
			slider.custom_minimum_size.x = 260
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(slider)
			var value_label: Label = _label("", row)
			value_label.custom_minimum_size.x = 180
			var update: Callable = func(next: float) -> void:
				Kit.tuning.trial("%s.%s" % [id, knob], next)
				var trial: bool = Kit.tuning.is_trial(id, knob)
				value_label.text = "%.2f%s%s" % [next, " · Trial" if trial else "", " · Restart needed" if metadata.get("restart", false) else ""]
				title.modulate = Color(1, 0.8, 0.35) if trial else Color.WHITE
			slider.value_changed.connect(update)
			update.call(slider.value)
			var help: Label = _styled(_label("%s  Range: %s–%s %s" % [metadata.get("help", ""), metadata.min, metadata.max, metadata.get("unit", "")], _knob_rows), &"KitHelp")
			help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _knob_rows.get_child_count() == 0:
		_label("Nothing matches \"%s\". Try a word like range, energy, speed or camera, or press Clear to see every group." % _search.text, _knob_rows).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _process(delta: float) -> void:
	_refresh_time += delta
	if _refresh_time >= 0.3 and _inspector.visible:
		_refresh_time = 0.0
		_refresh_fields()
		_refresh_log()
