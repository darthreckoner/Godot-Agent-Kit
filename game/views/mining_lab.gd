extends Node3D
@export var boot_world: bool = true
var _camera: Camera3D
var _ship: Node3D
var _dock: Node3D
var _rock_views: Dictionary = {}
var _ship_mesh: MeshInstance3D
var _tool: MeshInstance3D
var _thruster: MeshInstance3D
var _hud: Label
var _target_label: Label
var _toast: Label
var _caption: Label
var _selection: MeshInstance3D
var _ring_in_reach: StandardMaterial3D
var _ring_out_of_reach: StandardMaterial3D
var _beam: MeshInstance3D
var _beam_target: StringName = &""
var _target: StringName = &"rock:000"
var _yaw: float = 0.0
var _ship_yaw: float = 0.0
var _space_ready: bool = true
var _pitch: float = 0.38
var _distance: float = 17.0
var _orbiting: bool = false
var _shake: float = 0.0
var _shake_frequency: float = 20.0
var _presentation_time: float = 0.0
var _toast_time: float = 0.0
var _pulse: float = 0.0
var _flight_pulse: float = 0.0
var _next_held_request: float = 0.0

func _ready() -> void:
	if boot_world:
		if not MiningSetup.configure():
			push_error("The mining lab could not load its definitions.")
			get_tree().quit(1)
			return
		MiningSetup.finish_setup()
	_build_scene()
	_distance = float(Kit.tuning.value("presentation.camera_distance"))
	_yaw = deg_to_rad(float(Kit.tuning.value("presentation.camera_start_yaw")))
	_build_hud()
	Kit.events.fired.connect(_on_event)
	Kit.feel.stage_started.connect(_on_stage)
	Kit.clock.advanced.connect(_on_tick)
	for path: String in ["res://game/feel/mine_hit.tres", "res://game/feel/mine_hit_heavy.tres"]:
		Kit.overlay.add_feel_variant(load(path))
	_refresh()

func _material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material

func _box(parent: Node3D, size: Vector3, color: Color, position_value: Vector3, glow: float = 0.0) -> MeshInstance3D:
	var view: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color, glow)
	view.mesh = mesh
	view.position = position_value
	parent.add_child(view)
	return view

