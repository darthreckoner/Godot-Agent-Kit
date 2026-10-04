class_name KitActionDef
extends Resource
enum ChargePolicy { ON_SUCCESS, ON_ATTEMPT }
enum OverflowPolicy { REJECT, CLIP }
@export var id: StringName
@export var description: String
@export var handler: Script
@export var requires: Array[KitCondition] = []
@export var tuning_set: StringName
@export var events_on_success: Array[StringName] = []
@export var events_on_reject: Array[StringName] = []
@export var events_on_clip: Array[StringName] = []
@export var charge_policy: ChargePolicy = ChargePolicy.ON_SUCCESS
## Optional integer tuning knob: 0 pays on success, 1 also pays on a zero-yield attempt.
## When set, this is the sole live policy source; charge_policy is the unbound default.
@export var charge_policy_key: String = ""
@export var overflow_policy: OverflowPolicy = OverflowPolicy.REJECT

func resolved_charge_policy(tuning: KitTuningRegistry) -> int:
	if charge_policy_key.is_empty():
		return int(charge_policy)
	var parts: PackedStringArray = charge_policy_key.split(".")
	if parts.size() != 2 or not tuning.sets.has(StringName(parts[0])):
		return -1
	var resource: KitTuningSet = tuning.sets[StringName(parts[0])]
	if resource.metadata(parts[1]).is_empty():
		return -1
	var value: Variant = resource.get(parts[1])
	if not value is int or value < 0 or value > 1:
		return -1
	return int(value)
