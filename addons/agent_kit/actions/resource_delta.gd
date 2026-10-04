class_name KitResourceDelta
extends KitChange
var amount: float

static func make(id: StringName, path: String, delta: float, why: String, cost: bool = false) -> KitResourceDelta:
	var change: KitResourceDelta = KitResourceDelta.new()
	change.entity = id
	change.field = path
	change.amount = delta
	change.reason = why
	change.cost_only = cost
	return change

func apply(world: KitWorld) -> bool:
	var current: Variant = world.field(entity, field)
	if not (current is float or current is int):
		return false
	var next: float = float(current) + amount
	# Canonical whole-valued floats can be represented as ints. The declared field type,
	# rather than its current numeric representation, determines integer-only resources.
	var type_id: StringName = StringName(world.field(entity, "type"))
	var definition: KitRecordType = world.types[type_id]
	if not field.contains(".") and definition.fields.get(field) == "int":
		return next == floorf(next) and world.set_field(entity, field, int(next))
	return world.set_field(entity, field, next)

func to_dict() -> Dictionary:
	var result: Dictionary = super.to_dict()
	result["kind"] = "resource_delta"
	result["amount"] = amount
	return result

func describe() -> String:
	return "%s changes by %+.2f because of %s." % [field, amount, reason]
