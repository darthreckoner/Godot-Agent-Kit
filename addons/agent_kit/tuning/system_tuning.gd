class_name KitSystemTuning
extends KitTuningSet
const KNOBS: Dictionary = {
	"tick_rate": {"help": "Simulation ticks each second.", "restart": true},
	"log_capacity": {"help": "Recent operations and events kept during play."},
	"flash_decay": {"help": "How quickly the screen flash fades; no rule effects."},
	"tuning_panel_width": {"help": "Width of the tuning panel when it is docked to the side, as a share of the window width. It never gets narrower than its contents need."},
	"tuning_panel_faded_opacity": {"help": "How visible the side panel stays after you click back into the game. Clicking the panel restores it."},
	"tuning_panel_fade_time": {"help": "How long the side panel takes to fade back or return. 0 switches instantly."}
}
@export_range(1, 120, 1, "suffix:Hz") var tick_rate: float = 30.0
@export_range(32, 8192, 1, "suffix:records") var log_capacity: int = 512
@export_range(0.1, 20, 0.1, "suffix:opacity/s") var flash_decay: float = 2.5
@export_range(0.25, 0.7, 0.01, "suffix:of window width") var tuning_panel_width: float = 0.4
@export_range(0.1, 1, 0.05, "suffix:opacity") var tuning_panel_faded_opacity: float = 0.35
@export_range(0, 1, 0.05, "suffix:s") var tuning_panel_fade_time: float = 0.15
