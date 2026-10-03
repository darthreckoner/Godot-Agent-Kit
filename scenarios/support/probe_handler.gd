extends KitActionHandler
func plan(ctx: Dictionary) -> KitChangeSet:
	var result: KitChangeSet = KitChangeSet.new()
	match str(ctx.params.get("probe", "")):
		"rng":
			var generator: RandomNumberGenerator = ctx.rng.stream(&"probe")
			var reward: float = float(generator.randi_range(1, 5))
			var second: float = generator.randf()
			result.add(KitResourceDelta.make(ctx.actor, "credits", reward + second, "rule/audited_rng"))
		"negative":
			result.add(KitResourceDelta.make(ctx.actor, "credits", 10.0, "rule/first_change"))
			result.add(KitResourceDelta.make(ctx.actor, "energy", -10000.0, "rule/reject_negative"))
		"overflow":
			result.add(KitResourceDelta.make(ctx.actor, "cargo.iron", 10000.0, "rule/reject_capacity"))
		"mutate":
			var allowed: bool = ctx.world.set_field(ctx.actor, "energy", 0.0)
			result.has_yield = allowed
		"add_remove":
			result.add(KitRecordChange.add(&"dock:temporary", &"dock", {"position": [2.0, 0.0, 0.0]}, "rule/add_record"))
			result.add(KitRecordChange.remove_id(&"dock:home", "rule/remove_record"))
	return result
