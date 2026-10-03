class_name KitMap
extends RefCounted

static func paths(directory: String, extension: String) -> Array[String]:
	var result: Array[String] = []
	var dir: DirAccess = DirAccess.open(directory)
	if dir == null:
		push_error("Cannot inspect directory: " + directory)
		return result
	var error: Error = dir.list_dir_begin()
	if error != OK:
		push_error("Cannot list directory: " + error_string(error))
		return result
	var name: String = dir.get_next()
	while not name.is_empty():
		var path: String = directory.path_join(name)
		if dir.current_is_dir() and not name.begins_with("."):
			result.append_array(paths(path, extension))
		elif name.get_extension() == extension:
			result.append(path)
		name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result

static func generate() -> Error:
	var text: String = "# Game map\n\nGenerated from declarations. Change the source resource and regenerate this map.\n\n"
	var categories: Dictionary = {"Actions": [], "Events": [], "Tuning": [], "Record types": [], "Feel sequences": [], "Scenarios": []}
	var resources: Array[String] = paths("res://addons/agent_kit", "tres")
	if DirAccess.dir_exists_absolute("res://game"):
		resources.append_array(paths("res://game", "tres"))
	for path: String in resources:
		var resource: Resource = load(path)
		var link: String = "[%s](%s)" % [path.trim_prefix("res://"), path.trim_prefix("res://")]
		if resource is KitActionDef:
			var requirements: Array[String] = []
			for condition: KitCondition in resource.requires:
				requirements.append("%s: %s" % [condition.rule_id, condition.description])
			categories.Actions.append("- **%s** — %s %s\n  - Requires: %s\n  - Charge: %s; overflow: %s; tuning: %s; success events: %s; rejection events: %s; clip events: %s.\n" % [resource.id, resource.description, link, "; ".join(requirements) if not requirements.is_empty() else "handler checks", KitActionDef.ChargePolicy.keys()[resource.charge_policy], KitActionDef.OverflowPolicy.keys()[resource.overflow_policy], resource.tuning_set, ", ".join(resource.events_on_success), ", ".join(resource.events_on_reject), ", ".join(resource.events_on_clip)])
		elif resource is KitEventRegistry:
			for event: String in resource.declarations:
				var definition: Dictionary = resource.declarations[event]
				categories.Events.append("- **%s** — %s Payload: %s. %s\n" % [event, definition.description, ", ".join(definition.fields), link])
		elif resource is KitTuningSet:
			var rows: String = "- **%s** — %s %s\n\n  | Knob | Value | Unit | Range | Help |\n  |---|---:|---|---|---|\n" % [resource.id, resource.description, link]
			for knob: String in resource.knobs():
				var metadata: Dictionary = resource.metadata(knob)
				rows += "  | %s | %s | %s | %s to %s | %s%s |\n" % [knob, str(resource.get(knob)), metadata.get("unit", ""), metadata.get("min", ""), metadata.get("max", ""), metadata.get("help", ""), " Restart needed." if metadata.get("restart", false) else ""]
			categories.Tuning.append(rows + "\n")
		elif resource is KitRecordType:
			categories["Record types"].append("- **%s** — %s Fields: %s. Limits: %s. %s\n" % [resource.id, resource.description, JSON.stringify(resource.fields), JSON.stringify(resource.limits), link])
		elif resource is KitFeelSequence:
			var stages: Array[String] = []
			for stage: KitFeelStage in resource.stages:
				stages.append("%s (%ss)" % [stage.stage_name, stage.duration])
			categories["Feel sequences"].append("- **%s** — %s Event: %s; stages: %s. %s\n" % [resource.id, resource.description, resource.trigger_event, " → ".join(stages), link])
	if DirAccess.dir_exists_absolute("res://scenarios"):
		for path: String in paths("res://scenarios", "gd"):
			var script: Script = load(path)
			if script == null or not script.can_instantiate():
				return ERR_PARSE_ERROR
			var instance: RefCounted = script.new()
			if instance is KitScenario and not instance.id.is_empty():
				categories.Scenarios.append("- **%s** — %s [%s](%s)\n" % [instance.id, instance.description, path.trim_prefix("res://"), path.trim_prefix("res://")])
	for category: String in categories:
		text += "## %s\n\n%s\n" % [category, "".join(categories[category])]
	return KitCanonical.write_text("res://GAME_MAP.md", text.strip_edges(false, true) + "\n")
