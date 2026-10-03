class_name KitActionRunner
extends RefCounted
var definitions: Dictionary = {}
var pending: Array[Dictionary] = []
var sequence: int = 0
var input_source: String = "input"
var running: bool = false

func register(definition: KitActionDef) -> void:
	definitions[definition.id] = definition.duplicate(true)

func queue(action: StringName, actor: StringName, params: Dictionary = {}, source: String = "input") -> void:
	sequence += 1
	pending.append({"tick": Kit.clock.tick + 1, "seq": sequence, "action": str(action), "actor": str(actor), "params": params.duplicate(true), "source": source})

func resolve(tick: int) -> void:
	var due: Array[Dictionary] = []
	var future: Array[Dictionary] = []
	for item: Dictionary in pending:
		if int(item.tick) <= tick:
			due.append(item)
		else:
			future.append(item)
	pending = future
	due.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.tick) < int(b.tick) or (int(a.tick) == int(b.tick) and int(a.seq) < int(b.seq)))
	for item: Dictionary in due:
		_execute(StringName(item.action), StringName(item.actor), item.params, str(item.source), int(item.seq))

func run(action: StringName, actor: StringName, params: Dictionary = {}, source: String = "") -> KitActionResult:
	sequence += 1
	return _execute(action, actor, params, input_source if source.is_empty() else source, sequence)

