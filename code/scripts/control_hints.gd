class_name ControlHints
extends RefCounted

const KEYBOARD_NAMES := {
	&"move_left": "A",
	&"move_right": "D",
	&"jump": "W",
	&"slide": "S",
	&"pause_session": "P",
}
const GAMEPAD_NAMES := {
	&"move_left": "D-pad Left",
	&"move_right": "D-pad Right",
	&"jump": "the A button",
	&"slide": "the B button",
	&"pause_session": "Start",
}
const KEYBOARD_FOOTER := "Keyboard · A D W S    /    P to pause"
const GAMEPAD_FOOTER := "Controller · D-pad, A jump, B slide  /  Start to pause"


static func uses_gamepad() -> bool:
	return not Input.get_connected_joypads().is_empty()


static func input_name(source_action: StringName, gamepad: bool) -> String:
	return (GAMEPAD_NAMES if gamepad else KEYBOARD_NAMES).get(source_action, "")


static func footer_text(gamepad: bool) -> String:
	return GAMEPAD_FOOTER if gamepad else KEYBOARD_FOOTER
