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
@export var overflow_policy: OverflowPolicy = OverflowPolicy.REJECT
