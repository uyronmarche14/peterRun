class_name ControlHints
extends RefCounted

const KEYBOARD_NAMES := {
	&"move_left": "A",
	&"move_right": "D",
	&"jump": "W",
	&"slide": "S",
	&"pause_session": "P",
}
# Godot maps buttons by position: jump is the bottom face button, slide the
# right one. Each family prints different labels on those positions.
# In menus the bottom button is Select (ui_accept), the right one Back
# (ui_cancel) and the top one Continue on practice screens.
const FACE_BUTTONS := {
	&"xbox": {&"jump": "A", &"slide": "B", &"pause_session": "Start", &"continue": "Y"},
	&"playstation": {&"jump": "Cross", &"slide": "Circle", &"pause_session": "Options", &"continue": "Triangle"},
	&"nintendo": {&"jump": "B", &"slide": "A", &"pause_session": "+", &"continue": "X"},
}
const KEYBOARD_FOOTER := "Keyboard · A D W S to move · P to pause"


static func uses_gamepad() -> bool:
	return not Input.get_connected_joypads().is_empty()


static func connected_gamepad_name() -> String:
	var pads := Input.get_connected_joypads()
	return Input.get_joy_name(pads[0]) if not pads.is_empty() else ""


static func gamepad_style(joy_name: String) -> StringName:
	var name := joy_name.to_lower()
	for marker in ["nintendo", "switch", "joy-con", "joycon"]:
		if name.contains(marker):
			return &"nintendo"
	for marker in ["playstation", "dualshock", "dualsense", "sony", "ps3", "ps4", "ps5"]:
		if name.contains(marker):
			return &"playstation"
	return &"xbox"


static func input_name(source_action: StringName, gamepad: bool, joy_name: String = connected_gamepad_name()) -> String:
	if not gamepad:
		return KEYBOARD_NAMES.get(source_action, "")
	match source_action:
		&"move_left":
			return "D-pad Left"
		&"move_right":
			return "D-pad Right"
		&"pause_session":
			return FACE_BUTTONS[gamepad_style(joy_name)][source_action]
	return "the %s button" % FACE_BUTTONS[gamepad_style(joy_name)].get(source_action, "")


static func menu_hint(gamepad: bool, joy_name: String = connected_gamepad_name()) -> String:
	if not gamepad:
		return "Enter Select · Esc Back"
	var buttons: Dictionary = FACE_BUTTONS[gamepad_style(joy_name)]
	return "%s Select · %s Back" % [buttons[&"jump"], buttons[&"slide"]]


static func continue_hint(gamepad: bool, joy_name: String = connected_gamepad_name()) -> String:
	if not gamepad:
		return "Click Continue"
	return "%s Continue" % FACE_BUTTONS[gamepad_style(joy_name)][&"continue"]


static func footer_text(gamepad: bool, joy_name: String = connected_gamepad_name()) -> String:
	if not gamepad:
		return KEYBOARD_FOOTER
	var buttons: Dictionary = FACE_BUTTONS[gamepad_style(joy_name)]
	return "Controller · D-pad, %s jump, %s slide · %s to pause" % [buttons[&"jump"], buttons[&"slide"], buttons[&"pause_session"]]
