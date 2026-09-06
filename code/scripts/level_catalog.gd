extends Resource

@export var levels: Array[Resource] = []


func find_level(level_id: StringName) -> Resource:
	for definition in levels:
		if definition != null and definition.get("level_id") == level_id:
			return definition
	return null
