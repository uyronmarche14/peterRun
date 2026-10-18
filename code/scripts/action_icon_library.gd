extends RefCounted

const ICONS := {
	&"move_left": preload("res://art/ui/action_icons/move_left.svg"),
	&"move_right": preload("res://art/ui/action_icons/move_right.svg"),
	&"jump": preload("res://art/ui/action_icons/jump.svg"),
	&"slide": preload("res://art/ui/action_icons/slide.svg"),
}


static func for_action(action: StringName) -> Texture2D:
	return ICONS.get(action, null)