func _execute(action: StringName, actor: StringName, params: Dictionary, source: String, seq: int) -> KitActionResult:
	var result: KitActionResult = KitActionResult.new()
	var record: KitActionRecord = KitActionRecord.new()
	record.data = {"tick": Kit.clock.tick, "seq": seq, "action": str(action), "actor": str(actor), "params": params.duplicate(true), "checks": [], "outcome": "rejected", "deltas": [], "events": [], "rng_draws": [], "input_source": source}
	result.record = record
	if running or not definitions.has(action) or Kit.world.record(actor).is_empty():
		record.data.checks.append(KitCheckResult.make(&"action.registered_actor", false, "The action and actor must exist; nested actions must be queued.").to_dict())
		Kit.log.append(record)
		return result
	running = true
	var definition: KitActionDef = definitions[action]
	var before: Dictionary = Kit.world.snapshot()
	var rng_before: Dictionary = Kit.rng.snapshot()
	var read_world: KitWorld = KitWorld.new()
	read_world.types = Kit.world.types
	read_world.restore(before)
	read_world.writable = false
	var ctx: Dictionary = {"world": read_world, "actor": actor, "params": params.duplicate(true), "tuning": Kit.tuning, "clock": Kit.clock, "rng": Kit.rng, "definition": definition}
	var checks: Array[KitCheckResult] = []
	Kit.rng.begin_action()
	for condition: KitCondition in definition.requires:
		checks.append(condition.check(ctx))
	var handler: KitActionHandler = definition.handler.new()
	checks.append_array(handler.check(ctx))
	var passed: bool = true
	for check: KitCheckResult in checks:
		record.data.checks.append(check.to_dict())
		if not check.passed:
			passed = false
			result.message += check.message + " "
	var changes: KitChangeSet = KitChangeSet.new()
	if passed:
		changes = handler.plan(ctx)
		if not changes.has_yield and definition.charge_policy == KitActionDef.ChargePolicy.ON_SUCCESS:
			passed = false
			result.message = changes.no_yield_message
			record.data.checks.append(KitCheckResult.make(changes.no_yield_rule, false, result.message).to_dict())
	# Plans cannot secretly mutate the authoritative state.
	if before != Kit.world.snapshot():
		Kit.world.restore(before)
		passed = false
		result.message = "The handler tried to write world state while planning."
		record.data.checks.append(KitCheckResult.make(&"transaction.read_only_plan", false, result.message).to_dict())
	record.data.rng_draws = Kit.rng.end_action()
	var stage: KitWorld = KitWorld.new()
	stage.types = Kit.world.types
	stage.restore(before)
	var deltas: Array[Dictionary] = []
	var clipped: bool = false
	if passed:
		for change: KitChange in changes.changes:
			if not changes.has_yield and not change.cost_only:
				continue
			if change.reason.is_empty():
				passed = false
				result.message = "Every planned change needs a plain-English reason naming its rule or tuning knob."
				break
			var old: Variant = stage.field(change.entity, change.field) if not change.field.is_empty() else stage.record(change.entity)
			if not change.apply(stage):
				passed = false
				result.message = "A planned change could not be applied: " + change.describe()
				break
			# Clip only new positive cargo, preserving cargo already owned.
			if change is KitResourceDelta and change.amount > 0.0 and definition.overflow_policy == KitActionDef.OverflowPolicy.CLIP:
				var data: Dictionary = stage.record(change.entity)
				var type_def: KitRecordType = stage.types[StringName(data.type)]
				var root: String = change.field.get_slice(".", 0)
				var limit: Dictionary = type_def.limits.get(root, {})
				if limit.has("max_field"):
					var total: float = 0.0
					if data[root] is Dictionary:
						for quantity: Variant in data[root].values():
							total += float(quantity)
					else:
						total = float(data[root])
					var excess: float = maxf(0.0, total - float(data[limit.max_field]))
					if excess > 0.0:
						stage.set_field(change.entity, change.field, float(stage.field(change.entity, change.field)) - minf(excess, change.amount))
						clipped = true
			var delta: Dictionary = change.to_dict()
			delta.merge({"entity": str(change.entity), "field": change.field, "reason": change.reason, "description": change.describe()}, true)
			delta["before"] = old
			delta["after"] = stage.field(change.entity, change.field) if not change.field.is_empty() else stage.record(change.entity)
			if old is float or old is int:
				delta["delta"] = float(delta.after) - float(old) if delta.after != null else -float(old)
			deltas.append(delta)
		var validation: Dictionary = stage.validate(false)
		if not validation.ok:
			passed = false
			result.message = validation.message
		if not passed:
			record.data.checks.append(KitCheckResult.make(&"transaction.valid_changes", false, result.message).to_dict())
	var payload: Dictionary = {"entity": str(params.get("target", actor)), "actor": str(actor), "action": str(action)}
	payload.merge(changes.payload, true)
	payload["clipped"] = clipped
	var events: Array[StringName] = definition.events_on_success.duplicate() if passed else definition.events_on_reject.duplicate()
	if passed:
		events.append_array(changes.extra_events)
		for event: StringName in definition.events_on_clip:
			if clipped:
				events.append(event)
	payload["message"] = result.message
	for event: StringName in events:
		if not Kit.events.valid(event, payload):
			passed = false
			result.message = "The action declares an invalid event."
			events.clear()
			record.data.checks.append(KitCheckResult.make(&"events.declared", false, result.message).to_dict())
			break
	if passed:
		if not Kit.world.restore(stage.snapshot()):
			passed = false
			result.message = "The transaction could not commit."
		else:
			result.outcome = "attempted_no_yield" if not changes.has_yield else ("clipped" if clipped else "success")
			record.data.deltas = deltas
	if not passed:
		Kit.rng.restore(rng_before)
	record.data.outcome = result.outcome
	record.data.events = events.map(func(name: StringName) -> String: return str(name))
	Kit.log.append(record)
	running = false
	for event: StringName in events:
		Kit.events.emit_event(event, payload, Kit.clock.tick)
	return result

func snapshot() -> Dictionary:
	var policies: Dictionary = {}
	for id: StringName in definitions:
		policies[str(id)] = {"charge": int(definitions[id].charge_policy), "overflow": int(definitions[id].overflow_policy)}
	return {"pending": pending.duplicate(true), "sequence": sequence, "policies": policies}

func restore(data: Dictionary) -> void:
	pending.assign(data.pending)
	sequence = int(data.sequence)
	for id: String in data.get("policies", {}):
		if definitions.has(StringName(id)):
			definitions[StringName(id)].charge_policy = int(data.policies[id].charge)
			definitions[StringName(id)].overflow_policy = int(data.policies[id].overflow)
