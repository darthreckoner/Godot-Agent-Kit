class_name KitActionRecord
extends RefCounted
var data: Dictionary = {}

func to_dict() -> Dictionary:
	return data.duplicate(true)
