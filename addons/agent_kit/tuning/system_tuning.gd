class_name KitSystemTuning
extends KitTuningSet
const KNOBS: Dictionary = {
	"tick_rate": {"help": "Simulation ticks each second.", "restart": true},
	"log_capacity": {"help": "Recent operations and events kept during play."},
	"flash_decay": {"help": "How quickly the screen flash fades; no rule effects."}
}
@export_range(1, 120, 1, "suffix:Hz") var tick_rate: float = 30.0
@export_range(32, 8192, 1, "suffix:records") var log_capacity: int = 512
@export_range(0.1, 20, 0.1, "suffix:opacity/s") var flash_decay: float = 2.5
