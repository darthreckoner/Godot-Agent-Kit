extends KitScenario
var _checks: Array[Dictionary] = []

func _init() -> void:
	id = &"scenario_tuning_pins"
	description = "Scenario pins validate together, preserve resources and files, and establish the Discard baseline."

func setup() -> bool:
	_checks.clear()
	Kit.reset(20261004, true)
	var mining: MiningTuning = load("res://game/tuning/mining.tres")
	Kit.tuning.register(mining)
	return pin_tuning({"mining.energy_cost": 4.0, "mining.charge_on_attempt": 0})

func steps() -> Array[Dictionary]:
	return [{"command": "pin_contracts"}, {"command": "advance"}]

func execute_custom(_command: Dictionary, _view: Node) -> bool:
	if _command.command != "pin_contracts":
		return false
	var before_file: String = FileAccess.get_sha256("res://game/tuning/mining.tres")
	if before_file.is_empty():
		return false
	var resource: KitTuningSet = Kit.tuning.sets[&"mining"]
	_checks.append(assertion("A valid list pins multiple knobs and keeps resource identity.", pin_tuning({"mining.energy_cost": 5.0, "mining.charge_on_attempt": 1}) and resource == Kit.tuning.sets[&"mining"] and resource.get("energy_cost") == 5.0 and resource.get("charge_on_attempt") == 1))
	_checks.append(assertion("Pinned knobs are the baseline, not trials.", not Kit.tuning.is_trial(&"mining", "energy_cost") and not Kit.tuning.is_trial(&"mining", "charge_on_attempt")))
	_checks.append(assertion("A live trial succeeds.", Kit.tuning.trial("mining.energy_cost", 6.0)))
	Kit.tuning.discard(&"mining")
	_checks.append(assertion("Discard restores the pinned value.", resource.get("energy_cost") == 5.0))
	var before: Dictionary = Kit.tuning.snapshot()
	var pins_before: Dictionary = tuning_pins.duplicate(true)
	for invalid: Dictionary in [
		{"mining.energy_cost": 7.0, "mining.missing": 1.0},
		{"mining.energy_cost": 7.0, "mining.tool_power": 100.0},
		{"mining.energy_cost": NAN},
		{"mining.charge_on_attempt": 0.5}
	]:
		var refused: bool = not pin_tuning(invalid)
		_checks.append(assertion("An invalid list changes neither tuning nor its recorded pins and explains why.", refused and Kit.tuning.snapshot() == before and tuning_pins == pins_before and not setup_message.is_empty()))
	_checks.append(assertion("Scenario pins preserve project files.", FileAccess.get_sha256("res://game/tuning/mining.tres") == before_file))
	return true

func expect() -> Array[Dictionary]:
	return _checks.duplicate(true)
