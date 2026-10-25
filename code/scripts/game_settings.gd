class_name GameSettings
extends RefCounted

# Visual pace affects road and ambient scenery only. Prompt response timing stays prescribed.
const CALM_PACE := 0.85
const STANDARD_PACE := 1.0
const LIVELY_PACE := 1.15
# The review rating (1 = faster ... 10 = slower) maps onto this scenery-only range.
const MIN_PACE := 0.40
const MAX_PACE := 2.20

static var visual_pace := STANDARD_PACE
static var reduced_motion := false
static var effects_intensity := 1.0
# One-shot: the Ready screen sets it, the runner consumes it to play the 3-2-1 start countdown.
static var start_countdown_pending := false
# Seconds counted down before a run (0 = off). Only 0, 3 and 5 are offered in Settings.
static var countdown_seconds := 3


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
	if not is_preset_pace():
		return "%d/10 (%.1fx)" % [rating_for_pace(visual_pace), visual_pace]
	return "Standard"


static func set_reduced_motion(value: bool) -> void:
	reduced_motion = value


static func set_effects_intensity(value: float) -> void:
	if is_equal_approx(value, 0.5) or is_equal_approx(value, 1.0):
		effects_intensity = value


static func set_countdown_seconds(value: int) -> void:
	if value == 0 or value == 3 or value == 5:
		countdown_seconds = value


static func is_preset_pace() -> bool:
	return is_equal_approx(visual_pace, CALM_PACE) or is_equal_approx(visual_pace, STANDARD_PACE) or is_equal_approx(visual_pace, LIVELY_PACE)


# Nearest 1-10 speed number for the current pace (shown in Setup; 1 = fastest).
static func rating_for_pace(pace: float) -> int:
	var step := clampf((MAX_PACE - pace) / (MAX_PACE - MIN_PACE), 0.0, 1.0)
	return clampi(roundi(1.0 + step * 9.0), 1, 10)


# Evens out how an obstacle closes in, never when it arrives: 0 stays 0 and 1 stays 1.
# The road's perspective curve already holds distant props small and then rushes them
# (power 1.85); this softens that so the approach reads as steady. A faster speed
# softens it a little more. Prompt timing is not touched.
static func approach_fraction(fraction: float) -> float:
	var exponent := clampf(0.65 - maxf(0.0, visual_pace - STANDARD_PACE) * 0.08, 0.5, 0.65)
	return pow(clampf(fraction, 0.0, 1.0), exponent)
