class_name KitCondition
extends Resource
@export var rule_id: StringName
@export var description: String
@export_enum("has_resource", "in_range", "cooldown_ready", "custom") var kind: String = "custom"
@export var field: String
@export var tuning_key: String
@export var target_param: String = "target"

func check(ctx: Dictionary) -> KitCheckResult:
	var ok: bool = true
	match kind:
		"has_resource":
			ok = float(ctx.world.field(ctx.actor, field)) >= float(ctx.tuning.value(tuning_key))
		"in_range":
			var target: StringName = StringName(ctx.params.get(target_param, ""))
			var origin: Variant = ctx.world.field(ctx.actor, field)
			var destination: Variant = ctx.world.field(target, field)
			ok = origin is Array and destination is Array and origin.size() == destination.size() and not origin.is_empty()
			if ok:
				var squared_distance: float = 0.0
				for index: int in range(origin.size()):
					squared_distance += pow(float(origin[index]) - float(destination[index]), 2.0)
				ok = sqrt(squared_distance) <= float(ctx.tuning.value(tuning_key))
		"cooldown_ready":
			ok = ctx.clock.seconds() + 0.000001 >= float(ctx.world.field(ctx.actor, field))
		"custom":
			ok = false
	return KitCheckResult.make(rule_id, ok, description)
