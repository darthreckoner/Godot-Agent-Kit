class_name KitFeelPlayer
extends Node
signal stage_started(stage: KitFeelStage, payload: Dictionary, target: Node)
signal sequence_finished(sequence: KitFeelSequence)
var sequences: Dictionary = {}
var views: Dictionary = {}
var time_scale: float = 1.0
var enabled: bool = true
var last_sequence: KitFeelSequence
var last_stage: KitFeelStage
var last_payload: Dictionary = {}
var _playing: Array[Dictionary] = []
var _flash: ColorRect

func _ready() -> void:
	Kit.events.fired.connect(_on_event)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	layer.add_child(_flash)

func register(sequence: KitFeelSequence) -> void:
	var active: KitFeelSequence = KitFeelSequence.new()
	active.id = sequence.id
	active.description = sequence.description
	active.trigger_event = sequence.trigger_event
	active.set_meta("source_path", sequence.resource_path)
	active.stages.assign(sequence.stages)
	sequences[sequence.trigger_event] = active
	for index: int in range(sequence.stages.size()):
		var stage: KitFeelStage = sequence.stages[index]
		if stage.id.is_empty():
			stage.id = StringName("feel_%s_%d" % [sequence.id, index])
		if not Kit.tuning.sets.has(stage.id):
			Kit.tuning.register(stage, stage.resource_path)
		active.stages[index] = Kit.tuning.sets[stage.id]

func snapshot() -> Dictionary:
	var result: Dictionary = {}
	for event: StringName in sequences:
		result[str(event)] = sequences[event].get_meta("source_path", "")
	return result

func restore(data: Dictionary) -> bool:
	for event: String in data:
		var sequence: KitFeelSequence = load(str(data[event]))
		if sequence == null or sequence.trigger_event != StringName(event):
			return false
		register(sequence)
	return true

func register_view(id: StringName, view: Node) -> void:
	views[id] = weakref(view)

func view_for(id: StringName) -> Node:
	if not views.has(id):
		return null
	return views[id].get_ref()

func _on_event(event: StringName, payload: Dictionary) -> void:
	if enabled and sequences.has(event):
		play(sequences[event], payload)

func play(sequence: KitFeelSequence, payload: Dictionary = {}) -> void:
	if sequence.stages.is_empty():
		return
	last_sequence = sequence
	last_payload = payload.duplicate(true)
	_playing.append({"sequence": sequence, "payload": payload.duplicate(true), "index": 0, "elapsed": 0.0, "hit": false, "audio": null})
	_begin(_playing[-1])

func replay() -> void:
	if last_sequence != null:
		play(last_sequence, last_payload)

func is_playing() -> bool:
	return not _playing.is_empty()

func skip() -> void:
	for playback: Dictionary in _playing:
		_stop_audio(playback)
		playback.index = playback.sequence.stages.size() - 1
		playback.elapsed = 0.0
		playback.hit = false
		_begin(playback)
		_hit(playback)

func clear() -> void:
	for playback: Dictionary in _playing:
		_stop_audio(playback)
	_playing.clear()
	last_stage = null
	if _flash != null:
		_flash.color.a = 0.0

func _begin(playback: Dictionary) -> void:
	var stage: KitFeelStage = playback.sequence.stages[playback.index]
	if stage.sound != null:
		var audio: AudioStreamPlayer = AudioStreamPlayer.new()
		audio.stream = stage.sound
		audio.pitch_scale = maxf(time_scale, 0.01)
		add_child(audio)
		audio.play()
		playback.audio = audio
	if stage.sound_marker_sec <= 0.0:
		_hit(playback)

func _hit(playback: Dictionary) -> void:
	if playback.hit:
		return
	playback.hit = true
	var stage: KitFeelStage = playback.sequence.stages[playback.index]
	var target: Node = view_for(StringName(playback.payload.get(stage.target, "")))
	last_stage = stage
	# Overlapping effects must caption their own sequence, rather than the most recently started one.
	var stage_payload: Dictionary = playback.payload.duplicate(true)
	stage_payload["_sequence_description"] = playback.sequence.description
	stage_started.emit(stage, stage_payload, target)
	var opacity: float = maxf(_flash.color.a, stage.screen_flash)
	_flash.color = stage.flash_color
	_flash.color.a = opacity
	if stage.particle_scene != null and target != null:
		var particles: Node = stage.particle_scene.instantiate()
		if "speed_scale" in particles:
			particles.set("speed_scale", time_scale)
		target.add_child(particles)

func _stop_audio(playback: Dictionary) -> void:
	var audio: AudioStreamPlayer = playback.audio
	if is_instance_valid(audio):
		audio.queue_free()
	playback.audio = null

func _process(delta: float) -> void:
	if _flash != null:
		_flash.color.a = move_toward(_flash.color.a, 0.0, delta * time_scale * float(Kit.tuning.value("kit.flash_decay")))
	var finished: Array[Dictionary] = []
	for playback: Dictionary in _playing:
		if is_instance_valid(playback.audio):
			playback.audio.pitch_scale = maxf(time_scale, 0.01)
		playback.elapsed += delta * time_scale
		var stage: KitFeelStage = playback.sequence.stages[playback.index]
		if playback.elapsed >= stage.sound_marker_sec:
			_hit(playback)
		if playback.elapsed >= maxf(stage.duration, stage.sound_marker_sec):
			_stop_audio(playback)
			playback.index += 1
			if playback.index >= playback.sequence.stages.size():
				sequence_finished.emit(playback.sequence)
				finished.append(playback)
			else:
				playback.elapsed = 0.0
				playback.hit = false
				_begin(playback)
	for playback: Dictionary in finished:
		_playing.erase(playback)
