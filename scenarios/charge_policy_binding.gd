extends "res://scenarios/mine_hard_rock.gd"
var _checks: Array[Dictionary] = []
func _init() -> void:
	id = &"charge_policy_binding"
	description = "A bound charge policy follows live tuning through queueing, Discard and legacy save restoration."
func setup() -> bool:
	_checks.clear()
	if not super.setup():
		return false
	# A conflicting fallback must never override the bound knob.
	Kit.actions.definitions[&"mine"].charge_policy = KitActionDef.ChargePolicy.ON_ATTEMPT
	return true
func steps() -> Array[Dictionary]:
	return [
		{"command": "policy_checks"},
		{"command": "queue", "action": "mine", "actor": "ship:player", "params": {"target": "rock:020"}},
		{"command": "tune", "key": "mining.charge_on_attempt", "value": 1},
		{"command": "advance"},
		{"command": "discard_checks"}
	]
func execute_custom(command: Dictionary, _view: Node) -> bool:
	if command.command == "policy_checks":
		var initial: Dictionary = Kit.snapshot()
		initial.actions.policies.mine.charge = 1
		_checks.append(assertion("Legacy duplicated charge cannot override the bound success knob.", Kit.restore(initial) and Kit.actions.definitions[&"mine"].resolved_charge_policy(Kit.tuning) == 0))
		var result: KitActionResult = Kit.actions.run(&"mine", &"ship:player", {"target": "rock:020"})
		_checks.append(assertion("Bound success rejects despite an attempt fallback.", result.outcome == "rejected" and result.record.data.deltas.is_empty()))
		var bad: KitActionDef = KitActionDef.new()
		bad.id = &"bad_policy"
		bad.handler = load("res://scenarios/support/probe_handler.gd")
		bad.charge_policy_key = "mining.missing"
		Kit.actions.register(bad)
		result = Kit.actions.run(&"bad_policy", &"ship:player")
		_checks.append(assertion("A missing policy knob rejects with a named check.", result.outcome == "rejected" and result.record.data.checks[0].rule_id == "action.charge_policy" and not result.record.data.checks[0].passed))
	elif command.command == "discard_checks":
		var records: Array[Dictionary] = Kit.log.records()
		_checks.append(assertion("Queued execution reads the current attempt knob.", records[-1].outcome == "attempted_no_yield"))
		Kit.tuning.discard(&"mining")
		_checks.append(assertion("Discard immediately restores success-only policy.", Kit.actions.definitions[&"mine"].resolved_charge_policy(Kit.tuning) == 0))
		var snapshot: Dictionary = Kit.snapshot()
		_checks.append(assertion("Bound snapshots retain a stable fallback rather than another live policy.", int(snapshot.actions.policies.mine.charge) == 1 and int(snapshot.tuning.mining.charge_on_attempt) == 0))
	return true
func expect() -> Array[Dictionary]:
	var results: Array[Dictionary] = _checks.duplicate(true)
	results.append(assertion("Only the attempted hit paid energy.", close(float(Kit.world.field(&"ship:player", "energy")), float(Kit.tuning.value("ship.energy_max")) - float(Kit.tuning.value("mining.energy_cost")))))
	return results
