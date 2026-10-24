class_name GameSettings
extends RefCounted

# Visual pace affects road and ambient scenery only. Prompt response timing stays prescribed.
const CALM_PACE := 0.85
const STANDARD_PACE := 1.0
const LIVELY_PACE := 1.15
# The review rating (1 = faster ... 10 = slower) maps onto this scenery-only range.
const MIN_PACE := 0.70
const MAX_PACE := 1.30

static var visual_pace := STANDARD_PACE
static var reduced_motion := false
static var effects_intensity := 1.0
# One-shot: the Ready screen sets it, the runner consumes it to play the 3-2-1 start countdown.
static var start_countdown_pending := false


static func set_visual_pace(value: float) -> void:
	if value >= MIN_PACE - 0.0001 and value <= MAX_PACE + 0.0001:
		visual_pace = value


# 1 = fastest (MAX_PACE) ... 10 = slowest (MIN_PACE), linear in between.
static func pace_for_rating(rating: int) -> float:
	var step := clampf(float(rating - 1) / 9.0, 0.0, 1.0)
	return lerpf(MAX_PACE, MIN_PACE, step)


static func get_pace_label() -> String:
	if is_equal_approx(visual_pace, CALM_PACE):
		return "Calm"
	if is_equal_approx(visual_pace, LIVELY_PACE):
		return "Lively"
	return "Standard"


static func set_reduced_motion(value: bool) -> void:
	reduced_motion = value


static func set_effects_intensity(value: float) -> void:
	if is_equal_approx(value, 0.5) or is_equal_approx(value, 1.0):
		effects_intensity = value
