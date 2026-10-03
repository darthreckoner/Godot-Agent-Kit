class_name KitActionResult
extends RefCounted
var outcome: String = "rejected"
var record: KitActionRecord
var message: String = ""

func committed() -> bool:
	return outcome != "rejected"
