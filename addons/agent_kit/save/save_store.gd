class_name KitSaveStore
extends RefCounted
const SCHEMA_VERSION: int = 1
const KIT_VERSION: String = "0.3.0"
var last_message: String = ""

func _wrapper(payload: Dictionary) -> Dictionary:
	return {"kit_version": KIT_VERSION, "schema_version": SCHEMA_VERSION, "created": Time.get_datetime_string_from_system(true), "checksum_sha256": KitCanonical.hash_value(payload), "payload": payload}

func _read(path: String) -> Dictionary:
	var read: Dictionary = KitCanonical.read_json(path)
	if not read.ok:
		return read
	var data: Dictionary = read.data
	for key: String in ["kit_version", "schema_version", "created", "checksum_sha256", "payload"]:
		if not data.has(key):
			return {"ok": false, "error": "Save is missing " + key}
	if not data.kit_version is String or not data.created is String or not data.checksum_sha256 is String or not (data.schema_version is int or data.schema_version is float) or float(data.schema_version) != floorf(float(data.schema_version)):
		return {"ok": false, "error": "Save wrapper fields have the wrong types."}
	if not data.payload is Dictionary or str(data.checksum_sha256) != KitCanonical.hash_value(data.payload):
		return {"ok": false, "error": "Save checksum does not match."}
	var version: int = int(data.schema_version)
	if version > SCHEMA_VERSION or version < 0:
		return {"ok": false, "error": "This save uses an unsupported schema."}
	var payload: Dictionary = data.payload
	while version < SCHEMA_VERSION:
		var path_to_migration: String = "res://addons/agent_kit/migrations/v%d_to_v%d.gd" % [version, version + 1]
		if not ResourceLoader.exists(path_to_migration):
			return {"ok": false, "error": "Missing migration: " + path_to_migration}
		var migration: RefCounted = load(path_to_migration).new()
		payload = migration.migrate(payload)
		if payload.is_empty():
			return {"ok": false, "error": "Migration could not read the old payload."}
		version += 1
	if not Kit.validate_snapshot(payload):
		return {"ok": false, "error": "Save payload has invalid records or continuation state."}
	return {"ok": true, "payload": payload}

func write(path: String) -> bool:
	last_message = ""
	var temporary: String = path + ".tmp"
	var readable: String = JSON.stringify(KitCanonical.normalize(_wrapper(Kit.snapshot())), "  ", true, false)
	var error: Error = KitCanonical.write_text(temporary, readable)
	if error != OK:
		last_message = "Save could not be written: " + error_string(error)
		return false
	var verified: Dictionary = _read(temporary)
	if not verified.ok:
		last_message = "The temporary save did not pass verification: " + str(verified.get("error", "unknown error"))
		return false
	if FileAccess.file_exists(path):
		if _read(path).ok:
			error = DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
		else:
			error = DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".rejected"))
		if error != OK:
			last_message = "The previous save could not be preserved: " + error_string(error)
			return false
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if error != OK:
		last_message = "The verified save could not replace its destination: " + error_string(error)
		return false
	return true

func load_file(path: String) -> bool:
	var read: Dictionary = _read(path)
	var fallback: bool = false
	if not read.ok:
		if FileAccess.file_exists(path):
			var error: Error = DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".rejected"))
			if error != OK:
				last_message = "The unreadable save could not be preserved: " + error_string(error)
				return false
		read = _read(path + ".bak")
		fallback = true
	if not read.ok:
		last_message = "Neither the save nor its backup is valid: " + str(read.get("error", "unknown error"))
		return false
	if not Kit.restore(read.payload):
		last_message = "The save could not be restored."
		return false
	last_message = "Recovered the previous valid save." if fallback else "Save loaded."
	return true
