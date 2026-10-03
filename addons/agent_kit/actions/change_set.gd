class_name KitChangeSet
extends RefCounted
var changes: Array[KitChange] = []
var has_yield: bool = true
var payload: Dictionary = {}
var extra_events: Array[StringName] = []
var no_yield_rule: StringName = &"action.has_yield"
var no_yield_message: String = "This attempt would yield nothing; no cost was charged."

func add(change: KitChange) -> KitChangeSet:
	changes.append(change)
	return self
