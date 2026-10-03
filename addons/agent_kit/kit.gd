extends Node
## The one autoload. Game-specific registration belongs to the game.
var world: KitWorld = KitWorld.new()
var actions: KitActionRunner = KitActionRunner.new()
var events: KitEventBus = KitEventBus.new()
var log: KitActionLog = KitActionLog.new()
var rng: KitRng = KitRng.new()
var clock: KitClock = KitClock.new()
var tuning: KitTuningRegistry = KitTuningRegistry.new()
var feel: KitFeelPlayer
var save: KitSaveStore = KitSaveStore.new()
var overlay: KitOverlay
var scenario_mode: bool = false

func _ready() -> void:
	tuning.register(load("res://addons/agent_kit/tuning/system.tres"))
	rng.reset(1)
	clock.advanced.connect(actions.resolve)
	tuning.changed.connect(_tuning_changed)
	feel = KitFeelPlayer.new()
	add_child(feel)
	overlay = KitOverlay.new()
	add_child(overlay)

func _tuning_changed(key: String) -> void:
	if key == "kit.log_capacity":
		log.capacity = int(tuning.value(key))
		events.capacity = log.capacity

func _process(delta: float) -> void:
	if not scenario_mode:
		clock.process(delta)

func reset(seed_value: int = 1, scenarios: bool = false) -> void:
	scenario_mode = scenarios
	world = KitWorld.new()
	actions.definitions.clear()
	actions.pending.clear()
	actions.sequence = 0
	actions.running = false
	log.clear()
	log.unbounded = scenarios
	events.declarations.clear()
	events.history.clear()
	events.unbounded = scenarios
	tuning.sets.clear()
	tuning.paths.clear()
	tuning.register(load("res://addons/agent_kit/tuning/system.tres"))
	log.capacity = int(tuning.value("kit.log_capacity"))
	events.capacity = log.capacity
	rng.reset(seed_value)
	clock.tick = 0
	clock.tick_rate = float(tuning.value("kit.tick_rate"))
	clock.mode = KitClock.Mode.MANUAL_TURN if scenarios else KitClock.Mode.FIXED_TICK
	clock.restore({"tick": 0, "tick_rate": clock.tick_rate, "mode": int(clock.mode)})
	feel.clear()
	feel.sequences.clear()
	feel.views.clear()
	overlay.clear_feel_variants()
	feel.enabled = not scenarios

func snapshot() -> Dictionary:
	return {"world": world.snapshot(), "clock": clock.snapshot(), "rng": rng.snapshot(), "actions": actions.snapshot(), "tuning": tuning.snapshot(), "feel": feel.snapshot(), "log": log.records(), "events": events.history.duplicate(true)}

func _integer(value: Variant, minimum: int = 0) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= minimum

