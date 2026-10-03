class_name KitChange
extends RefCounted
var entity: StringName
var field: String
var reason: String
var cost_only: bool = false

func apply(_world: KitWorld) -> bool:
	return false

func describe() -> String:
	return reason

func to_dict() -> Dictionary:
	return {"entity": str(entity), "field": field, "reason": reason, "cost_only": cost_only}
