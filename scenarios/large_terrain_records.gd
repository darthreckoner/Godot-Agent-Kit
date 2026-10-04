extends "res://scenarios/mining_scenario.gd"
const RECORD_COUNT: int = 2000
const PAYLOAD_SIZE: int = 128
const ACTION_COUNT: int = 20
var _checks: Array[Dictionary] = []
var _measurements: Dictionary = {}
var _untouched_hash: String
func _init() -> void:
	id = &"large_terrain_records"
	description = "Measure action staging with 2,000 large terrain records; only two touched records may be copied."
func setup() -> bool:
	_checks.clear()
	_measurements.clear()
	if not super.setup():
		return false
	var definition: KitActionDef = KitActionDef.new()
	definition.id = &"probe"
	definition.handler = load("res://scenarios/support/probe_handler.gd")
	Kit.actions.register(definition)
	var type: KitRecordType = KitRecordType.new()
	type.id = &"terrain"
	type.fields = {"health": "float", "samples": "array"}
	type.limits = {"health": {"min": 0.0}}
	Kit.world.register_type(type)
	Kit.world.writable = true
	var samples: Array = []
	for index: int in range(PAYLOAD_SIZE):
		samples.append(float(index) / 8.0)
	for index: int in range(RECORD_COUNT):
		if not Kit.world.put(StringName("terrain:%04d" % index), &"terrain", {"health": 100.0, "samples": samples}):
			return false
	Kit.world.writable = false
	_untouched_hash = KitCanonical.hash_value(Kit.world.record(&"terrain:1999"))
	return Kit.world.validate().ok
func steps() -> Array[Dictionary]:
	return [{"command": "measure"}, {"command": "contracts"}, {"command": "advance"}, {"command": "measure"}]
func execute_custom(command: Dictionary, _view: Node) -> bool:
	if command.command == "measure":
		var start: int = Time.get_ticks_usec()
		var max_copies: int = 0
		for index: int in range(ACTION_COUNT):
			var result: KitActionResult = Kit.actions.run(&"probe", &"ship:player", {"probe": "touch"})
			if not result.committed():
				return false
			max_copies = maxi(max_copies, int(Kit.actions.last_transaction_stats.copied_records))
		var elapsed: int = Time.get_ticks_usec() - start
		_measurements["staged_action_us"] = float(elapsed) / ACTION_COUNT
		_measurements["max_copied_records"] = max_copies
		# Measure the five full snapshot/restore passes removed from each action, on this machine.
		start = Time.get_ticks_usec()
		for index: int in range(5):
			var copied: KitWorld = KitWorld.new()
			copied.types = Kit.world.types
			if not copied.restore(Kit.world.snapshot()):
				return false
		_measurements["five_full_copy_us"] = Time.get_ticks_usec() - start
		_measurements["records"] = RECORD_COUNT
		_measurements["numbers_per_record"] = PAYLOAD_SIZE
		_checks.append(assertion("Each action copied exactly the two touched records.", max_copies == 2, max_copies, 2))
	elif command.command == "contracts":
		for probe: String in ["negative", "overflow", "mutate_authority", "invalid_add"]:
			var before: String = Kit.world.state_hash()
			var rng_before: Dictionary = Kit.rng.snapshot()
			var result: KitActionResult = Kit.actions.run(&"probe", &"ship:player", {"probe": probe})
			_checks.append(assertion("%s discards every staged write and RNG draw." % probe, result.outcome == "rejected" and before == Kit.world.state_hash() and rng_before == Kit.rng.snapshot()))
		var cargo: Variant = Kit.world.field(&"ship:player", "cargo")
		var position: Variant = Kit.world.field(&"ship:player", "position")
		var ownership: KitActionResult = Kit.actions.run(&"probe", &"ship:player", {"probe": "read_ownership"})
		_checks.append(assertion("Nested reads cannot mutate live records.", ownership.committed() and cargo == Kit.world.field(&"ship:player", "cargo") and position == Kit.world.field(&"ship:player", "position")))
	return true
func expect() -> Array[Dictionary]:
	var result: Array[Dictionary] = _checks.duplicate(true)
	result.append(assertion("Untouched terrain data is preserved.", _untouched_hash == KitCanonical.hash_value(Kit.world.record(&"terrain:1999"))))
	result.append(assertion("Both batches committed their terrain damage.", close(float(Kit.world.field(&"terrain:0000", "health")), 100.0 - 2 * ACTION_COUNT * 0.25)))
	return result
func numbers() -> Dictionary:
	return _measurements
