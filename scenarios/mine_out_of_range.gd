extends "res://scenarios/mining_scenario.gd"
func _init() -> void:
	id = &"mine_out_of_range"
	description = "A rock out of drill reach rejects without cost; flying in and stopping makes it minable."
func setup() -> bool:
	return start_from_launch()
func steps() -> Array[Dictionary]:
	var commands: Array[Dictionary] = [{"command": "run", "action": "mine", "actor": "ship:player", "params": {"target": "rock:000"}}]
	for index: int in range(20):
		commands.append({"command": "queue", "action": "move_ship", "actor": "ship:player", "params": {"direction": [1.0, 0.0, 0.0]}})
		commands.append({"command": "advance", "ticks": 1})
	for index: int in range(20):
		commands.append({"command": "queue", "action": "move_ship", "actor": "ship:player", "params": {"direction": [0.0, 0.0, 0.0]}})
		commands.append({"command": "advance", "ticks": 1})
	commands.append_array(mine_steps())
	return commands
func expect() -> Array[Dictionary]:
	var first: Dictionary = {}
	for record: Dictionary in Kit.log.records():
		if record.action == "mine":
			first = record
			break
	var failed: Array[String] = []
	for check: Dictionary in first.get("checks", []):
		if not check.passed:
			failed.append(str(check.rule_id))
	var ship: Array = Kit.world.field(&"ship:player", "position")
	var rock: Array = Kit.world.field(&"rock:000", "position")
	var distance: float = Vector3(ship[0], ship[1], ship[2]).distance_to(Vector3(rock[0], rock[1], rock[2]))
	return [
		assertion("Mining from the launch point was rejected.", first.get("outcome", "") == "rejected", first.get("outcome", ""), "rejected"),
		assertion("Only the reach rule failed.", failed == ["mining.in_range"], failed, ["mining.in_range"]),
		assertion("The rejected hit charged nothing.", first.get("deltas", [null]).is_empty()),
		assertion("The ship stopped within drill reach.", distance <= float(Kit.tuning.value("mining.range")), distance, Kit.tuning.value("mining.range")),
		assertion("The rock broke after flying in.", close(float(Kit.world.field(&"rock:000", "health")), 0.0)),
		assertion("Iron yield matches the tuning.", close(float(Kit.world.field(&"ship:player", "cargo.iron")), float(Kit.tuning.value("mining.iron_yield"))))
	]
