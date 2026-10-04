extends "res://scenarios/mining_scenario.gd"
func _init() -> void:
	id = &"rng_two_streams"
	description = "Audit two rule RNG streams in alphabetical order, even when drawn in reverse order."
func setup() -> bool:
	if not super.setup():
		return false
	var definition: KitActionDef = KitActionDef.new()
	definition.id = &"probe"
	definition.handler = load("res://scenarios/support/probe_handler.gd")
	Kit.actions.register(definition)
	return true
func steps() -> Array[Dictionary]:
	return [
		{"command": "run", "action": "probe", "actor": "ship:player", "params": {"probe": "two_streams"}},
		{"command": "queue", "action": "probe", "actor": "ship:player", "params": {"probe": "two_streams"}},
		{"command": "advance"}
	]
func expect() -> Array[Dictionary]:
	var checks: Array[Dictionary] = []
	var records: Array[Dictionary] = Kit.log.records()
	checks.append(assertion("Both actions ran.", records.size() == 2))
	for record: Dictionary in records:
		var draws: Array = record.rng_draws
		checks.append(assertion("Draws are alpha then zeta, with both streams audited.", draws.size() == 2 and draws[0].stream == "alpha" and draws[1].stream == "zeta", draws))
		checks.append(assertion("The action committed.", record.outcome == "success"))
	return checks