func validate_snapshot(data: Dictionary) -> bool:
	for key: String in ["world", "clock", "rng", "actions", "tuning", "log", "events"]:
		if not data.has(key):
			return false
	if not data.world is Dictionary or not data.clock is Dictionary or not data.rng is Dictionary or not data.actions is Dictionary or not data.tuning is Dictionary or not data.log is Array or not data.events is Array:
		return false
	if not _integer(data.clock.get("tick")) or not _integer(data.clock.get("mode")) or int(data.clock.mode) > 1:
		return false
	var rate: Variant = data.clock.get("tick_rate")
	var accumulator: Variant = data.clock.get("accumulator", 0.0)
	if not (rate is int or rate is float) or not is_finite(float(rate)) or float(rate) <= 0.0 or not (accumulator is int or accumulator is float) or not is_finite(float(accumulator)) or float(accumulator) < 0.0:
		return false
	if not data.rng.get("run_seed") is String or not str(data.rng.run_seed).is_valid_int() or not data.rng.get("streams") is Dictionary:
		return false
	for stream_name: String in data.rng.streams:
		var state: Variant = data.rng.streams[stream_name]
		if not state is Dictionary:
			return false
		for key: String in ["seed", "state"]:
			if not state.get(key) is String or not str(state[key]).is_valid_int():
				return false
	if data.rng.has("cosmetic"):
		if not data.rng.cosmetic is Dictionary:
			return false
		for key: String in ["seed", "state"]:
			if not data.rng.cosmetic.get(key) is String or not str(data.rng.cosmetic[key]).is_valid_int():
				return false
	if not data.actions.get("pending") is Array or not _integer(data.actions.get("sequence")) or not data.actions.get("policies") is Dictionary:
		return false
	for id: String in data.actions.policies:
		var policy: Variant = data.actions.policies[id]
		if not actions.definitions.has(StringName(id)) or not policy is Dictionary or not _integer(policy.get("charge")) or not _integer(policy.get("overflow")) or int(policy.charge) > 1 or int(policy.overflow) > 1:
			return false
	for entry: Variant in data.actions.pending:
		if not entry is Dictionary:
			return false
		for key: String in ["tick", "seq", "action", "actor", "params", "source"]:
			if not entry.has(key):
				return false
		if not _integer(entry.tick) or not _integer(entry.seq, 1) or int(entry.seq) > int(data.actions.sequence) or not entry.action is String or not entry.actor is String or not entry.source is String or not entry.params is Dictionary:
			return false
		if not actions.definitions.has(StringName(entry.action)) or not data.world.has(str(entry.actor)):
			return false
	for set_id: String in data.tuning:
		if not tuning.sets.has(StringName(set_id)) or not data.tuning[set_id] is Dictionary:
			return false
		for knob: String in data.tuning[set_id]:
			var metadata: Dictionary = tuning.sets[StringName(set_id)].metadata(knob)
			var value: Variant = data.tuning[set_id][knob]
			if metadata.is_empty() or not (value is int or value is float) or not is_finite(float(value)):
				return false
			if float(value) < metadata.min or float(value) > metadata.max:
				return false
	for record: Variant in data.log:
		if not record is Dictionary:
			return false
		for key: String in ["tick", "seq", "action", "actor", "params", "checks", "outcome", "deltas", "events", "rng_draws", "input_source"]:
			if not record.has(key):
				return false
		if not _integer(record.tick) or not _integer(record.seq) or not record.params is Dictionary or not record.checks is Array or not record.deltas is Array or not record.events is Array or not record.rng_draws is Array or str(record.outcome) not in ["success", "rejected", "clipped", "attempted_no_yield"]:
			return false
		for check: Variant in record.checks:
			if not check is Dictionary or not check.get("rule_id") is String or not check.get("passed") is bool or not check.get("message") is String:
				return false
		for delta: Variant in record.deltas:
			if not delta is Dictionary:
				return false
			for key: String in ["entity", "field", "reason", "before", "after"]:
				if not delta.has(key):
					return false
	for event: Variant in data.events:
		if not event is Dictionary or not event.get("name") is String or not event.get("payload") is Dictionary or not _integer(event.get("tick")):
			return false
		if not events.declarations.has(str(event.name)):
			return false
		for field: String in events.declarations[str(event.name)].get("fields", []):
			if not event.payload.has(field):
				return false
	var feels: Variant = data.get("feel", {})
	if not feels is Dictionary:
		return false
	for event: String in feels:
		if not feels[event] is String or not str(feels[event]).begins_with("res://") or not str(feels[event]).ends_with(".tres") or not ResourceLoader.exists(str(feels[event])):
			return false
		var sequence: Resource = load(str(feels[event]))
		if not sequence is KitFeelSequence or sequence.trigger_event != StringName(event):
			return false
	var trial_world: KitWorld = KitWorld.new()
	trial_world.types = world.types
	return trial_world.restore(data.world) and trial_world.validate().ok

func restore(data: Dictionary) -> bool:
	if not validate_snapshot(data):
		return false
	if not world.restore(data.world) or not tuning.restore(data.tuning):
		return false
	clock.restore(data.clock)
	rng.restore(data.rng)
	actions.restore(data.actions)
	log.restore(data.log)
	events.history.assign(data.events)
	feel.clear()
	if not feel.restore(data.get("feel", {})):
		return false
	return true

func simulation_hash() -> String:
	var rule_rng: Dictionary = rng.snapshot()
	rule_rng.erase("cosmetic")
	return KitCanonical.hash_value({"world": world.dump(), "clock": clock.snapshot(), "rng": rule_rng, "actions": actions.snapshot()})
