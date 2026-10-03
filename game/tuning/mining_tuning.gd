class_name MiningTuning
extends KitTuningSet
const KNOBS: Dictionary = {
	"energy_cost": {"help": "Energy paid for each successful mining hit."},
	"range": {"help": "Maximum distance to the selected rock."},
	"cooldown": {"help": "Rule time between hits, independent of animation."},
	"tool_power": {"help": "Tool strength compared with the rock's hardness."},
	"iron_yield": {"help": "Iron collected when an iron rock breaks."},
	"gold_yield": {"help": "Gold collected when a gold rock breaks."},
	"stone_yield": {"help": "Stone collected when a stone rock breaks."},
	"soft_threshold": {"help": "Hardness of soft rocks.", "restart": true},
	"medium_threshold": {"help": "Hardness of medium rocks.", "restart": true},
	"hard_threshold": {"help": "Hardness of hard rocks.", "restart": true},
	"rock_health": {"help": "Initial health of each rock block.", "restart": true},
	"charge_on_attempt": {"help": "0: charge successful hits only. 1: also charge attempts against hard rocks."}
}
@export_range(0, 20, 0.25, "suffix:energy") var energy_cost: float = 4.0
@export_range(1, 30, 0.25, "suffix:m") var range: float = 8.0
@export_range(0.033333, 3, 0.033333, "suffix:s") var cooldown: float = 0.3
@export_range(0.25, 10, 0.25, "suffix:power") var tool_power: float = 2.0
@export_range(0, 20, 0.25, "suffix:ore") var iron_yield: float = 3.0
@export_range(0, 20, 0.25, "suffix:ore") var gold_yield: float = 1.0
@export_range(0, 20, 0.25, "suffix:ore") var stone_yield: float = 2.0
@export_range(0.25, 10, 0.25, "suffix:hardness") var soft_threshold: float = 1.0
@export_range(0.25, 10, 0.25, "suffix:hardness") var medium_threshold: float = 2.0
@export_range(0.25, 10, 0.25, "suffix:hardness") var hard_threshold: float = 4.0
@export_range(1, 40, 1, "suffix:health") var rock_health: float = 4.0
@export_range(0, 1, 1, "suffix:policy") var charge_on_attempt: int = 0
