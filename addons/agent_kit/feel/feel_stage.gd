class_name KitFeelStage
extends KitTuningSet
const KNOBS: Dictionary = {
	"duration": {"help": "Presentation time for this stage; never changes rule time."},
	"sound_marker_sec": {"help": "Time in the sound where the stage makes contact."},
	"shake_amplitude": {"help": "Strength sent to the game's presentation camera."},
	"shake_frequency": {"help": "Shake oscillations per second."},
	"screen_flash": {"help": "Brightness of the brief screen flash."}
}
@export var stage_name: String = "Contact"
@export_range(0.0, 5.0, 0.01, "suffix:s") var duration: float = 0.1
@export var sound: AudioStream
@export var flash_color: Color = Color.WHITE
@export_range(0.0, 5.0, 0.01, "suffix:s") var sound_marker_sec: float = 0.0
@export_range(0.0, 2.0, 0.01, "suffix:strength") var shake_amplitude: float = 0.0
@export_range(0.0, 80.0, 0.1, "suffix:Hz") var shake_frequency: float = 20.0
@export_range(0.0, 1.0, 0.01, "suffix:opacity") var screen_flash: float = 0.0
@export var particle_scene: PackedScene
@export_enum("entity", "actor") var target: String = "entity"
