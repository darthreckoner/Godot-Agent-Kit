extends KitActionHandler

func check(ctx: Dictionary) -> Array[KitCheckResult]:
	var target: StringName = StringName(ctx.params.get("target", ""))
	var rock: Dictionary = ctx.world.record(target)
	var usable: bool = rock.get("type", "") == "rock" and float(rock.get("health", 0.0)) > 0.0
	return [KitCheckResult.make(&"mining.target_alive", usable, "Choose a rock that has not already broken.")]

func plan(ctx: Dictionary) -> KitChangeSet:
	var result: KitChangeSet = KitChangeSet.new()
	var target: StringName = StringName(ctx.params.target)
	var rock: Dictionary = ctx.world.record(target)
	var power: float = float(ctx.tuning.value("mining.tool_power"))
	var hardness: float = float(rock.hardness)
	result.has_yield = power >= hardness
	result.no_yield_rule = &"mining.tool_vs_hardness"
	result.no_yield_message = "This rock is too hard for the current tool. No energy was charged."
	result.add(KitResourceDelta.make(ctx.actor, "energy", -float(ctx.tuning.value("mining.energy_cost")), "tuning/mining.energy_cost", true))
	result.add(KitSetField.make(ctx.actor, "mine_ready_at", ctx.clock.seconds() + float(ctx.tuning.value("mining.cooldown")), "tuning/mining.cooldown", true))
	result.payload = {"broke": false, "hardness": hardness, "no_yield": not result.has_yield}
	if result.has_yield:
		var damage: float = power - hardness + 1.0
		var health: float = maxf(0.0, float(rock.health) - damage)
		result.add(KitSetField.make(target, "health", health, "rule/tool_power_vs_hardness + tuning/mining.tool_power"))
		if health == 0.0:
			var ore: String = str(rock.ore_type)
			var amount: float = float(ctx.tuning.value("mining.%s_yield" % ore))
			result.add(KitResourceDelta.make(ctx.actor, "cargo." + ore, amount, "tuning/mining.%s_yield" % ore))
			result.add(KitSetField.make(target, "ore_amount", 0.0, "rule/rock_break"))
			result.payload.broke = true
			result.extra_events.append(&"rock_break")
	return result
