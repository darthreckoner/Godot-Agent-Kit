extends KitActionHandler

func check(ctx: Dictionary) -> Array[KitCheckResult]:
	var ship: Dictionary = ctx.world.record(ctx.actor)
	var revenue: float = 0.0
	for ore: String in ship.cargo:
		revenue += float(ship.cargo[ore]) * float(ctx.tuning.value("economy.%s_price" % ore))
	var refuel: float = (float(ship.energy_max) - float(ship.energy)) * float(ctx.tuning.value("economy.refuel_price"))
	return [KitCheckResult.make(&"economy.can_afford_refuel", float(ship.credits) + revenue >= refuel, "Cargo sale and current credits must cover a full refill.")]

func plan(ctx: Dictionary) -> KitChangeSet:
	var result: KitChangeSet = KitChangeSet.new()
	var ship: Dictionary = ctx.world.record(ctx.actor)
	for ore: String in ship.cargo:
		var quantity: float = float(ship.cargo[ore])
		result.add(KitResourceDelta.make(ctx.actor, "credits", quantity * float(ctx.tuning.value("economy.%s_price" % ore)), "tuning/economy.%s_price" % ore))
		result.add(KitResourceDelta.make(ctx.actor, "cargo." + ore, -quantity, "rule/sell_all_cargo"))
	var missing: float = float(ship.energy_max) - float(ship.energy)
	result.add(KitResourceDelta.make(ctx.actor, "credits", -missing * float(ctx.tuning.value("economy.refuel_price")), "tuning/economy.refuel_price"))
	result.add(KitResourceDelta.make(ctx.actor, "energy", missing, "rule/refill_to_energy_max"))
	return result
