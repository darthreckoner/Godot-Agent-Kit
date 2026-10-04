extends "res://scenarios/mining_scenario.gd"
func _init() -> void:
	id = &"mine_hard_rock"
	description = "Prove success-only rejection and paid zero-yield attempts."
func setup() -> bool:
	if not super.setup():
		return false
	Kit.world.writable = true
	# This scenario explicitly needs a rock harder than the tool, even after designer tuning.
	var ok: bool = Kit.world.set_field(&"rock:020", "position", [4.5, 0.0, 0.0]) and Kit.world.set_field(&"rock:020", "hardness", float(Kit.tuning.value("mining.tool_power")) + 1.0)
	Kit.world.writable = false
	return ok
func steps() -> Array[Dictionary]:
	return [
		{"command": "tune", "key": "mining.charge_on_attempt", "value": 0},
		{"command": "run", "action": "mine", "actor": "ship:player", "params": {"target": "rock:020"}},
		{"command": "tune", "key": "mining.charge_on_attempt", "value": 1},
		{"command": "queue", "action": "mine", "actor": "ship:player", "params": {"target": "rock:020"}},
		{"command": "advance", "ticks": 1}
	]
func expect() -> Array[Dictionary]:
	var records: Array[Dictionary] = Kit.log.records()
	if records.size() != 2:
		return [assertion("Both policy attempts completed.", false, records.size(), 2)]
	var energy: float = float(Kit.tuning.value("ship.energy_max")) - float(Kit.tuning.value("mining.energy_cost"))
	return [
		assertion("Success-only hard hit was rejected.", records[0].outcome == "rejected"),
		assertion("Rejected hit charged nothing.", records[0].deltas.is_empty()),
		assertion("Attempt policy committed zero yield.", records[1].outcome == "attempted_no_yield"),
		assertion("Exactly one energy cost was charged.", close(float(Kit.world.field(&"ship:player", "energy")), energy), Kit.world.field(&"ship:player", "energy"), energy),
		assertion("Hard rock was unchanged.", close(float(Kit.world.field(&"rock:020", "health")), float(Kit.tuning.value("mining.rock_health")))),
		assertion("The queued action resolved on the next tick.", int(records[1].tick) == 1)
	]
