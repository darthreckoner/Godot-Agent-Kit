extends "res://scenarios/mining_scenario.gd"
func _init() -> void:
	id = &"mine_full_cargo"
	description = "Clip new ore at shared capacity without removing existing cargo."
func setup() -> bool:
	if not super.setup():
		return false
	Kit.world.writable = true
	var ok: bool = Kit.world.set_field(&"ship:player", "cargo.gold", float(Kit.tuning.value("ship.cargo_capacity")) - 1.0)
	Kit.world.writable = false
	return ok
func steps() -> Array[Dictionary]:
	return mine_steps()
func expect() -> Array[Dictionary]:
	var data: Dictionary = Kit.world.record(&"ship:player")
	var total: float = float(data.cargo.iron) + float(data.cargo.gold) + float(data.cargo.stone)
	var records: Array[Dictionary] = Kit.log.records()
	return [
		assertion("New ore was clipped.", records[-1].outcome == "clipped", records[-1].outcome, "clipped"),
		assertion("Cargo is exactly at capacity.", close(total, float(data.cargo_capacity)), total, data.cargo_capacity),
		assertion("Existing gold was preserved.", close(float(data.cargo.gold), float(data.cargo_capacity) - 1.0)),
		assertion("Only the available one unit of iron was collected.", close(float(data.cargo.iron), 1.0))
	]
