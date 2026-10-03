class_name KitRecordChange
extends KitChange
var type_id: StringName
var fields: Dictionary = {}
var remove_record: bool = false

static func add(id: StringName, type: StringName, data: Dictionary, why: String) -> KitRecordChange:
	var change: KitRecordChange = KitRecordChange.new()
	change.entity = id
	change.type_id = type
	change.fields = data
	change.reason = why
	return change

static func remove_id(id: StringName, why: String) -> KitRecordChange:
	var change: KitRecordChange = KitRecordChange.new()
	change.entity = id
	change.remove_record = true
	change.reason = why
	return change

func apply(world: KitWorld) -> bool:
	return world.remove(entity) if remove_record else world.put(entity, type_id, fields)

func to_dict() -> Dictionary:
	var result: Dictionary = super.to_dict()
	result.merge({"kind": "remove_record" if remove_record else "add_record", "type": str(type_id), "fields": fields})
	return result
