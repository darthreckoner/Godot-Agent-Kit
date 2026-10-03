class_name KitActionHandler
extends RefCounted

func check(_ctx: Dictionary) -> Array[KitCheckResult]:
	return []

func plan(_ctx: Dictionary) -> KitChangeSet:
	return KitChangeSet.new()
