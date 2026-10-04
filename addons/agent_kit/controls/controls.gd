class_name KitControls
extends RefCounted
signal changed()
var actions: Dictionary = {}
var bindings: Dictionary = {}
var path: String = ""
var last_message: String = ""
var _saved: Dictionary = {}
var _defaults: Dictionary = {}
var _project: KitControlSet

func clear() -> void:
	for id: StringName in actions:
		Input.action_release(id)
		InputMap.erase_action(id)
	actions.clear()
	bindings.clear()
	_saved.clear()
	_defaults.clear()
	path = ""
	_project = null

func register(resource: KitControlSet, project_path: String = "", use_defaults: bool = false) -> bool:
	last_message = ""
	if resource == null:
		last_message = "The controls declaration could not be loaded."
		return false
	var proposed_actions: Dictionary = actions.duplicate()
	var proposed_defaults: Dictionary = _defaults.duplicate(true)
	for action: KitControlAction in resource.actions:
		if action == null or action.id.is_empty() or action.description.is_empty() or action.group.is_empty() or proposed_actions.has(action.id) or InputMap.has_action(action.id):
			last_message = "Each control needs a unique action, description and group."
			return false
		proposed_actions[action.id] = action.duplicate(true)
		proposed_defaults[action.id] = action.keys.duplicate(true)
	if not _validate(proposed_defaults, proposed_actions):
		return false
	var proposed: Dictionary = proposed_defaults.duplicate(true) if use_defaults else bindings.duplicate(true)
	for action: KitControlAction in resource.actions:
		proposed[action.id] = action.keys.duplicate(true)
	if not use_defaults:
		for id: Variant in resource.bindings:
			if not (id is String or id is StringName) or not proposed_actions.has(StringName(id)):
				last_message = "Saved controls name an unknown action."
				return false
			proposed[StringName(id)] = resource.bindings[id]
	if not _validate(proposed, proposed_actions):
		return false
	actions = proposed_actions
	_defaults = proposed_defaults
	bindings = proposed.duplicate(true)
	_saved = bindings.duplicate(true)
	if not project_path.is_empty():
		path = project_path
		_project = resource.duplicate(true)
	_sync()
	return true

func _validate(values: Dictionary, declarations: Dictionary) -> bool:
	var owners: Dictionary = {}
	for id: Variant in values:
		var slots: Variant = values[id]
		if not declarations.has(id) or not slots is Array or slots.size() > 2:
			last_message = "Each control supports at most two key slots."
			return false
		for binding: Variant in slots:
			if not binding is Dictionary:
				last_message = "A control must be a keyboard key or mouse button."
				return false
			if binding.is_empty():
				continue
			if binding.size() != 1 or not (binding.has("key") or binding.has("mouse")):
				last_message = "A control must be a keyboard key or mouse button."
				return false
			var code: Variant = binding.get("key", binding.get("mouse"))
			if not code is int or code <= 0 or (binding.has("mouse") and code > MOUSE_BUTTON_XBUTTON2) or (binding.has("key") and OS.get_keycode_string(code).is_empty()):
				last_message = "That key or mouse button is not supported."
				return false
			var token: String = "%s:%d" % ["key" if binding.has("key") else "mouse", code]
			if owners.has(token):
				last_message = "%s is already %s." % [label(binding), declarations[owners[token]].description.to_lower()]
				return false
			owners[token] = id
	return true

static func from_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"key": int(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode)}
	if event is InputEventMouseButton:
		return {"mouse": int(event.button_index)}
	return {}

static func input_event(binding: Dictionary, pressed: bool = true) -> InputEvent:
	if binding.has("key"):
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = int(binding.key) as Key
		event.pressed = pressed
		return event
	if binding.has("mouse"):
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = int(binding.mouse) as MouseButton
		event.pressed = pressed
		return event
	return null

static func label(binding: Dictionary) -> String:
	if binding.has("key"):
		return "Numpad Enter" if int(binding.key) == KEY_KP_ENTER else OS.get_keycode_string(int(binding.key))
	if binding.has("mouse"):
		match int(binding.mouse):
			MOUSE_BUTTON_LEFT: return "Left mouse"
			MOUSE_BUTTON_RIGHT: return "Right mouse"
			MOUSE_BUTTON_MIDDLE: return "Middle mouse"
			MOUSE_BUTTON_WHEEL_UP: return "Wheel up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Wheel down"
			_: return "Mouse button %d" % int(binding.mouse)
	return "Unbound"

func slot(id: StringName, index: int = 0) -> Dictionary:
	var slots: Array = bindings.get(id, [])
	return slots[index].duplicate(true) if index >= 0 and index < slots.size() else {}

func text(id: StringName) -> String:
	var labels: Array[String] = []
	for binding: Dictionary in bindings.get(id, []):
		if not binding.is_empty():
			labels.append(label(binding))
	return " / ".join(labels) if not labels.is_empty() else "Unbound"

func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(actions.keys())
	result.sort_custom(func(a: StringName, b: StringName) -> bool:
		return actions[a].group < actions[b].group if actions[a].group != actions[b].group else str(a) < str(b))
	return result

func is_trial(id: StringName) -> bool:
	return bindings.get(id) != _saved.get(id)

func trial(id: StringName, index: int, binding: Dictionary) -> bool:
	if not actions.has(id) or index < 0 or index > 1:
		last_message = "Choose one of this control's two key slots."
		return false
	if not binding.is_empty():
		for owner: StringName in bindings:
			for other_slot: int in range(bindings[owner].size()):
				if owner == id and other_slot == index:
					continue
				if bindings[owner][other_slot] == binding:
					last_message = "%s is already %s." % [label(binding), actions[owner].description.to_lower()]
					return false
	var proposed: Dictionary = bindings.duplicate(true)
	while proposed[id].size() <= index:
		proposed[id].append({})
	proposed[id][index] = binding.duplicate(true)
	# Empty trailing slots do not represent a different binding.
	while not proposed[id].is_empty() and proposed[id][-1].is_empty():
		proposed[id].pop_back()
	if not _validate(proposed, actions):
		return false
	bindings = proposed
	last_message = "%s: %s · Trial. Apply to save, or Discard." % [actions[id].description, text(id)]
	_sync()
	return true

func discard() -> void:
	bindings = _saved.duplicate(true)
	last_message = "Controls trials discarded."
	_sync()

func reset_defaults() -> void:
	bindings = _defaults.duplicate(true)
	last_message = "Default controls restored as a trial. Apply to save, or Discard."
	_sync()

func apply() -> Error:
	if _project == null or not path.begins_with("res://") or path.begins_with("res://addons/agent_kit/"):
		last_message = "Register a game's project controls resource before applying controls."
		return ERR_FILE_BAD_PATH
	var candidate: KitControlSet = _project.duplicate(true)
	candidate.bindings = bindings.duplicate(true)
	var error: Error = ResourceSaver.save(candidate, path)
	last_message = "Controls saved to the project's defaults." if error == OK else "Could not save controls: " + error_string(error)
	if error == OK:
		_project = candidate
		_saved = bindings.duplicate(true)
		changed.emit()
	return error

func _sync() -> void:
	for id: StringName in actions:
		if not InputMap.has_action(id):
			InputMap.add_action(id)
		Input.action_release(id)
		InputMap.action_erase_events(id)
		for binding: Dictionary in bindings[id]:
			var event: InputEvent = input_event(binding)
			if event != null:
				InputMap.action_add_event(id, event)
	changed.emit()
