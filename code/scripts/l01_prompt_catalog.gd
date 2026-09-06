class_name L01PromptCatalog
extends RefCounted

# Compatibility facade for existing L01 tests/tools. Runtime uses LevelDefinition.
const Definition = preload("res://data/levels/l01_barangay.tres")


func get_planned_sequence() -> Array[StringName]:
	return Definition.get_planned_sequence()


func get_prop_id(action_name: StringName) -> StringName:
	return Definition.get_prop_id(action_name)


func get_action_label(action_name: StringName) -> String:
	return Definition.get_action_label(action_name)
