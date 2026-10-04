extends "res://scenarios/mining_scenario.gd"
func _init() -> void:
	id = &"feel_change_is_scoped"
	description = "Compare light and heavy impacts while preserving every mining outcome and tick."
func comparison_variants() -> Array[String]:
	return ["mine_hit", "mine_hit_heavy"]
func steps() -> Array[Dictionary]:
	var commands: Array[Dictionary] = mine_steps()
	if render_mode:
		commands.insert(1, {"command": "screenshot", "name": "impact", "stage": "Heavy impact" if variant.contains("heavy") else "Impact", "delay": 0.0})
		commands.append({"command": "screenshot", "name": "rock_broken", "delay": 0.3})
		commands.append({"command": "wait_for_feel", "timeout": 30.0})
	return commands
func expect() -> Array[Dictionary]:
	return basic_expect()
func constraints() -> Dictionary:
	var values: Dictionary = numbers()
	return {"mining.energy_cost": Kit.tuning.value("mining.energy_cost"), "mining.cooldown": Kit.tuning.value("mining.cooldown"), "energy_spent": values.energy_spent, "ore_yielded": values.ore_yielded, "action_ticks": values.action_ticks, "world_hash": Kit.world.state_hash()}
