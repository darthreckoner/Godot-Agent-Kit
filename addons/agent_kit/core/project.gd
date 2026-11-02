class_name KitProject
extends RefCounted
## Where a game keeps its kit declarations, rules and scenarios. A game whose folders differ
## from the kit's convention (game/, game/rules/, scenarios/) says so in res://kit.project.json:
##   {"content_folders": ["res://data/kit_tuning"], "rules_folders": [], "scenario_folder": "res://tests/kit_scenarios"}
## Every key is optional. A missing file means the convention. A broken file is reported as an
## error and the convention is used, so the run fails loudly instead of checking the wrong folders.
const PATH: String = "res://kit.project.json"
const DEFAULTS: Dictionary = {"content_folders": ["res://game"], "rules_folders": ["res://game/rules"], "scenario_folder": "res://scenarios"}

static func settings() -> Dictionary:
	var result: Dictionary = DEFAULTS.duplicate(true)
	if not FileAccess.file_exists(PATH):
		return result
	var text: String = FileAccess.get_file_as_string(PATH)
	if text.is_empty() and FileAccess.get_open_error() != OK:
		push_error("Cannot read %s: %s." % [PATH, error_string(FileAccess.get_open_error())])
		return result
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("%s is not a JSON object. Using the kit's default folders." % PATH)
		return result
	for key: Variant in parsed:
		if not DEFAULTS.has(key):
			push_error("%s has an unknown setting \"%s\". Known settings: %s." % [PATH, key, ", ".join(DEFAULTS.keys())])
			return DEFAULTS.duplicate(true)
		var value: Variant = parsed[key]
		var folders: Array = value if value is Array else [value]
		if (key == "scenario_folder") != (value is String):
			push_error("%s: \"%s\" must be %s." % [PATH, key, "one res:// folder" if key == "scenario_folder" else "a list of res:// folders"])
			return DEFAULTS.duplicate(true)
		for folder: Variant in folders:
			if not folder is String or not str(folder).begins_with("res://") or str(folder).contains(".."):
				push_error("%s: \"%s\" has %s, which is not a res:// folder inside the project." % [PATH, key, JSON.stringify(folder)])
				return DEFAULTS.duplicate(true)
		result[key] = value
	return result

static func content_folders() -> Array[String]:
	var result: Array[String] = []
	result.assign(settings().content_folders)
	return result

static func scenario_folder() -> String:
	return str(settings().scenario_folder)
