class_name MiningSetup
extends RefCounted

static func configure(seed_value: int = 20261003, scenario: bool = false, variant: String = "") -> bool:
	Kit.reset(seed_value, scenario)
	for id: String in ["mining", "ship", "economy", "presentation"]:
		var path: String = "res://game/tuning/%s.tres" % id
		var resource: KitTuningSet = load(path)
		if resource == null:
			return false
		Kit.tuning.register(resource, path)
	for id: String in ["ship", "rock", "dock"]:
		Kit.world.register_type(load("res://game/data/%s_type.tres" % id))
	Kit.events.register(load("res://game/data/events.tres"))
	for id: String in ["mine", "sell_and_refuel", "move_ship"]:
		Kit.actions.register(load("res://game/data/%s.tres" % id))
	for id: String in ["mine_hit_heavy", "mine_hit", "rock_break", "mine_rejected", "cargo_clipped", "ship_moved", "dock_success", "dock_rejected"]:
		var sequence: KitFeelSequence = load("res://game/feel/%s.tres" % id)
		if sequence == null:
			return false
		Kit.feel.register(sequence)
	Kit.tuning.changed.connect(_tuning_changed) if not Kit.tuning.changed.is_connected(_tuning_changed) else null
	if not variant.is_empty():
		if not use_variant(variant):
			return false
	_tuning_changed("mining.charge_on_attempt")
	var ship: Dictionary = {
		"position": [0.0, 0.0, 0.0], "velocity": [0.0, 0.0, 0.0],
		"energy": float(Kit.tuning.value("ship.energy_max")), "energy_max": float(Kit.tuning.value("ship.energy_max")),
		"cargo": {"iron": 0.0, "gold": 0.0, "stone": 0.0},
		"cargo_capacity": float(Kit.tuning.value("ship.cargo_capacity")), "credits": float(Kit.tuning.value("ship.starting_credits")), "mine_ready_at": 0.0
	}
	if not Kit.world.put(&"ship:player", &"ship", ship) or not Kit.world.put(&"dock:home", &"dock", {"position": [-5.0, 0.0, 0.0]}):
		return false
	for index: int in range(30):
		var tier: int = index / 10
		var hardness: float = float(Kit.tuning.value("mining.%s_threshold" % ["soft", "medium", "hard"][tier]))
		var ore: String = ["iron", "stone", "gold"][tier]
		var position: Array = [4.5 + float(index % 5) * 1.2, float((index / 5) % 3) * 1.2, float(index / 15) * 1.4]
		if not Kit.world.put(StringName("rock:%03d" % index), &"rock", {"position": position, "hardness": hardness, "health": float(Kit.tuning.value("mining.rock_health")), "ore_type": ore, "ore_amount": float(Kit.tuning.value("mining.%s_yield" % ore))}):
			return false
	return Kit.world.validate().ok

static func finish_setup() -> void:
	Kit.world.writable = false

static func _tuning_changed(key: String) -> void:
	if key == "mining.charge_on_attempt" and Kit.actions.definitions.has(&"mine"):
		Kit.actions.definitions[&"mine"].charge_policy = int(Kit.tuning.value(key))

static func use_variant(path: String) -> bool:
	var resource_path: String = path
	if not path.begins_with("res://"):
		for candidate: String in ["res://game/tuning/%s.tres" % path, "res://game/feel/%s.tres" % path]:
			if ResourceLoader.exists(candidate):
				resource_path = candidate
				break
	if not ResourceLoader.exists(resource_path):
		push_error("Variant was not found: " + path)
		return false
	var resource: Resource = load(resource_path)
	if resource is KitTuningSet:
		Kit.tuning.register(resource, resource_path)
		_tuning_changed("mining.charge_on_attempt")
		return true
	if resource is KitFeelSequence:
		Kit.feel.register(resource)
		return true
	return false
