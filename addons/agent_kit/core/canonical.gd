class_name KitCanonical
extends RefCounted
## Canonical JSON: sorted keys, six decimal places, finite numbers only.
static func normalize(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		var keys: Array = value.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		for key: Variant in keys:
			result[str(key)] = normalize(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(normalize(item))
		return result
	if value is float:
		var rounded: float = roundf(value * 1000000.0) / 1000000.0
		# JSON parses whole numbers as floats: canonicalize 4 and 4.0 alike.
		return int(rounded) if absf(rounded) <= 9007199254740991.0 and rounded == floorf(rounded) else rounded
	if value is StringName:
		return str(value)
	return value

static func encode(value: Variant) -> String:
	return JSON.stringify(normalize(value), "", true, false)

static func hash_value(value: Variant) -> String:
	return encode(value).sha256_text()

static func write_text(path: String, content: String) -> Error:
	var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if error != OK:
		return error
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.flush()
	error = file.get_error()
	file.close()
	return error

static func read_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": error_string(FileAccess.get_open_error())}
	var content: String = file.get_as_text()
	var error: Error = file.get_error()
	file.close()
	if error != OK and error != ERR_FILE_EOF:
		return {"ok": false, "error": error_string(error)}
	var parser: JSON = JSON.new()
	if parser.parse(content) != OK or not parser.data is Dictionary:
		return {"ok": false, "error": "The file is not a valid JSON object."}
	return {"ok": true, "data": parser.data}
