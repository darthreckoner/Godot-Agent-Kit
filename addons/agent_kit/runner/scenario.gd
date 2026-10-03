class_name KitScenario
extends RefCounted
var id: StringName
var description: String
var variant: String = ""
var report_dir: String = ""
var render_mode: bool = false

func setup() -> bool:
	return true

func steps() -> Array[Dictionary]:
	return []

func expect() -> Array[Dictionary]:
	return []

func constraints() -> Dictionary:
	return {}

func comparison_variants() -> Array[String]:
	return []

func numbers() -> Dictionary:
	return {}

func render_scene() -> PackedScene:
	return null

static func assertion(label: String, passed: bool, actual: Variant = null, expected: Variant = null) -> Dictionary:
	return {"label": label, "passed": passed, "actual": actual, "expected": expected}

static func close(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= 0.00001
