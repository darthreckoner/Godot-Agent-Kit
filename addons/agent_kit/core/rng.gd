class_name KitRng
extends RefCounted
var run_seed: int = 1
var cosmetic: RandomNumberGenerator = RandomNumberGenerator.new()
var _streams: Dictionary = {}
var _audit_start: Dictionary = {}
var auditing: bool = false

func reset(seed_value: int) -> void:
	run_seed = seed_value
	_streams.clear()
	_audit_start.clear()
	cosmetic.seed = _derived_seed("cosmetic")
	auditing = false

func _derived_seed(name: String) -> int:
	return ("seed:%d/%s" % [run_seed, name]).sha256_text().substr(0, 15).hex_to_int()

func stream(name: StringName) -> RandomNumberGenerator:
	if not _streams.has(name):
		var generator: RandomNumberGenerator = RandomNumberGenerator.new()
		generator.seed = _derived_seed(str(name))
		_streams[name] = generator
		if auditing:
			_audit_start[name] = generator.state
	return _streams[name]

func begin_action() -> void:
	auditing = true
	_audit_start.clear()
	for name: StringName in _streams:
		_audit_start[name] = _streams[name].state

func end_action() -> Array[Dictionary]:
	var draws: Array[Dictionary] = []
	var names: Array = _streams.keys()
	names.sort()
	for name: StringName in names:
		var generator: RandomNumberGenerator = _streams[name]
		var replay: RandomNumberGenerator = RandomNumberGenerator.new()
		replay.seed = _derived_seed(str(name))
		replay.state = int(_audit_start[name])
		while replay.state != generator.state:
			var before: int = replay.state
			var value: int = replay.randi()
			draws.append({"stream": str(name), "raw_draw": value, "before": str(before), "after": str(replay.state)})
			if draws.size() > 100000:
				push_error("RNG audit exceeded 100000 draws. Do not reseed streams inside actions.")
				break
	auditing = false
	return draws

func snapshot() -> Dictionary:
	var streams: Dictionary = {}
	for name: StringName in _streams:
		streams[str(name)] = {"seed": str(_streams[name].seed), "state": str(_streams[name].state)}
	return {"run_seed": str(run_seed), "streams": streams, "cosmetic": {"seed": str(cosmetic.seed), "state": str(cosmetic.state)}}

func restore(data: Dictionary) -> void:
	reset(int(data.run_seed))
	if data.has("cosmetic"):
		cosmetic.seed = int(data.cosmetic.seed)
		cosmetic.state = int(data.cosmetic.state)
	for name: String in data.streams:
		var generator: RandomNumberGenerator = stream(StringName(name))
		generator.seed = int(data.streams[name].seed)
		generator.state = int(data.streams[name].state)