func _build_scene() -> void:
	var environment: WorldEnvironment = WorldEnvironment.new()
	var settings: Environment = Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.015, 0.025, 0.055)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.42, 0.54, 0.72)
	settings.ambient_light_energy = 0.7
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -30, 0)
	sun.light_color = Color(1, 0.84, 0.61)
	sun.light_energy = 2.0
	add_child(sun)
	var rim: OmniLight3D = OmniLight3D.new()
	rim.position = Vector3(-3, 5, 2)
	rim.light_color = Color(0.2, 0.75, 1)
	rim.omni_range = 40
	rim.light_energy = 3.0
	add_child(rim)
	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 55
	add_child(_camera)
	_ship = Node3D.new()
	add_child(_ship)
	_ship_mesh = _box(_ship, Vector3(1.8, 0.45, 0.85), Color(0.20, 0.65, 0.72), Vector3.ZERO)
	_box(_ship, Vector3(0.7, 0.35, 0.65), Color(0.08, 0.2, 0.32), Vector3(0.15, 0.35, 0), 0.3)
	_box(_ship, Vector3(0.5, 0.18, 1.55), Color(0.65, 0.77, 0.82), Vector3(-0.45, 0, 0))
	_thruster = _box(_ship, Vector3(0.12, 0.3, 0.45), Color(0.2, 0.85, 1), Vector3(-0.96, 0, 0), 2.0)
	_tool = _box(_ship, Vector3(0.65, 0.12, 0.16), Color(1, 0.65, 0.15), Vector3(1.15, 0.05, 0), 1.0)
	Kit.feel.register_view(&"ship:player", _ship)
	for id: StringName in Kit.world.ids():
		if not str(id).begins_with("rock:"):
			continue
		var data: Dictionary = Kit.world.record(id)
		var view: Node3D = Node3D.new()
		var pos: Array = data.position
		view.position = Vector3(pos[0], pos[1], pos[2])
		add_child(view)
		var color: Color = {"iron": Color(0.67, 0.40, 0.24), "stone": Color(0.38, 0.48, 0.58), "gold": Color(0.70, 0.62, 0.25)}[data.ore_type]
		var mesh: MeshInstance3D = _box(view, Vector3(1.03, 1.03, 1.03), color, Vector3.ZERO)
		mesh.rotation = Vector3(0.06 * float(str(id).to_int() % 3), 0.12, 0.04)
		_rock_views[id] = {"node": view, "mesh": mesh}
		Kit.feel.register_view(id, view)
	var dock: Node3D = Node3D.new()
	_dock = dock
	dock.position = Vector3(-5, 0, 0)
	add_child(dock)
	_box(dock, Vector3(2, 0.2, 2), Color(0.15, 0.32, 0.46), Vector3(0, -0.7, 0))
	_box(dock, Vector3(0.13, 2.5, 0.13), Color(0.30, 0.92, 0.69), Vector3(-0.7, 0.2, -0.7), 1.5)
	var sign: Label3D = Label3D.new()
	sign.text = "DOCK\nSell + refuel"
	sign.position = Vector3(0, 1.7, 0)
	sign.font_size = 48
	sign.pixel_size = 0.006
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dock.add_child(sign)
	Kit.feel.register_view(&"dock:home", dock)
	_selection = MeshInstance3D.new()
	var marker: TorusMesh = TorusMesh.new()
	marker.inner_radius = 0.68
	marker.outer_radius = 0.74
	_ring_in_reach = _material(Color(1, 0.78, 0.25), 1.5)
	_ring_out_of_reach = _material(Color(0.85, 0.25, 0.22), 0.8)
	marker.material = _ring_in_reach
	_selection.mesh = marker
	add_child(_selection)
	# The drill beam only shows a committed hit; it never decides reach.
	_beam = _box(self, Vector3(0.07, 0.07, 1.0), Color(1, 0.65, 0.15), Vector3.ZERO, 2.5)
	_beam.visible = false
	# Cosmetic stars never touch records or the rule RNG streams.
	for index: int in range(100):
		var star: Vector3 = Vector3(Kit.rng.cosmetic.randf_range(-60, 60), Kit.rng.cosmetic.randf_range(-25, 30), Kit.rng.cosmetic.randf_range(-50, -14))
		_box(self, Vector3.ONE * 0.07, Color(0.53, 0.7, 0.9), star, 1.0)

func _build_hud() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(24, 18)
	panel.size = Vector2(1232, 62)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var title: Label = Label.new()
	title.text = "  MINING LAB     "
	title.add_theme_color_override("font_color", Color(0.39, 0.89, 0.90))
	title.add_theme_font_size_override("font_size", 24)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title)
	_hud = Label.new()
	_hud.add_theme_font_size_override("font_size", 20)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_hud)
	_target_label = Label.new()
	_target_label.position = Vector2(28, 94)
	_target_label.add_theme_font_size_override("font_size", 18)
	root.add_child(_target_label)
	_caption = Label.new()
	_caption.position = Vector2(28, 145)
	_caption.add_theme_color_override("font_color", Color(0.54, 0.80, 0.85))
	_caption.add_theme_font_size_override("font_size", 18)
	root.add_child(_caption)
	_toast = Label.new()
	_toast.position = Vector2(360, 560)
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.add_theme_color_override("font_color", Color(1, 0.77, 0.34))
	root.add_child(_toast)
	var hints: Label = Label.new()
	hints.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hints.offset_left = 28
	hints.offset_top = -84
	hints.offset_bottom = -18
	hints.text = "WASD: fly (W = away from camera)   Q/E: down/up   Right-drag: orbit   Wheel: zoom\nClick rock: select + mine   Space: mine selected   Enter: sell + refuel   F1: Why   F2: tuning   B: impact A/B   V: charge policy\nF3: skip feel   F5/F9: save/load   R: restart trials   Esc: exit"
	hints.add_theme_font_size_override("font_size", 16)
	root.add_child(hints)

