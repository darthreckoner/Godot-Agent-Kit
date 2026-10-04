extends "res://scenarios/support/play_scenario.gd"
var _start: Vector3
var _yaw_before: float
func _init() -> void:
	requires_play = true
	id = &"play_flight_and_dock"
	description = "Drive camera orbit and WASD through physical input; Numpad Enter and Enter both trade at the dock."
func setup() -> bool:
	_checks.clear()
	if not start_from_launch():
		return false
	Kit.world.writable = true
	var ok: bool = Kit.world.set_field(&"ship:player", "energy", 20.0) and Kit.world.set_field(&"ship:player", "cargo.iron", 3.0)
	Kit.world.writable = false
	return ok
func steps() -> Array[Dictionary]:
	var orbit: float = deg_to_rad(float(Kit.tuning.value("presentation.camera_start_yaw"))) / float(Kit.tuning.value("presentation.orbit_sensitivity"))
	return [
		{"command": "remember"},
		{"command": "control", "action": "orbit_camera", "position": [800, 350]},
		{"command": "mouse_motion", "relative": [orbit, 0]},
		{"command": "control", "action": "orbit_camera", "position": [800, 350], "pressed": false},
		{"command": "wait_presentation", "seconds": 0.3},
		{"command": "orbit_check"},
		{"command": "control", "action": "fly_forward"},
		{"command": "input_ticks", "ticks": 8},
		{"command": "control", "action": "fly_forward", "pressed": false},
		{"command": "input_ticks", "ticks": 20},
		{"command": "wait_presentation", "seconds": 1.0},
		{"command": "forward_check"},
		{"command": "screenshot", "name": "camera_relative_flight"},
		{"command": "control", "action": "fly_back"},
		{"command": "input_ticks", "ticks": 8},
		{"command": "control", "action": "fly_back", "pressed": false},
		{"command": "input_ticks", "ticks": 20},
		{"command": "strafe_start"},
		{"command": "control", "action": "fly_left"},
		{"command": "input_ticks", "ticks": 33},
		{"command": "control", "action": "fly_left", "pressed": false},
		{"command": "input_ticks", "ticks": 20},
		{"command": "strafe_check"},
		{"command": "control", "action": "sell_and_refuel", "slot": 1},
		{"command": "control", "action": "sell_and_refuel", "slot": 1, "pressed": false},
		{"command": "control", "action": "sell_and_refuel"},
		{"command": "control", "action": "sell_and_refuel", "pressed": false},
		{"command": "dock_check"},
		{"command": "screenshot", "name": "numpad_enter_docks"},
		{"command": "wait_presentation", "seconds": 1.0}
	]
func position() -> Vector3:
	var values: Array = Kit.world.field(&"ship:player", "position")
	return Vector3(values[0], values[1], values[2])
func execute_custom(command: Dictionary, view: Node) -> bool:
	match str(command.command):
		"remember":
			_start = position()
			_yaw_before = view.get("_ship_yaw")
		"orbit_check":
			_checks.append(assertion("Right-drag changes the camera, leaving the nose alone.", absf(float(view.get("_yaw"))) < 0.001 and is_equal_approx(view.get("_ship_yaw"), _yaw_before)))
		"forward_check":
			_checks.append(assertion("W flies away from the camera and eases the nose forward.", position().z < _start.z - 0.1 and absf(position().x - _start.x) < 0.01 and absf(angle_difference(view.get("_ship_yaw"), PI / 2.0)) < 0.05))
			_yaw_before = view.get("_nose_goal")
		"strafe_start":
			_checks.append(assertion("S reverses without turning the nose.", is_equal_approx(view.get("_nose_goal"), _yaw_before)))
			_start = position()
		"strafe_check":
			_checks.append(assertion("A strafes left without turning the nose or automatic rock-facing.", position().x < _start.x - 1.0 and is_equal_approx(view.get("_nose_goal"), _yaw_before)))
		"dock_check":
			var trades: Array[Dictionary] = []
			for record: Dictionary in Kit.log.records():
				if record.action == "sell_and_refuel":
					trades.append(record)
			_checks.append(assertion("Both Enter keys invoke the same successful trade.", trades.size() == 2 and trades[0].outcome == "success" and trades[1].outcome == "success", trades))
			_checks.append(assertion("Docking sells cargo and fully refills energy.", float(Kit.world.field(&"ship:player", "cargo.iron")) == 0.0 and float(Kit.world.field(&"ship:player", "energy")) == float(Kit.world.field(&"ship:player", "energy_max"))))
			_checks.append(assertion("Docking does not draw a mining beam.", float(view.get("_beam_glow")) == 0.0))
	return true
