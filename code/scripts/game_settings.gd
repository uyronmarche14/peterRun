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
# While the start countdown runs the road moves at this share of the chosen pace, then
# eases up to full pace over RAMP_SECONDS after "Go!".
const COUNTDOWN_PACE_FRACTION := 0.3
const RAMP_SECONDS := 0.5
static var start_ramp := 1.0


static func set_visual_pace(value: float) -> void:
	if value >= MIN_PACE - 0.0001 and value <= MAX_PACE + 0.0001:
		visual_pace = value


# Speed 1 = fastest (MAX_PACE), speed 6 = exactly the standard pace, speed 10 = slowest (MIN_PACE).
const STANDARD_RATING := 6


static func pace_for_rating(rating: int) -> float:
	var speed := clampi(rating, 1, 10)
	if speed <= STANDARD_RATING:
		return lerpf(MAX_PACE, STANDARD_PACE, float(speed - 1) / float(STANDARD_RATING - 1))
	return lerpf(STANDARD_PACE, MIN_PACE, float(speed - STANDARD_RATING) / float(10 - STANDARD_RATING))


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
	if pace >= STANDARD_PACE:
		var fast_step := clampf((MAX_PACE - pace) / (MAX_PACE - STANDARD_PACE), 0.0, 1.0)
		return clampi(roundi(1.0 + fast_step * float(STANDARD_RATING - 1)), 1, STANDARD_RATING)
	var slow_step := clampf((STANDARD_PACE - pace) / (STANDARD_PACE - MIN_PACE), 0.0, 1.0)
	return clampi(roundi(float(STANDARD_RATING) + slow_step * float(10 - STANDARD_RATING)), STANDARD_RATING, 10)


# An obstacle always starts far up the road and travels at one steady pace to contact,
# at every speed setting. Contact lands on time (progress 1 at the end of the approach)
# because prompt timing is fixed, so the speed setting does not change the obstacle's
# journey; it changes the road, Peter's stride and the ambience.
# Depth is eased in two straight pieces, so size and ground speed both stay even.
const APPROACH_KNOT_PROGRESS := 0.4


static func _depth_at(progress: float) -> float:
	var knot_depth := RoadProjection.MID_DEPTH
	if progress <= APPROACH_KNOT_PROGRESS:
		return knot_depth * progress / APPROACH_KNOT_PROGRESS
	return knot_depth + (1.0 - knot_depth) * (progress - APPROACH_KNOT_PROGRESS) / (1.0 - APPROACH_KNOT_PROGRESS)


# Maps time through the approach (0..1) to the road projection fraction.
static func approach_fraction(fraction: float) -> float:
	return RoadProjection.fraction_from_depth(_depth_at(clampf(fraction, 0.0, 1.0)))


const WARNING_SECONDS_STANDARD := 2.5
const WARNING_SECONDS_FASTEST := 1.5
const WARNING_SECONDS_SLOWEST := 4.0


# How long the GET READY warning lasts at a pace. Only the warning changes: the 2.0 s
# response window and the 0.75 s settle stay as prescribed. Standard pace is exactly 2.5 s.
static func warning_seconds_for_pace(pace: float) -> float:
	if pace >= STANDARD_PACE:
		return lerpf(WARNING_SECONDS_STANDARD, WARNING_SECONDS_FASTEST, clampf((pace - STANDARD_PACE) / (MAX_PACE - STANDARD_PACE), 0.0, 1.0))
	return lerpf(WARNING_SECONDS_STANDARD, WARNING_SECONDS_SLOWEST, clampf((STANDARD_PACE - pace) / (STANDARD_PACE - MIN_PACE), 0.0, 1.0))


# The pace the road, scenery and Peter's stride actually move at right now.
static func motion_pace() -> float:
	return visual_pace * start_ramp


# Input sensitivity: how soon the same action may repeat and how far a stick must move.
const SENSITIVITY_LOW := 0
const SENSITIVITY_NORMAL := 1
const SENSITIVITY_HIGH := 2
const SENSITIVITY_COOLDOWNS := [0.5, 0.35, 0.15]
const SENSITIVITY_STICK_THRESHOLDS := [0.65, 0.5, 0.35]
const SENSITIVITY_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"jump", &"slide"]
static var input_sensitivity := SENSITIVITY_NORMAL
static var settings_path := "user://settings.cfg"


static func set_input_sensitivity(value: int) -> void:
	if value < SENSITIVITY_LOW or value > SENSITIVITY_HIGH:
		return
	input_sensitivity = value
	apply_stick_threshold()
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value("input", "sensitivity", value)
	config.save(settings_path)


static func input_cooldown_seconds() -> float:
	return SENSITIVITY_COOLDOWNS[input_sensitivity]


static func stick_threshold() -> float:
	return SENSITIVITY_STICK_THRESHOLDS[input_sensitivity]


static func apply_stick_threshold() -> void:
	for action_name in SENSITIVITY_ACTIONS:
		if InputMap.has_action(action_name):
			InputMap.action_set_deadzone(action_name, stick_threshold())


# Reads the remembered sensitivity (called once when the game opens).
static func load_saved_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var saved: Variant = config.get_value("input", "sensitivity", SENSITIVITY_NORMAL)
	if typeof(saved) == TYPE_INT and saved >= SENSITIVITY_LOW and saved <= SENSITIVITY_HIGH:
		input_sensitivity = saved
		apply_stick_threshold()
