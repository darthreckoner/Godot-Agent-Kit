class_name KitActionLog
extends RefCounted
var _records: Array[KitActionRecord] = []
var unbounded: bool = false
var capacity: int = 512

func append(record: KitActionRecord) -> void:
	var retained: KitActionRecord = KitActionRecord.new()
	retained.data = record.to_dict()
	_records.append(retained)
	if not unbounded:
		while _records.size() > capacity:
			_records.pop_front()

func records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: KitActionRecord in _records:
		result.append(record.to_dict())
	return result

func clear() -> void:
	_records.clear()

func changes_for(entity_id: StringName, field: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: KitActionRecord in _records:
		for delta: Dictionary in record.data.deltas:
			if delta.entity == str(entity_id) and (field.is_empty() or delta.field == field or str(delta.field).begins_with(field + ".")):
				result.append(record.to_dict())
				break
		if record.data.outcome == "rejected" and record.data.actor == str(entity_id):
			result.append(record.to_dict())
	return result

func restore(records_data: Array) -> void:
	clear()
	for data: Dictionary in records_data:
		var record: KitActionRecord = KitActionRecord.new()
		record.data = data
		append(record)
