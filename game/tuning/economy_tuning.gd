class_name EconomyTuning
extends KitTuningSet
const KNOBS: Dictionary = {
	"iron_price": {"help": "Credits received for one unit of iron."},
	"gold_price": {"help": "Credits received for one unit of gold."},
	"stone_price": {"help": "Credits received for one unit of stone."},
	"refuel_price": {"help": "Credits paid for each unit of energy refilled."},
	"dock_range": {"help": "Distance from the dock needed to sell and refuel."}
}
@export_range(0, 50, 0.25, "suffix:credits/ore") var iron_price: float = 5.0
@export_range(0, 50, 0.25, "suffix:credits/ore") var gold_price: float = 12.0
@export_range(0, 50, 0.25, "suffix:credits/ore") var stone_price: float = 2.0
@export_range(0, 10, 0.1, "suffix:credits/energy") var refuel_price: float = 0.5
@export_range(1, 10, 0.25, "suffix:m") var dock_range: float = 3.0
