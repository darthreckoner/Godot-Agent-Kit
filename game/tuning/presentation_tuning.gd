class_name MiningPresentationTuning
extends KitTuningSet
const KNOBS: Dictionary = {
	"camera_distance": {"help": "Initial orbit-camera distance.", "restart": true},
	"camera_fov": {"help": "Camera field of view."},
	"orbit_sensitivity": {"help": "Orbit angle per pixel of mouse movement."},
	"zoom_step": {"help": "Distance changed by one mouse-wheel step."},
	"camera_min": {"help": "Closest orbit distance."},
	"camera_max": {"help": "Farthest orbit distance."},
	"shake_decay": {"help": "How quickly camera shake fades after an impact."},
	"pulse_decay": {"help": "How quickly the mining tool glow settles."},
	"flight_pulse_decay": {"help": "How quickly the thruster feedback settles after flight input."},
	"toast_duration": {"help": "How long rejection and cargo messages remain visible."},
	"ship_turn_rate": {"help": "Top speed of the ship model's turn when W points it where the camera looks, or when it noses toward the rock it is mining. Looks only; flight rules ignore it."},
	"ship_turn_ease": {"help": "Seconds the ship model takes to speed up into a turn and to settle out of it. Higher feels heavier and smoother."},
	"camera_start_yaw": {"help": "Starting orbit angle around the ship. -90 sits directly behind the ship, looking past its nose at the rocks; 0 looks at its side.", "restart": true}
}
@export_range(8, 35, 0.25, "suffix:m") var camera_distance: float = 17.0
@export_range(35, 90, 1, "suffix:degrees") var camera_fov: float = 55.0
@export_range(0.001, 0.03, 0.001, "suffix:rad/px") var orbit_sensitivity: float = 0.007
@export_range(0.25, 3, 0.25, "suffix:m/step") var zoom_step: float = 1.0
@export_range(4, 15, 0.25, "suffix:m") var camera_min: float = 8.0
@export_range(16, 60, 1, "suffix:m") var camera_max: float = 35.0
@export_range(0.1, 10, 0.1, "suffix:strength/s") var shake_decay: float = 1.8
@export_range(0.1, 10, 0.1, "suffix:strength/s") var pulse_decay: float = 3.0
@export_range(0.1, 10, 0.1, "suffix:strength/s") var flight_pulse_decay: float = 3.0
@export_range(0.5, 10, 0.25, "suffix:s") var toast_duration: float = 3.0
@export_range(30, 1080, 10, "suffix:degrees/s") var ship_turn_rate: float = 240.0
@export_range(0.05, 1.5, 0.05, "suffix:s") var ship_turn_ease: float = 0.3
@export_range(-180, 180, 1, "suffix:degrees") var camera_start_yaw: float = -45.0