func _on_tick(_tick: int) -> void:
	if Kit.scenario_mode or Kit.overlay.is_open():
		return
	# Flight keys follow the camera: W flies away from it, D to its right. The action records the world direction.
	var forward: Vector3 = Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var right: Vector3 = Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var direction: Vector3 = right * (float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))) \
		+ Vector3.UP * (float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q))) \
		+ forward * (float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S)))
	var velocity: Array = Kit.world.field(&"ship:player", "velocity")
	if direction.length_squared() > 0.0 or Vector3(velocity[0], velocity[1], velocity[2]).length_squared() > 0.00001:
		Kit.actions.run(&"move_ship", &"ship:player", {"direction": [direction.x, direction.y, direction.z]})
	# After a rock breaks, Space must be released before the next rock is mined.
	if Input.is_physical_key_pressed(KEY_SPACE):
		if _space_ready and Kit.clock.seconds() >= _next_held_request:
			_next_held_request = Kit.clock.seconds() + float(Kit.tuning.value("mining.cooldown"))
			_mine_target()
	else:
		_space_ready = true

func _unhandled_input(event: InputEvent) -> void:
	if Kit.scenario_mode or Kit.overlay.is_open():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(float(Kit.tuning.value("presentation.camera_min")), _distance - float(Kit.tuning.value("presentation.zoom_step")))
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(float(Kit.tuning.value("presentation.camera_max")), _distance + float(Kit.tuning.value("presentation.zoom_step")))
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _select_at(event.position):
			_mine_target()
	if event is InputEventMouseMotion and _orbiting:
		_yaw -= event.relative.x * float(Kit.tuning.value("presentation.orbit_sensitivity"))
		_pitch = clampf(_pitch + event.relative.y * float(Kit.tuning.value("presentation.orbit_sensitivity")), -0.4, 1.2)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: Kit.actions.run(&"sell_and_refuel", &"ship:player", {"dock": "dock:home"})
			KEY_F3: Kit.feel.skip()
			KEY_F5: _show_toast("Save written." if Kit.save.write("user://mining.json") else Kit.save.last_message)
			KEY_F9: _show_toast("Save loaded." if Kit.save.load_file("user://mining.json") else Kit.save.last_message)
			KEY_V:
				Kit.tuning.trial("mining.charge_on_attempt", 1 - int(Kit.tuning.value("mining.charge_on_attempt")))
				_show_toast("Charge policy is a live trial. Apply or Discard in F2.")
			KEY_B:
				var heavy: bool = Kit.feel.sequences[&"mine_hit"].id != &"mine_hit_heavy"
				MiningSetup.use_variant("mine_hit_heavy" if heavy else "mine_hit")
				_show_toast("Heavy impact." if heavy else "Light impact.")
			KEY_R:
				get_tree().reload_current_scene()
			KEY_ESCAPE: get_tree().quit()

func _select_at(screen: Vector2) -> bool:
	var origin: Vector3 = _camera.project_ray_origin(screen)
	var ray: Vector3 = _camera.project_ray_normal(screen)
	var nearest: float = INF
	for id: StringName in _rock_views:
		if not _alive(id):
			continue
		var center: Vector3 = _rock_views[id].node.global_position
		var t: float = (center - origin).dot(ray)
		if t > 0.0 and (origin + ray * t).distance_to(center) < 0.85 and t < nearest:
			nearest = t
			_target = id
	return nearest < INF

func _mine_target() -> void:
	if not _alive(_target):
		_show_toast("No rock selected. Click a rock to target it.")
		return
	Kit.actions.run(&"mine", &"ship:player", {"target": str(_target)})

func _alive(id: StringName) -> bool:
	var rock: Dictionary = Kit.world.record(id) if id != &"" else {}
	return not rock.is_empty() and float(rock.get("health", 0.0)) > 0.0

