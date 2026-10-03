class_name ShipTuning
extends KitTuningSet
const KNOBS: Dictionary = {
	"speed": {"help": "Maximum flight speed."},
	"accel": {"help": "How quickly the ship responds and brakes."},
	"energy_max": {"help": "Full energy capacity on the next setup.", "restart": true},
	"cargo_capacity": {"help": "Shared capacity of all ore types on the next setup.", "restart": true},
	"starting_credits": {"help": "Credits at the start of a run.", "restart": true}
}
@export_range(0.5, 20, 0.25, "suffix:m/s") var speed: float = 4.0
@export_range(0.5, 30, 0.25, "suffix:m/s²") var accel: float = 7.0
@export_range(1, 200, 1, "suffix:energy") var energy_max: float = 40.0
@export_range(1, 100, 1, "suffix:ore") var cargo_capacity: float = 12.0
@export_range(0, 1000, 1, "suffix:credits") var starting_credits: float = 20.0
