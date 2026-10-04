class_name KitWorld
extends RefCounted

var types: Dictionary = {}
var _records: Dictionary = {}
var writable: bool = true
var _base: KitWorld
var _removed: Dictionary = {}
var _read_only: bool = false
var _locked: bool = false
var copied_records: int = 0

## Reads still return owned data. A read view cannot be made writable by a handler.
func read_view(view: KitWorld) -> void:
	view.types = types
	view._base = self
	view.writable = false
	view._read_only = true

## A transaction stores only changed records, with unchanged reads falling through to this world.
func begin_transaction(stage: KitWorld) -> bool:
	if _locked or _base != null or _read_only or stage == null or stage == self or not stage._records.is_empty() or stage._base != null:
		return false
	_locked = true
	stage.types = types
	stage._base = self
	return true

func finish_transaction(stage: KitWorld, commit: bool) -> bool:
	if not _locked or stage == null or stage._base != self:
		return false
	if commit:
		# No callbacks run between validation and these replacements/removals.
		for id: StringName in stage._removed:
			_records.erase(id)
		for id: StringName in stage._records:
			_records[id] = stage._records[id]
	_locked = false
	# A retained planning/staging reference must never be able to edit committed records.
	stage._records = {}
	stage._removed = {}
	stage._read_only = true
	return true

func _lookup(id: StringName) -> Dictionary:
	if _removed.has(id):
		return {}
	if _records.has(id):
		return _records[id]
	return _base._lookup(id) if _base != null else {}

func _can_write() -> bool:
	return writable and not _read_only and not _locked

func _stage_record(id: StringName) -> void:
	if _base != null and not _records.has(id):
		_records[id] = KitCanonical.normalize(_base._lookup(id))
		copied_records += 1

func register_type(definition: KitRecordType) -> void:
	types[definition.id] = definition

func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	var combined: Dictionary = {}
	if _base != null:
		for id: StringName in _base.ids():
			if not _removed.has(id):
				combined[id] = true
	for id: Variant in _records:
		combined[id] = true
	for id: Variant in combined:
		result.append(StringName(id))
	# Sorting StringNames directly is not alphabetical in Godot; compare their text.
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	return result

func record(id: StringName) -> Dictionary:
	return _lookup(id).duplicate(true)

func field(id: StringName, path: String) -> Variant:
	var value: Variant = _lookup(id)
	for part: String in path.split("."):
		if not value is Dictionary or not value.has(part):
			return null
		value = value[part]
	return value.duplicate(true) if value is Dictionary or value is Array else value

func put(id: StringName, type_id: StringName, fields: Dictionary) -> bool:
	if not _can_write() or id.is_empty() or not _lookup(id).is_empty() or not types.has(type_id):
		return false
	var definition: KitRecordType = types[type_id]
	if fields.size() != definition.fields.size():
		return false
	for key: String in definition.fields:
		if not fields.has(key) or not _matches(fields[key], str(definition.fields[key])):
			return false
	var data: Dictionary = fields.duplicate(true)
	data["type"] = str(type_id)
	_records[id] = data
	_removed.erase(id)
	return true

func set_field(id: StringName, path: String, value: Variant) -> bool:
	if not _can_write() or _lookup(id).is_empty():
		return false
	var parts: PackedStringArray = path.split(".")
	var definition: KitRecordType = types[StringName(_lookup(id).type)]
	if not definition.fields.has(parts[0]):
		return false
	if parts.size() == 1 and not _matches(value, str(definition.fields[parts[0]])):
		return false
	_stage_record(id)
	var container: Dictionary = _records[id]
	for index: int in range(parts.size() - 1):
		if not container.get(parts[index]) is Dictionary:
			return false
		container = container[parts[index]]
	container[parts[-1]] = value.duplicate(true) if value is Array or value is Dictionary else value
	return true

func remove(id: StringName) -> bool:
	if not _can_write() or _lookup(id).is_empty():
		return false
	_records.erase(id)
	if _base != null:
		_removed[id] = true
	return true

func dump() -> Dictionary:
	var result: Dictionary = {}
	for id: StringName in ids():
		result[str(id)] = record(id)
	return KitCanonical.normalize(result)

func snapshot() -> Dictionary:
	return dump()