func _ship_position() -> Vector3:
	var position_value: Array = Kit.world.field(&"ship:player", "position")
	return Vector3(position_value[0], position_value[1], position_value[2])

func _rock_position(id: StringName) -> Vector3:
	var position_value: Array = Kit.world.field(id, "position")
	return Vector3(position_value[0], position_value[1], position_value[2])

# Same centre-to-centre distance the mining.in_range rule measures.
func _target_distance() -> float:
	return _ship_position().distance_to(_rock_position(_target))

# A broken target hands over to the nearest live rock, or to no target when none are left.
func _retarget() -> void:
	var nearest: float = INF
	_target = &""
	for id: StringName in _rock_views:
		if _alive(id) and _ship_position().distance_to(_rock_position(id)) < nearest:
			nearest = _ship_position().distance_to(_rock_position(id))
			_target = id

func _on_event(name: StringName, payload: Dictionary) -> void:
	if name == &"mine_hit":
		_pulse = 1.0
		_beam_target = StringName(payload.get("entity", ""))
		if payload.get("broke", false):
			_space_ready = false
		if payload.get("no_yield", false):
			_show_toast("Too hard: energy paid for an attempt, with no yield.")
	if name == &"mine_rejected" or name == &"dock_rejected":
		_show_toast(str(payload.get("message", "Action rejected.")))
	if name == &"cargo_clipped":
		_show_toast("Cargo full. Excess ore was left behind.")
	if name == &"dock_success":
		_show_toast("Cargo sold. Energy refilled.")
	_refresh()

func _on_stage(stage: KitFeelStage, payload: Dictionary, _view: Node) -> void:
	_shake = maxf(_shake, stage.shake_amplitude)
	_shake_frequency = stage.shake_frequency
	if payload.get("action", "") == "move_ship":
		_flight_pulse = 1.0
	if payload.get("action", "") != "move_ship":
		_caption.text = "%s · %s" % [Kit.feel.last_sequence.description if Kit.feel.last_sequence != null else "Feel", stage.stage_name]
		_pulse = maxf(_pulse, stage.screen_flash)

func _show_toast(message: String) -> void:
	_toast.text = message
	_toast_time = float(Kit.tuning.value("presentation.toast_duration"))

func caption(text: String) -> void:
	_caption.text = text

func _refresh() -> void:
	if _hud == null:
		return
	var ship: Dictionary = Kit.world.record(&"ship:player")
	var total: float = 0.0
	for amount: Variant in ship.cargo.values():
		total += float(amount)
	_hud.text = "Energy %.1f / %.0f    Cargo %.1f / %.0f    Credits %.1f" % [ship.energy, ship.energy_max, total, ship.cargo_capacity, ship.credits]
	var position_value: Array = ship.position
	_ship.position = Vector3(position_value[0], position_value[1], position_value[2])
	for id: StringName in _rock_views:
		var data: Dictionary = Kit.world.record(id)
		_rock_views[id].mesh.visible = not data.is_empty() and float(data.get("health", 0.0)) > 0.0
		if not data.is_empty():
			var pos: Array = data.position
			_rock_views[id].node.position = Vector3(pos[0], pos[1], pos[2])
	var dock_data: Dictionary = Kit.world.record(&"dock:home")
	_dock.visible = not dock_data.is_empty()
	if not dock_data.is_empty():
		var dock_position: Array = dock_data.position
		_dock.position = Vector3(dock_position[0], dock_position[1], dock_position[2])
	if not _alive(_target):
		_retarget()
	var policy: String = "Policy: %s · Impact: %s" % ["charge on attempt" if int(Kit.tuning.value("mining.charge_on_attempt")) else "charge on success", Kit.feel.sequences[&"mine_hit"].description]
	_selection.visible = _alive(_target)
	if not _alive(_target):
		_target_label.text = "No rock selected · click a rock to target it\n" + policy
	else:
		var rock: Dictionary = Kit.world.record(_target)
		var distance: float = _target_distance()
		var reach: float = float(Kit.tuning.value("mining.range"))
		var in_reach: bool = distance <= reach
		_selection.position = _rock_views[_target].node.position + Vector3(0, -0.5, 0)
		(_selection.mesh as TorusMesh).material = _ring_in_reach if in_reach else _ring_out_of_reach
		var reach_text: String = "in drill reach" if in_reach else "fly %.1f m closer" % maxf(0.1, ceilf((distance - reach) * 10.0) / 10.0)
		_target_label.text = "Target %s · %s · hardness %.1f · health %.1f · %s\n%s" % [_target, rock.ore_type, rock.hardness, rock.health, reach_text, policy]

