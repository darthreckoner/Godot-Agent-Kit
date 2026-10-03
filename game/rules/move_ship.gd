extends KitActionHandler

func check(ctx: Dictionary) -> Array[KitCheckResult]:
	var direction: Variant = ctx.params.get("direction")
	var valid: bool = direction is Array and direction.size() == 3
	if valid:
		for value: Variant in direction:
			valid = valid and (value is float or value is int) and is_finite(float(value))
	return [KitCheckResult.make(&"flight.direction", valid, "Flight needs three numeric direction components.")]

func plan(ctx: Dictionary) -> KitChangeSet:
	var result: KitChangeSet = KitChangeSet.new()
	var ship: Dictionary = ctx.world.record(ctx.actor)
	var input: Array = ctx.params.direction
	var direction: Vector3 = Vector3(input[0], input[1], input[2]).limit_length()
	var current: Vector3 = Vector3(ship.velocity[0], ship.velocity[1], ship.velocity[2])
	var dt: float = 1.0 / ctx.clock.tick_rate
	var velocity: Vector3 = current.move_toward(direction * float(ctx.tuning.value("ship.speed")), float(ctx.tuning.value("ship.accel")) * dt)
	var position: Vector3 = Vector3(ship.position[0], ship.position[1], ship.position[2]) + velocity * dt
	result.add(KitSetField.make(ctx.actor, "velocity", [velocity.x, velocity.y, velocity.z], "tuning/ship.speed + tuning/ship.accel"))
	result.add(KitSetField.make(ctx.actor, "position", [position.x, position.y, position.z], "rule/fixed_tick_flight"))
	return result