func restore(data: Dictionary) -> bool:
	if _read_only or _locked or _base != null:
		return false
	var previous: Dictionary = _records
	_records = {}
	var was_writable: bool = writable
	writable = true
	for id: String in data:
		if not data[id] is Dictionary:
			_records = previous
			writable = was_writable
			return false
		var fields: Dictionary = data[id].duplicate(true)
		if not fields.get("type") is String and not fields.get("type") is StringName:
			_records = previous
			writable = was_writable
			return false
		var type_id: StringName = StringName(fields.get("type", ""))
		fields.erase("type")
		if not types.has(type_id):
			_records = previous
			writable = was_writable
			return false
		var definition: KitRecordType = types[type_id]
		for key: String in definition.fields:
			if fields.has(key) and str(definition.fields[key]) == "int":
				if not (fields[key] is int or fields[key] is float) or not is_finite(float(fields[key])) or float(fields[key]) != floorf(float(fields[key])):
					_records = previous
					writable = was_writable
					return false
				fields[key] = int(fields[key])
		if not put(StringName(id), type_id, fields):
			_records = previous
			writable = was_writable
			return false
	writable = was_writable
	return true

func state_hash() -> String:
	return KitCanonical.hash_value(dump())

func validate(clip: bool = false) -> Dictionary:
	return _validate_ids(ids(), clip)

## Validate and canonicalize only the staged records; untouched records were already valid.
func validate_changes() -> Dictionary:
	if _base == null or not _can_write():
		return {"ok": false, "message": "Only a writable transaction may validate staged changes."}
	for id: StringName in _records:
		_records[id] = KitCanonical.normalize(_records[id])
	var changed: Array[StringName] = []
	for id: StringName in _records:
		changed.append(id)
	changed.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	return _validate_ids(changed, false)

func _validate_ids(record_ids: Array[StringName], clip: bool) -> Dictionary:
	if clip and not _can_write():
		return {"ok": false, "message": "A read-only world cannot clip records."}
	var clipped: bool = false
	for id: StringName in record_ids:
		if clip:
			_stage_record(id)
		var data: Dictionary = _lookup(id)
		var definition: KitRecordType = types[StringName(data.type)]
		for key: String in definition.fields:
			if not _matches(data.get(key), str(definition.fields[key])):
				return {"ok": false, "message": "%s.%s has the wrong type." % [id, key]}
		for key: String in definition.array_lengths:
			if not data.get(key) is Array or data[key].size() != int(definition.array_lengths[key]):
				return {"ok": false, "message": "%s.%s has the wrong number of entries." % [id, key]}
		for key: String in definition.limits:
			var rule: Dictionary = definition.limits[key]
			var value: Variant = data[key]
			var total: float = 0.0
			if value is Dictionary:
				for entry: Variant in value:
					if not (value[entry] is float or value[entry] is int) or not is_finite(float(value[entry])) or float(value[entry]) < float(rule.get("min", 0.0)):
						return {"ok": false, "message": "%s.%s cannot be negative or nonnumeric." % [id, key]}
					total += float(value[entry])
			else:
				total = float(value)
				if not is_finite(total) or total < float(rule.get("min", 0.0)):
					return {"ok": false, "message": "%s.%s would go below its minimum." % [id, key]}
			if rule.has("max_field"):
				var maximum: float = float(data[rule.max_field])
				if total > maximum + 0.000001:
					if not clip:
						return {"ok": false, "message": "%s.%s would exceed capacity." % [id, key]}
					clipped = true
					if value is Dictionary:
						var keys: Array = value.keys()
						keys.sort()
						var excess: float = total - maximum
						# Stable clipping order. The runner supplies positive-delta preference below.
						for entry: Variant in keys:
							var removed: float = minf(excess, float(value[entry]))
							value[entry] = float(value[entry]) - removed
							excess -= removed
					else:
						data[key] = maximum
	return {"ok": true, "clipped": clipped}

func _matches(value: Variant, kind: String) -> bool:
	match kind:
		"float": return (value is float or value is int) and is_finite(float(value))
		"int": return value is int
		"string": return value is String or value is StringName
		"bool": return value is bool
		"array":
			if not value is Array:
				return false
			for number: Variant in value:
				if not (number is float or number is int) or not is_finite(float(number)):
					return false
			return true
		"dictionary": return value is Dictionary
	return false
