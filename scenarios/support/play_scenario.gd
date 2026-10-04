extends "res://scenarios/mining_scenario.gd"
var _checks: Array[Dictionary] = []

func _init() -> void:
	requires_play = true

func setup() -> bool:
	_checks.clear()
	return super.setup()

func control(id: StringName, pressed: bool = true, index: int = 0) -> void:
	var event: InputEvent = KitControls.input_event(Kit.controls.slot(id, index), pressed)
	if event == null:
		push_error("The play scenario needs a bound control: " + str(id))
		return
	Input.parse_input_event(event)
	await Kit.get_tree().process_frame

func key(code: Key, pressed: bool = true) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await Kit.get_tree().process_frame

func click_rock(view: Node, id: StringName) -> bool:
	# Clock commands update records before the scene's camera/meshes process that frame.
	await Kit.get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	var camera: Camera3D = view.get("_camera")
	var position: Array = Kit.world.field(id, "position")
	var screen: Vector2 = camera.unproject_position(Vector3(position[0], position[1], position[2]))
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = screen
	Input.parse_input_event(motion)
	var event: InputEvent = KitControls.input_event(Kit.controls.slot(&"select_target"))
	if event == null:
		return false
	if event is InputEventMouseButton:
		event.position = screen
	Input.parse_input_event(event)
	await Kit.get_tree().process_frame
	event = KitControls.input_event(Kit.controls.slot(&"select_target"), false)
	if event is InputEventMouseButton:
		event.position = screen
	Input.parse_input_event(event)
	await Kit.get_tree().process_frame
	return view.get("_target") == id

func shot(name: String) -> bool:
	if not render_mode:
		return true
	await Kit.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path: String = report_dir.path_join("shots/%s.png" % name)
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir())) != OK:
		return false
	return Kit.get_viewport().get_texture().get_image().save_png(path) == OK

func expect() -> Array[Dictionary]:
	return _checks.duplicate(true)
