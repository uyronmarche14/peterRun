extends RefCounted

const Definition = preload("res://scripts/level_definition.gd")
const Catalog = preload("res://data/levels/catalog.tres")


static func resolve(config) -> Resource:
	if config == null:
		return null
	var definition: Resource = config.level_definition
	if definition == null:
		definition = Catalog.find_level(config.selected_level_id)
	if not definition is Definition:
		return null
	if definition.level_id != config.selected_level_id or not definition.validate().is_empty():
		return null
	return definition
