class_name KitTuningRegistry
extends RefCounted
signal changed(key: String)
var sets: Dictionary = {}
var paths: Dictionary = {}
var _original: Dictionary = {}
var last_message: String = ""

## Establish an in-memory baseline before scenario world setup, including Discard.
## Validate the complete list first; keep resource identity so feel stages stay linked.
func pin(values: Dictionary) -> bool:
	for key: Variant in values:
		var parts: PackedStringArray = str(key).split(".")
		if not (key is String or key is StringName) or parts.size() != 2 or not sets.has(StringName(parts[0])):
			last_message = "Scenario tuning cannot find " + str(key) + "."
			return false
		var resource: KitTuningSet = sets[StringName(parts[0])]
		var metadata: Dictionary = resource.metadata(parts[1])
		var next: Variant = values[key]
		if metadata.is_empty():
			last_message = "Scenario tuning cannot find " + str(key) + "."
			return false
		if not (next is int or next is float) or not is_finite(float(next)) or float(next) < metadata.min or float(next) > metadata.max:
			last_message = "Scenario tuning needs %s between %s and %s." % [key, metadata.min, metadata.max]
			return false
		if resource.get(parts[1]) is int and float(next) != floorf(float(next)):
			last_message = "Scenario tuning needs a whole number for " + str(key) + "."
			return false
	for key: Variant in values:
		var parts: PackedStringArray = str(key).split(".")
		var set_id: StringName = StringName(parts[0])
		var resource: KitTuningSet = sets[set_id]
		resource.set(parts[1], int(values[key]) if resource.get(parts[1]) is int else float(values[key]))
		_original[set_id][parts[1]] = resource.get(parts[1])
		changed.emit(str(key))
	last_message = "Scenario tuning is pinned in memory; project defaults are preserved."
	return true

func register(resource: KitTuningSet, path: String = "") -> void:
	sets[resource.id] = resource.duplicate(true)
	paths[resource.id] = path if not path.is_empty() else resource.resource_path
	_original[resource.id] = _values(sets[resource.id])

func value(key: String) -> Variant:
	var parts: PackedStringArray = key.split(".")
	if parts.size() != 2 or not sets.has(StringName(parts[0])):
		push_error("Unknown tuning value: " + key)
		return null
	return sets[StringName(parts[0])].get(parts[1])

func trial(key: String, next: Variant) -> bool:
	var parts: PackedStringArray = key.split(".")
	if parts.size() != 2 or not sets.has(StringName(parts[0])):
		return false
	var resource: KitTuningSet = sets[StringName(parts[0])]
	var metadata: Dictionary = resource.metadata(parts[1])
	if metadata.is_empty() or float(next) < metadata.min or float(next) > metadata.max:
		return false
	resource.set(parts[1], int(next) if resource.get(parts[1]) is int else float(next))
	changed.emit(key)
	return true

func is_trial(set_id: StringName, knob: String) -> bool:
	return sets[set_id].get(knob) != _original[set_id].get(knob)

func apply(set_id: StringName) -> Error:
	var path: String = paths.get(set_id, "")
	if path.is_empty():
		return ERR_FILE_BAD_PATH
	var error: Error = ResourceSaver.save(sets[set_id], path)
	if error == OK:
		_original[set_id] = _values(sets[set_id])
	return error

func discard(set_id: StringName) -> void:
	for knob: String in _original[set_id]:
		sets[set_id].set(knob, _original[set_id][knob])
		changed.emit("%s.%s" % [set_id, knob])

func save_variant(set_id: StringName, variant_name: String) -> Error:
	if variant_name.is_empty() or not variant_name.is_valid_filename() or variant_name.contains("."):
		return ERR_INVALID_PARAMETER
	var path: String = paths[set_id].get_base_dir().path_join("%s.%s.tres" % [set_id, variant_name])
	if FileAccess.file_exists(path):
		return ERR_ALREADY_EXISTS
	return ResourceSaver.save(sets[set_id], path)

func _values(resource: KitTuningSet) -> Dictionary:
	var result: Dictionary = {}
	for knob: String in resource.knobs():
		result[knob] = resource.get(knob)
	return result

func snapshot() -> Dictionary:
	var result: Dictionary = {}
	for set_id: StringName in sets:
		result[str(set_id)] = _values(sets[set_id])
	return result

func restore(data: Dictionary) -> bool:
	for set_id: String in data:
		if not sets.has(StringName(set_id)):
			return false
		for knob: String in data[set_id]:
			if not trial("%s.%s" % [set_id, knob], data[set_id][knob]):
				return false
	return true
