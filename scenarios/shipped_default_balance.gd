extends KitScenario
var _changes: Dictionary = {}
var _baseline: Dictionary = {}

func _init() -> void:
	id = &"shipped_default_balance"
	description = "Report changes to shipped mining, ship and economy defaults separately from rule fixtures."

func setup() -> bool:
	_changes.clear()
	var source: Dictionary = KitCanonical.read_json("res://scenarios/fixtures/default_balance.json")
	if not source.ok or not source.data is Dictionary:
		return false
	_baseline = source.data
	if not MiningSetup.configure(20261003, true):
		return false
	MiningSetup.finish_setup()
	for key: String in _baseline:
		var actual: Variant = Kit.tuning.value(key)
		if actual == null:
			return false
		if not close(float(actual), float(_baseline[key])):
			_changes[key] = {"expected": _baseline[key], "shipped": actual}
	print("DEFAULT BALANCE: unchanged." if _changes.is_empty() else "DEFAULT BALANCE CHANGED (notice only): " + KitCanonical.encode(_changes))
	return true

func expect() -> Array[Dictionary]:
	return [assertion("Shipped default balance was inspected; differences are notices, not rule failures.", not _baseline.is_empty(), _changes)]

func numbers() -> Dictionary:
	return {"default_changes": _changes.duplicate(true)}
