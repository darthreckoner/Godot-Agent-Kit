extends "res://scenarios/mining_scenario.gd"
var _checks: Array[Dictionary] = []
func _init() -> void:
	id = &"kit_integrity"
	description = "Verify atomicity, RNG auditing, queue order, tuning trials, save recovery and migration."
func setup() -> bool:
	_checks.clear()
	if not super.setup():
		return false
	var definition: KitActionDef = KitActionDef.new()
	definition.id = &"probe"
	definition.description = "Exercise reusable kit contracts."
	definition.handler = load("res://scenarios/support/probe_handler.gd")
	Kit.actions.register(definition)
	return true
func steps() -> Array[Dictionary]:
	return [
		{"command": "contracts"},
		{"command": "queue", "action": "probe", "actor": "ship:player", "params": {"probe": "rng"}},
		{"command": "queue", "action": "probe", "actor": "ship:player", "params": {"probe": "rng"}},
		{"command": "advance", "ticks": 1},
		{"command": "save_checks"},
		{"command": "tuning_checks"}
	]
func execute_custom(command: Dictionary, _view: Node) -> bool:
	match str(command.command):
		"contracts":
			for probe: String in ["negative", "overflow", "mutate"]:
				var before: String = Kit.world.state_hash()
				var result: KitActionResult = Kit.actions.run(&"probe", &"ship:player", {"probe": probe}, "scenario")
				_checks.append(assertion("%s rejects atomically" % probe, result.outcome == "rejected" and Kit.world.state_hash() == before))
			var result: KitActionResult = Kit.actions.run(&"probe", &"ship:player", {"probe": "add_remove"}, "scenario")
			_checks.append(assertion("Record additions/removals commit together.", result.committed() and not Kit.world.record(&"dock:temporary").is_empty() and Kit.world.record(&"dock:home").is_empty()))
			var numeric: Dictionary = {"b": [4.0, 0.33333339], "a": {"z": 2, "x": 1.0}}
			var parsed: Variant = JSON.parse_string(KitCanonical.encode(numeric))
			_checks.append(assertion("Canonical hashes survive JSON numeric conversion.", KitCanonical.hash_value(numeric) == KitCanonical.hash_value(parsed)))
			_checks.append(assertion("Canonical keys are sorted and floats round to six places.", KitCanonical.encode(numeric) == '{"a":{"x":1,"z":2},"b":[4,0.333333]}'))
			var local_world: KitWorld = KitWorld.new()
			var type: KitRecordType = KitRecordType.new()
			type.id = &"unit"
			type.fields = {"position": "array", "quantity": "int"}
			local_world.register_type(type)
			var placed: bool = local_world.put(&"unit:a", &"unit", {"position": [0.0, 0.0], "quantity": 1}) and local_world.put(&"unit:b", &"unit", {"position": [1.2, 1.6], "quantity": 0})
			var condition: KitCondition = KitCondition.new()
			condition.rule_id = &"probe.2d_range"
			condition.kind = "in_range"
			condition.field = "position"
			condition.tuning_key = "mining.range"
			var check: KitCheckResult = condition.check({"world": local_world, "actor": &"unit:a", "params": {"target": "unit:b"}, "tuning": Kit.tuning})
			_checks.append(assertion("The reusable range condition works in 2D.", placed and check.passed))
			var increment: KitResourceDelta = KitResourceDelta.make(&"unit:a", "quantity", 2.0, "rule/integer_resource")
			_checks.append(assertion("Integer resource deltas retain the field type.", increment.apply(local_world) and local_world.field(&"unit:a", "quantity") == 3))
			var ring: KitActionLog = KitActionLog.new()
			ring.capacity = 2
			var source_record: KitActionRecord = KitActionRecord.new()
			source_record.data = {"value": 1}
			ring.append(source_record)
			source_record.data.value = 2
			_checks.append(assertion("The log owns an immutable copy of each appended record.", ring.records()[0].value == 1))
			ring.append(source_record)
			ring.append(source_record)
			_checks.append(assertion("Play log capacity bounds retained records.", ring.records().size() == 2))
		"save_checks":
			var path: String = report_dir.path_join("recovery.json")
			var before: String = Kit.simulation_hash()
			if not Kit.save.write(path) or not Kit.save.write(path):
				return false
			if KitCanonical.write_text(path, "{corrupt primary") != OK:
				return false
			var recovered: bool = Kit.save.load_file(path)
			_checks.append(assertion("Corrupt primary falls back to a valid backup.", recovered and Kit.simulation_hash() == before))
			_checks.append(assertion("Unreadable primary is preserved.", FileAccess.file_exists(path + ".rejected")))
			# A valid checksum must not let an invalid payload through.
			var malformed: Dictionary = {"kit_version": "0.1.0", "schema_version": 1, "created": "fixture", "payload": {"world": {}}, "checksum_sha256": KitCanonical.hash_value({"world": {}})}
			var invalid_path: String = report_dir.path_join("invalid.json")
			if KitCanonical.write_text(invalid_path, KitCanonical.encode(malformed)) != OK:
				return false
			_checks.append(assertion("Malformed payload is rejected without changing play.", not Kit.save.load_file(invalid_path) and Kit.simulation_hash() == before))
			var fixture: Dictionary = KitCanonical.read_json("res://addons/agent_kit/fixtures/schema0_shape.json")
			if not fixture.ok:
				return false
			var old_payload: Dictionary = Kit.snapshot()
			old_payload["records"] = old_payload.world
			old_payload.erase("world")
			var old: Dictionary = {"kit_version": "0.0.0", "schema_version": 0, "created": "fixture", "payload": old_payload, "checksum_sha256": KitCanonical.hash_value(old_payload)}
			var migration_path: String = report_dir.path_join("schema0_fixture.json")
			if KitCanonical.write_text(migration_path, KitCanonical.encode(old)) != OK:
				return false
			_checks.append(assertion("Schema 0 migrates through v0_to_v1.", Kit.save.load_file(migration_path) and Kit.simulation_hash() == before))
			var current_snapshot: Dictionary = Kit.snapshot()
			var archived: Dictionary = KitCanonical.read_json("res://addons/agent_kit/fixtures/schema0_mining.json")
			if not archived.ok:
				return false
			_checks.append(assertion("The committed legacy save fixture loads.", Kit.save.load_file("res://addons/agent_kit/fixtures/schema0_mining.json") and Kit.world.state_hash() == KitCanonical.hash_value(archived.data.payload.records)))
			if not Kit.restore(current_snapshot):
				return false
		"tuning_checks":
			var initial: float = float(Kit.tuning.value("mining.energy_cost"))
			_checks.append(assertion("Trial changes the live tuning value.", Kit.tuning.trial("mining.energy_cost", initial + 0.25) and Kit.tuning.is_trial(&"mining", "energy_cost")))
			Kit.tuning.discard(&"mining")
			_checks.append(assertion("Discard restores the prior value.", close(float(Kit.tuning.value("mining.energy_cost")), initial)))
			_checks.append(assertion("Out-of-range values are refused.", not Kit.tuning.trial("mining.energy_cost", 10000.0)))
			# Apply and variant verification write only a report-local copy.
			var resource: KitTuningSet = Kit.tuning.sets[&"mining"]
			var original_path: String = Kit.tuning.paths[&"mining"]
			Kit.tuning.paths[&"mining"] = report_dir.path_join("mining.tres")
			_checks.append(assertion("Apply saves an editable resource.", Kit.tuning.apply(&"mining") == OK))
			var variant_name: String = "verified"
			var variant_path: String = report_dir.path_join("mining.%s.tres" % variant_name)
			if FileAccess.file_exists(variant_path):
				var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(variant_path))
				if error != OK:
					return false
			_checks.append(assertion("Save as variant writes a separate resource.", Kit.tuning.save_variant(&"mining", variant_name) == OK))
			var loaded: KitTuningSet = ResourceLoader.load(variant_path, "", ResourceLoader.CACHE_MODE_IGNORE)
			_checks.append(assertion("Saved tuning can be loaded.", loaded != null and close(float(loaded.get("energy_cost")), float(resource.get("energy_cost")))))
			Kit.tuning.paths[&"mining"] = original_path
	return true
func expect() -> Array[Dictionary]:
	var results: Array[Dictionary] = _checks.duplicate(true)
	var records: Array[Dictionary] = Kit.log.records()
	var rng_records: Array[Dictionary] = []
	for record: Dictionary in records:
		if record.params.get("probe", "") == "rng":
			rng_records.append(record)
	results.append(assertion("Both queued RNG actions ran.", rng_records.size() == 2))
	if rng_records.size() == 2:
		results.append(assertion("Queue ordering follows tick then sequence.", int(rng_records[0].seq) < int(rng_records[1].seq) and rng_records[0].tick == rng_records[1].tick))
		results.append(assertion("Every native rule RNG draw was audited.", rng_records[0].rng_draws.size() >= 2 and rng_records[1].rng_draws.size() >= 2))
		results.append(assertion("RNG draws use the named rule stream.", rng_records[0].rng_draws[0].stream == "probe"))
	return results
