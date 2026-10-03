extends "res://scenarios/mining_scenario.gd"
func _init() -> void:
	id = &"economy_round_trip"
	description = "Mine, fly to the dock, sell ore and buy a full refill."
func steps() -> Array[Dictionary]:
	var commands: Array[Dictionary] = mine_steps()
	for index: int in range(28):
		commands.append({"command": "queue", "action": "move_ship", "actor": "ship:player", "params": {"direction": [-1.0, 0.0, 0.0]}})
		commands.append({"command": "advance", "ticks": 1})
	commands.append({"command": "run", "action": "sell_and_refuel", "actor": "ship:player", "params": {"dock": "dock:home"}})
	return commands
func expect() -> Array[Dictionary]:
	var values: Dictionary = numbers()
	var credits: float = float(Kit.tuning.value("ship.starting_credits")) + float(Kit.tuning.value("mining.iron_yield")) * float(Kit.tuning.value("economy.iron_price")) - float(values.energy_spent) * float(Kit.tuning.value("economy.refuel_price"))
	return [
		assertion("Dock trade committed.", Kit.log.records()[-1].outcome == "success"),
		assertion("Credits include ore sale less refuelling.", close(float(values.credits), credits), values.credits, credits),
		assertion("Energy is full.", close(float(values.energy), float(Kit.tuning.value("ship.energy_max")))),
		assertion("Cargo was sold.", close(float(values.cargo.iron), 0.0))
	]
