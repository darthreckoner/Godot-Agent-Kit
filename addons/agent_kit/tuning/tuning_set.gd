class_name KitTuningSet
extends Resource
@export var id: StringName
@export var description: String

func knobs() -> Dictionary:
	var constants: Dictionary = get_script().get_script_constant_map()
	return constants.get("KNOBS", {})

func metadata(knob: String) -> Dictionary:
	var result: Dictionary = knobs().get(knob, {}).duplicate(true)
	for property: Dictionary in get_property_list():
		if property.name == knob and property.hint == PROPERTY_HINT_RANGE:
			var parts: PackedStringArray = str(property.hint_string).split(",")
			result["min"] = float(parts[0])
			result["max"] = float(parts[1])
			result["step"] = float(parts[2]) if parts.size() > 2 else 0.01
			result["unit"] = ""
			for part: String in parts:
				if part.begins_with("suffix:"):
					result["unit"] = part.trim_prefix("suffix:")
	return result
