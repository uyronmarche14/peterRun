class_name MenuFocus
extends RefCounted

## Gamepad/keyboard menu helpers. A focused Button already presses on
## ui_accept (A/Cross, Enter, Space); screens only choose the first highlight
## and route ui_cancel (B/Circle, Esc) to their own Back action.


static func focus(control: Control) -> void:
	if control != null and control.is_visible_in_tree() and not (control is BaseButton and control.disabled):
		control.call_deferred("grab_focus")


static func is_back(event: InputEvent) -> bool:
	return event.is_action_pressed(&"ui_cancel") and not event.is_echo()


static func is_continue_alt(event: InputEvent) -> bool:
	return event.is_action_pressed(&"menu_continue_alt") and not event.is_echo()
