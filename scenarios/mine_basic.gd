extends "res://scenarios/mining_scenario.gd"
func _init() -> void:
	id = &"mine_basic"
	description = "Mine a soft rock and verify energy and ore accounting."
func steps() -> Array[Dictionary]:
	return mine_steps()
func expect() -> Array[Dictionary]:
	return basic_expect()
