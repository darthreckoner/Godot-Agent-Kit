class_name KitCheckResult
extends RefCounted
var rule_id: StringName
var passed: bool
var message: String

static func make(id: StringName, ok: bool, text: String) -> RefCounted:
	# Avoid a self-referencing static factory retaining this script at shutdown.
	# Engine issue: https://github.com/godotengine/godot/issues/122022
	var result: RefCounted = load("res://addons/agent_kit/actions/check_result.gd").new()
	result.rule_id = id
	result.passed = ok
	result.message = text
	return result

func to_dict() -> Dictionary:
	return {"rule_id": str(rule_id), "passed": passed, "message": message}
