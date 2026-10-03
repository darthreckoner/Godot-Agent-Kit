class_name KitEventBus
extends RefCounted
signal fired(name: StringName, payload: Dictionary)
var declarations: Dictionary = {}
var history: Array[Dictionary] = []
var capacity: int = 512
var unbounded: bool = false

func register(registry: KitEventRegistry) -> void:
	declarations.merge(registry.declarations, true)

func valid(name: StringName, payload: Dictionary) -> bool:
	if not declarations.has(str(name)):
		if OS.is_debug_build():
			push_error("This event was not declared: %s" % name)
		return false
	for field: String in declarations[str(name)].get("fields", []):
		if not payload.has(field):
			if OS.is_debug_build():
				push_error("Event %s is missing %s." % [name, field])
			return false
	return true

func emit_event(name: StringName, payload: Dictionary, tick: int) -> bool:
	if not valid(name, payload):
		return false
	history.append({"name": str(name), "payload": payload.duplicate(true), "tick": tick})
	if not unbounded and history.size() > capacity:
		history.pop_front()
	fired.emit(name, payload.duplicate(true))
	return true
