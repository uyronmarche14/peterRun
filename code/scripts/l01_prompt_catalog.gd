class_name L01PromptCatalog
extends RefCounted

const PLANNED_SEQUENCE: Array[StringName] = [
	&"move_left",
	&"jump",
	&"move_right",
	&"slide",
]


func get_planned_sequence() -> Array[StringName]:
	return PLANNED_SEQUENCE.duplicate()


func get_prop_id(action_name: StringName) -> StringName:
	match action_name:
		&"move_left", &"move_right":
			return &"crate"
		&"jump":
			return &"puddle"
		&"slide":
			return &"laundry_line"
		_:
			return &""


func get_action_label(action_name: StringName) -> String:
	match action_name:
		&"move_left":
			return "MOVE LEFT"
		&"move_right":
			return "MOVE RIGHT"
		&"jump":
			return "JUMP"
		&"slide":
			return "SLIDE"
		_:
			return ""
