class_name GameSettings
extends RefCounted

# Visual pace affects road and roadside motion only. Prompt response timing stays prescribed.
const CALM_PACE := 0.85
const STANDARD_PACE := 1.0
const LIVELY_PACE := 1.15

static var visual_pace := STANDARD_PACE


static func set_visual_pace(value: float) -> void:
	if is_equal_approx(value, CALM_PACE) or is_equal_approx(value, STANDARD_PACE) or is_equal_approx(value, LIVELY_PACE):
		visual_pace = value


static func get_pace_label() -> String:
	if is_equal_approx(visual_pace, CALM_PACE):
		return "Calm"
	if is_equal_approx(visual_pace, LIVELY_PACE):
		return "Lively"
	return "Standard"