func _process(delta: float) -> void:
	if _camera == null:
		return
	var feel_delta: float = delta * Kit.feel.time_scale
	_presentation_time += feel_delta
	_shake = move_toward(_shake, 0.0, feel_delta * float(Kit.tuning.value("presentation.shake_decay")))
	_pulse = move_toward(_pulse, 0.0, feel_delta * float(Kit.tuning.value("presentation.pulse_decay")))
	_flight_pulse = move_toward(_flight_pulse, 0.0, feel_delta * float(Kit.tuning.value("presentation.flight_pulse_decay")))
	_thruster.scale = Vector3(1.0, 1.0 + _flight_pulse, 1.0 + _flight_pulse)
	_camera.fov = float(Kit.tuning.value("presentation.camera_fov"))
	_tool.scale = Vector3(1 + _pulse * 0.4, 1 + _pulse, 1 + _pulse)
	var center: Vector3 = _ship.position + Vector3(2.0, 0.5, 0)
	_camera.position = center + Vector3(sin(_yaw) * _distance * cos(_pitch), sin(_pitch) * _distance, cos(_yaw) * _distance)
	_camera.position += Vector3(sin(_presentation_time * _shake_frequency * TAU), cos(_presentation_time * _shake_frequency * TAU * 0.7), 0) * _shake
	_camera.look_at(center)
	_toast_time = maxf(0.0, _toast_time - delta)
	_toast.visible = _toast_time > 0.0
	_refresh()
	_face(delta)
	_update_beam()

# The ship model turns to face where it flies, or the selected rock once it is within reach. Looks only.
func _face(delta: float) -> void:
	var velocity: Array = Kit.world.field(&"ship:player", "velocity")
	var aim: Vector3 = Vector3(velocity[0], 0.0, velocity[2])
	if aim.length() < 0.3:
		aim = Vector3.ZERO
		if _alive(_target) and _target_distance() <= float(Kit.tuning.value("mining.range")):
			aim = _rock_position(_target) - _ship_position()
			aim.y = 0.0
	if aim.length_squared() > 0.0001:
		_ship_yaw = rotate_toward(_ship_yaw, atan2(-aim.z, aim.x), deg_to_rad(float(Kit.tuning.value("presentation.ship_turn_rate"))) * delta)
	_ship.rotation.y = _ship_yaw

# A short beam from the drill tip to the struck rock's face while the hit glow lasts.
func _update_beam() -> void:
	_beam.visible = false
	if _pulse < 0.05 or not _rock_views.has(_beam_target):
		return
	var nose: Vector3 = _ship.global_basis.x.normalized()
	var start: Vector3 = _tool.global_position + nose * 0.33
	var center: Vector3 = _rock_views[_beam_target].node.global_position
	var finish: Vector3 = center - (center - start).normalized() * 0.5
	var length: float = start.distance_to(finish)
	if length < 0.05:
		return
	var direction: Vector3 = (finish - start) / length
	_beam.global_position = (start + finish) * 0.5
	_beam.look_at(finish, Vector3.FORWARD if absf(direction.dot(Vector3.UP)) > 0.99 else Vector3.UP)
	_beam.scale = Vector3(1.0 + _pulse, 1.0 + _pulse, length)
	_beam.visible = true
