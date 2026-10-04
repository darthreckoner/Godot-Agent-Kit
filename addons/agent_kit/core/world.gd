class_name KitWorld
extends RefCounted

var types: Dictionary = {}
var _records: Dictionary = {}
var writable: bool = true

func register_type(definition: KitRecordType) -> void:
	types[definition.id] = definition

func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: Variant in _records:
		result.append(StringName(id))
	# Sorting StringNames directly is not alphabetical in Godot; compare their text.
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	return result

func record(id: StringName) -> Dictionary:
	return _records.get(id, {}).duplicate(true)

func field(id: StringName, path: String) -> Variant:
	var value: Variant = _records.get(id, {})
	for part: String in path.split("."):
		if not value is Dictionary or not value.has(part):
			return null
		value = value[part]
	return value.duplicate(true) if value is Dictionary or value is Array else value

func put(id: StringName, type_id: StringName, fields: Dictionary) -> bool:
	if not writable or id.is_empty() or _records.has(id) or not types.has(type_id):
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
	return true

func set_field(id: StringName, path: String, value: Variant) -> bool:
	if not writable or not _records.has(id):
		return false
	var parts: PackedStringArray = path.split(".")
	var definition: KitRecordType = types[StringName(_records[id].type)]
	if not definition.fields.has(parts[0]):
		return false
	if parts.size() == 1 and not _matches(value, str(definition.fields[parts[0]])):
		return false
	var container: Dictionary = _records[id]
	for index: int in range(parts.size() - 1):
		if not container.get(parts[index]) is Dictionary:
			return false
		container = container[parts[index]]
	container[parts[-1]] = value
	return true

func remove(id: StringName) -> bool:
	if not writable or not _records.has(id):
		return false
	return _records.erase(id)

func dump() -> Dictionary:
	var result: Dictionary = {}
	for id: StringName in ids():
		result[str(id)] = record(id)
	return KitCanonical.normalize(result)

func snapshot() -> Dictionary:
	return dump()

func restore(data: Dictionary) -> bool:
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
	var clipped: bool = false
	for id: StringName in ids():
		var data: Dictionary = _records[id]
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
