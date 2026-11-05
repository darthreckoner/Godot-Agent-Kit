class_name KitSetField
extends KitChange
var value: Variant

static func make(id: StringName, path: String, next: Variant, why: String, cost: bool = false) -> KitChange:
	# Avoid a self-referencing static factory retaining this script at shutdown (see check_result.gd).
	# Engine issue: https://github.com/godotengine/godot/issues/122022
	var change: Variant = load("res://addons/agent_kit/actions/set_field.gd").new()
	change.entity = id
	change.field = path
	change.value = next
	change.reason = why
	change.cost_only = cost
	return change

func apply(world: KitWorld) -> bool:
	return world.set_field(entity, field, value)

func to_dict() -> Dictionary:
	var result: Dictionary = super.to_dict()
	result["kind"] = "set_field"
	result["value"] = value
	return result
