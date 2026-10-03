class_name KitOverlay
extends CanvasLayer
var _inspector: PanelContainer
var _tuning_panel: PanelContainer
var _entities: ItemList
var _fields: ItemList
var _why_fields: OptionButton
var _why: RichTextLabel
var _timeline: RichTextLabel
var _event_text: RichTextLabel
var _action_filter: LineEdit
var _outcome_filter: LineEdit
var _search: LineEdit
var _knob_rows: VBoxContainer
var _status: Label
var _a: OptionButton
var _b: OptionButton
var _selected: StringName
var _refresh_time: float = 0.0
var _variant_sequences: Array[KitFeelSequence] = []

func _ready() -> void:
	layer = 80
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
			get_viewport().set_input_as_handled()

func is_open() -> bool:
	return _inspector.visible or _tuning_panel.visible

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
	add_child(panel)
	return panel

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
	_label("Select a value to read its history in Why.", field_column)
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
	_why_fields = OptionButton.new()
	why_tab.add_child(_why_fields)
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
	for id: StringName in Kit.world.ids():
		_entities.add_item(str(id))
		if id == _selected:
			_entities.select(_entities.item_count - 1)
	if _selected.is_empty() and _entities.item_count > 0:
		_selected = StringName(_entities.get_item_text(0))
		_entities.select(0)
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

func _refresh_why() -> void:
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

func _refresh_log() -> void:
	_timeline.clear()
	for record: Dictionary in Kit.log.records():
		if not str(record.action).contains(_action_filter.text) or not str(record.outcome).contains(_outcome_filter.text):
			continue
		_timeline.append_text("Tick %d · #%d · %s · %s · %s\n" % [record.tick, record.seq, record.action, record.outcome, record.input_source])
	_event_text.clear()
	for event: Dictionary in Kit.events.history:
		_event_text.append_text("Tick %d · %s\n%s\n\n" % [event.tick, event.name, JSON.stringify(event.payload)])

func _build_tuning() -> void:
	_tuning_panel = _panel()
	var column: VBoxContainer = VBoxContainer.new()
	_tuning_panel.add_child(column)
	_label("F2 · Try a tuning value", column).add_theme_font_size_override("font_size", 24)
	_search = LineEdit.new()
	_search.placeholder_text = "Search names, groups, or help"
	column.add_child(_search)
	_search.text_changed.connect(func(_text: String) -> void: _refresh_tuning())
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_knob_rows = VBoxContainer.new()
	_knob_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_knob_rows)
	_status = _label("Sliders are live trials. Apply saves; Discard restores.", column)
	_button("Close tuning", column, func() -> void: _tuning_panel.hide())

func _refresh_tuning() -> void:
	for child: Node in _knob_rows.get_children():
		_knob_rows.remove_child(child)
		child.queue_free()
	var ids: Array = Kit.tuning.sets.keys()
	ids.sort()
	for id: StringName in ids:
		var resource: KitTuningSet = Kit.tuning.sets[id]
		var rows: Array[String] = []
		for knob: String in resource.knobs():
			var metadata: Dictionary = resource.metadata(knob)
			var haystack: String = ("%s %s %s" % [id, knob, metadata.get("help", "")]).to_lower()
			if haystack.contains(_search.text.to_lower()):
				rows.append(knob)
		if rows.is_empty():
			continue
		_label("%s — %s" % [str(id).capitalize(), resource.description], _knob_rows).add_theme_font_size_override("font_size", 19)
		for knob: String in rows:
			var metadata: Dictionary = resource.metadata(knob)
			var row: HBoxContainer = HBoxContainer.new()
			_knob_rows.add_child(row)
			var title: Label = _label("%s (%s)" % [knob.capitalize(), metadata.get("unit", "")], row)
			title.custom_minimum_size.x = 265
			title.tooltip_text = metadata.get("help", "")
			var slider: HSlider = HSlider.new()
			slider.min_value = metadata.min
			slider.max_value = metadata.max
			slider.step = metadata.step
			slider.value = float(resource.get(knob))
			slider.custom_minimum_size.x = 260
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.tooltip_text = "%s\nRange: %s–%s %s" % [metadata.get("help", ""), metadata.min, metadata.max, metadata.get("unit", "")]
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
			_label("%s  Range: %s–%s %s" % [metadata.get("help", ""), metadata.min, metadata.max, metadata.get("unit", "")], _knob_rows).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var buttons: HBoxContainer = HBoxContainer.new()
		_knob_rows.add_child(buttons)
		_button("Apply " + str(id), buttons, func() -> void:
			var error: Error = Kit.tuning.apply(id)
			_status.text = "Saved " + str(id) if error == OK else "Could not save: " + error_string(error)
			_refresh_tuning())
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

func _process(delta: float) -> void:
	_refresh_time += delta
	if _refresh_time >= 0.3 and _inspector.visible:
		_refresh_time = 0.0
		_refresh_fields()
		_refresh_log()
