extends KitActionHandler
func plan(ctx: Dictionary) -> KitChangeSet:
	var result: KitChangeSet = KitChangeSet.new()
	match str(ctx.params.get("probe", "")):
		"two_streams":
			# Deliberately create/draw in reverse textual order.
			var zeta: int = ctx.rng.stream(&"zeta").randi()
			var alpha: int = ctx.rng.stream(&"alpha").randi()
			result.add(KitResourceDelta.make(ctx.actor, "credits", float((zeta % 5) + (alpha % 5)), "rule/two_streams"))
		"touch":
			result.add(KitResourceDelta.make(ctx.actor, "credits", 1.0, "rule/terrain_probe"))
			result.add(KitResourceDelta.make(&"terrain:0000", "health", -0.25, "rule/terrain_probe"))
		"read_ownership":
			var read: Dictionary = ctx.world.record(ctx.actor)
			read.cargo.iron = 99999.0
			var position: Array = ctx.world.field(ctx.actor, "position")
			position[0] = 99999.0
			result.add(KitResourceDelta.make(ctx.actor, "credits", 1.0, "rule/read_ownership"))
		"mutate_authority":
			# Even temporarily toggling writable cannot bypass the transaction lock.
			var was_writable: bool = Kit.world.writable
			Kit.world.writable = true
			var allowed: bool = Kit.world.set_field(ctx.actor, "energy", 0.0) or Kit.world.restore({})
			Kit.world.writable = was_writable
			ctx.world.writable = true
			allowed = allowed or ctx.world.set_field(ctx.actor, "energy", 0.0) or ctx.world.restore({})
			result.has_yield = allowed
		"invalid_add":
			result.add(KitResourceDelta.make(ctx.actor, "credits", 1.0, "rule/first_change"))
			result.add(KitRecordChange.add(&"dock:bad", &"dock", {"position": [1.0]}, "rule/bad_shape"))
		"rng":
			var generator: RandomNumberGenerator = ctx.rng.stream(&"probe")
			var reward: float = float(generator.randi_range(1, 5))
			var second: float = generator.randf()
			result.add(KitResourceDelta.make(ctx.actor, "credits", reward + second, "rule/audited_rng"))
		"negative":
			ctx.rng.stream(&"rejected").randi()
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
