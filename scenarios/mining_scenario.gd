extends KitScenario
const PARKED_AT_ROCK: Array = [2.5, 0.0, 0.0]

func setup() -> bool:
	if not MiningSetup.configure(20261003, true, variant):
		return false
	# Mining scenarios start parked with the drill against rock:000; mine_out_of_range covers the flight in.
	var parked: bool = Kit.world.set_field(&"ship:player", "position", PARKED_AT_ROCK)
	MiningSetup.finish_setup()
	return parked

func start_from_launch() -> bool:
	if not MiningSetup.configure(20261003, true, variant):
		return false
	MiningSetup.finish_setup()
	return true

func render_scene() -> PackedScene:
	return load("res://game/views/mining_lab.tscn")

func numbers() -> Dictionary:
	var ship: Dictionary = Kit.world.record(&"ship:player")
	var spent: float = 0.0
	var ore: float = 0.0
	var times: Array[int] = []
	for record: Dictionary in Kit.log.records():
		if record.action == "mine":
			times.append(int(record.tick))
		for delta: Dictionary in record.deltas:
			if delta.entity == "ship:player" and delta.field == "energy" and float(delta.get("delta", 0.0)) < 0:
				spent -= float(delta.delta)
			if str(delta.field).begins_with("cargo.") and float(delta.get("delta", 0.0)) > 0:
				ore += float(delta.delta)
	return {"energy": ship.energy, "credits": ship.credits, "cargo": ship.cargo, "energy_spent": spent, "ore_yielded": ore, "action_ticks": times}

func mine_steps(target: String = "rock:000") -> Array[Dictionary]:
	var count: int = ceili(float(Kit.tuning.value("mining.rock_health")) / (float(Kit.tuning.value("mining.tool_power")) - float(Kit.world.field(StringName(target), "hardness")) + 1.0))
	var wait: int = ceili(float(Kit.tuning.value("mining.cooldown")) * Kit.clock.tick_rate)
	var commands: Array[Dictionary] = []
	for index: int in range(count):
		commands.append({"command": "run", "action": "mine", "actor": "ship:player", "params": {"target": target}})
		if index < count - 1:
			commands.append({"command": "advance", "ticks": wait})
	return commands

func basic_expect() -> Array[Dictionary]:
	var count: int = ceili(float(Kit.tuning.value("mining.rock_health")) / (float(Kit.tuning.value("mining.tool_power")) - float(Kit.tuning.value("mining.soft_threshold")) + 1.0))
	var energy: float = float(Kit.tuning.value("ship.energy_max")) - float(count) * float(Kit.tuning.value("mining.energy_cost"))
	var ore: float = float(Kit.tuning.value("mining.iron_yield"))
	return [
		assertion("Energy spent matches the tuning.", close(float(Kit.world.field(&"ship:player", "energy")), energy), Kit.world.field(&"ship:player", "energy"), energy),
		assertion("The soft rock broke.", close(float(Kit.world.field(&"rock:000", "health")), 0.0)),
		assertion("Iron yield matches the tuning.", close(float(Kit.world.field(&"ship:player", "cargo.iron")), ore), Kit.world.field(&"ship:player", "cargo.iron"), ore)
	]
