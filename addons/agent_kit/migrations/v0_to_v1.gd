extends RefCounted
## Example supported legacy wrapper: schema 0 called world records 'records'.
func migrate(payload: Dictionary) -> Dictionary:
	var next: Dictionary = payload.duplicate(true)
	if not next.has("records"):
		return {}
	next["world"] = next.records
	next.erase("records")
	return next
