class_name KitClock
extends RefCounted
signal advanced(tick: int)
enum Mode { FIXED_TICK, MANUAL_TURN }
var mode: Mode = Mode.FIXED_TICK
var tick: int = 0
var tick_rate: float = 30.0
var _accumulator: float = 0.0

func seconds() -> float:
	return float(tick) / tick_rate

func advance(count: int = 1) -> void:
	for index: int in range(maxi(count, 0)):
		tick += 1
		advanced.emit(tick)

func process(delta: float) -> void:
	if mode != Mode.FIXED_TICK:
		return
	_accumulator += delta
	while _accumulator >= 1.0 / tick_rate:
		_accumulator -= 1.0 / tick_rate
		advance()

func snapshot() -> Dictionary:
	return {"tick": tick, "tick_rate": tick_rate, "mode": int(mode), "accumulator": _accumulator}

func restore(data: Dictionary) -> void:
	tick = int(data.tick)
	tick_rate = float(data.tick_rate)
	mode = int(data.mode) as Mode
	_accumulator = float(data.get("accumulator", 0.0))
