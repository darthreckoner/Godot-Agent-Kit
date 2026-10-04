extends "res://scenarios/support/play_scenario.gd"
var _goal: float
var _look_hash: String
func _init() -> void:
	requires_play = true
	id = &"play_targeting"
	description = "Physical clicks select and face once; Space alone drills, clears broken targets and explains hard gold."
func setup() -> bool:
	if not super.setup():
		return false
	Kit.world.writable = true
	# An exposed gold block avoids aiming through an occluding stone after the orbit check.
	var ok: bool = Kit.world.set_field(&"rock:020", "position", [1.0, 0.0, 0.0])
	Kit.world.writable = false
	return ok
func steps() -> Array[Dictionary]:
	var settle: float = 0.0
	for sequence: KitFeelSequence in Kit.feel.sequences.values():
		var duration: float = 0.0
		for stage: KitFeelStage in sequence.stages:
			duration += maxf(stage.duration, stage.sound_marker_sec)
		settle = maxf(settle, duration / Kit.feel.time_scale)
	return [
		{"command": "initial"},
		{"command": "control", "action": "fly_forward"},
		{"command": "wait_presentation", "seconds": 0.4},
		{"command": "control", "action": "fly_forward", "pressed": false},
		{"command": "wait_presentation", "seconds": 0.9},
		{"command": "click"},
		{"command": "screenshot", "name": "click_selects_only"},
		{"command": "wait_presentation", "seconds": 1.0},
		{"command": "faced"},
		{"command": "control", "action": "orbit_camera", "position": [800, 350]},
		{"command": "mouse_motion", "relative": [-150, 0]},
		{"command": "control", "action": "orbit_camera", "position": [800, 350], "pressed": false},
		{"command": "wait_presentation", "seconds": 0.5},
		{"command": "orbit_check"},
		{"command": "control", "action": "drill"},
		{"command": "input_ticks", "ticks": 9},
		{"command": "one_hit"},
		{"command": "finish_current"},
		{"command": "input_ticks", "ticks": 12},
		{"command": "broken"},
		{"command": "screenshot", "name": "broken_target_cleared"},
		{"command": "control", "action": "drill", "pressed": false},
		{"command": "gold"},
		{"command": "control", "action": "drill"},
		{"command": "input_ticks", "ticks": 12},
		{"command": "control", "action": "drill", "pressed": false},
		{"command": "gold_refused"},
		{"command": "screenshot", "name": "gold_power_explained"},
		{"command": "look_before"},
		{"command": "control", "action": "hit_look"},
		{"command": "control", "action": "hit_look", "pressed": false},
		{"command": "look_after"},
		{"command": "screenshot", "name": "heavy_same_damage"},
		{"command": "wait_presentation", "seconds": settle + 0.1},
		{"command": "control", "action": "kit_finish_effect"},
		{"command": "control", "action": "kit_finish_effect", "pressed": false},
		{"command": "idle_f3"}
	]
func execute_custom(command: Dictionary, view: Node) -> bool:
	match str(command.command):
		"initial":
			_checks.append(assertion("The lab starts with no automatically selected target.", view.get("_target") == &""))
		"click":
			var before: String = Kit.world.state_hash()
			var yaw: float = view.get("_ship_yaw")
			var selected: bool = await click_rock(view, &"rock:000")
			_goal = view.get("_nose_goal")
			_checks.append(assertion("Clicking selects without a mine, cost or world change.", selected and Kit.log.records().is_empty() and before == Kit.world.state_hash()))
			_checks.append(assertion("Clicking begins a smooth turn instead of snapping.", absf(angle_difference(yaw, _goal)) > 0.2 and absf(angle_difference(view.get("_ship_yaw"), _goal)) > 0.1))
		"faced":
			_checks.append(assertion("The clicked turn settles facing the rock.", absf(angle_difference(view.get("_ship_yaw"), _goal)) < 0.04))
		"orbit_check":
			_checks.append(assertion("Camera orbit alone does not change the captured nose goal.", is_equal_approx(view.get("_nose_goal"), _goal)))
		"one_hit":
			_checks.append(assertion("Space produces one in-reach hit with immediate feel.", Kit.log.records().size() == 1 and float(Kit.world.field(&"rock:000", "health")) == 2.0 and Kit.feel.last_sequence != null))
		"finish_current":
			var before: String = Kit.simulation_hash()
			var playing: bool = Kit.feel.is_playing()
			await control(&"kit_finish_effect")
			await control(&"kit_finish_effect", false)
			_checks.append(assertion("Active F3 finishes presentation without changing rules or timing.", playing and before == Kit.simulation_hash() and str(view.get("_toast").text).begins_with("Finished the current effect")))
		"broken":
			_checks.append(assertion("The broken target clears; held Space never mines another rock.", view.get("_target") == &"" and Kit.log.records().size() == 2 and float(Kit.world.field(&"rock:000", "health")) == 0.0))
			_checks.append(assertion("No-target Space names the current select control.", str(view.get("_toast").text).contains("No rock selected. %s: select a rock to target it." % Kit.controls.text(&"select_target"))))
		"gold":
			_checks.append(assertion("A gold click only selects and explains how to raise drill power.", await click_rock(view, &"rock:020") and str(view.get("_target_label").text).contains("raise Mining / tool power in F2") and Kit.log.records().size() == 2))
		"gold_refused":
			var records: Array[Dictionary] = Kit.log.records()
			_checks.append(assertion("Gold rejects through the actual Space callback without a cost.", records.size() > 2 and records[-1].outcome == "rejected" and records[-1].deltas.is_empty() and str(view.get("_toast").text).contains("tool_power")))
		"look_before":
			_look_hash = Kit.simulation_hash()
		"look_after":
			_checks.append(assertion("B says same damage, bigger shake and flash; rule state/timing are unchanged.", _look_hash == Kit.simulation_hash() and str(view.get("_toast").text).contains("same damage, bigger shake and flash") and str(view.get("_target_label").text).contains("Hit look: heavy")))
		"idle_f3":
			_checks.append(assertion("Idle F3 explains that it finishes a current effect.", str(view.get("_toast").text).begins_with("No effect playing."), str(view.get("_toast").text)))
	return true
