class_name RoadProjection
extends RefCounted

## Shared screen-space projection for player lanes, prompts, and moving props.
## L01 adds its own curb profile for the v06 painted road without changing
## other routes' established road geometry.

const SCREEN_CENTRE_X := 240.0
const HORIZON_Y := 112.0
const PLAYER_CONTACT_Y := 218.0
const FAR_SCALE := 0.24
const MID_SCALE := 0.68
const PLAYER_SCALE := 1.58
const MID_DEPTH := 0.48
const FAR_LANE_SPAN := 18.0
const PLAYER_LANE_SPAN := 132.0
const FAR_ROAD_HALF_WIDTH := 58.0
const PLAYER_ROAD_HALF_WIDTH := 216.0
const L01_FAR_ROAD_HALF_WIDTH := 32.0
const L01_PLAYER_ROAD_HALF_WIDTH := 168.0
const PROP_LANE_FILL_RATIO := 0.84
const PROP_MAX_SCREEN_HEIGHT := 100.0
const PLAYER_LANE_X := [
	SCREEN_CENTRE_X - PLAYER_LANE_SPAN,
	SCREEN_CENTRE_X,
	SCREEN_CENTRE_X + PLAYER_LANE_SPAN,
]


static func depth_curve(fraction: float) -> float:
	# Hold distant props small, then accelerate their apparent growth as they
	# enter Peter's foreground. This supplies the runner-style perspective
	# effect without changing approach time or world speed.
	return pow(clampf(fraction, 0.0, 1.0), 1.85)


static func scale_at(fraction: float) -> float:
	var projected_depth := depth_curve(fraction)
	if projected_depth <= MID_DEPTH:
		return lerpf(FAR_SCALE, MID_SCALE, projected_depth / MID_DEPTH)
	return lerpf(MID_SCALE, PLAYER_SCALE, (projected_depth - MID_DEPTH) / (1.0 - MID_DEPTH))


static func fraction_from_scale(value: float) -> float:
	var projected_depth := 0.0
	if value <= MID_SCALE:
		projected_depth = inverse_lerp(FAR_SCALE, MID_SCALE, clampf(value, FAR_SCALE, MID_SCALE)) * MID_DEPTH
	else:
		projected_depth = MID_DEPTH + inverse_lerp(MID_SCALE, PLAYER_SCALE, clampf(value, MID_SCALE, PLAYER_SCALE)) * (1.0 - MID_DEPTH)
	return pow(clampf(projected_depth, 0.0, 1.0), 1.0 / 1.85)


static func screen_y_at(fraction: float) -> float:
	return lerpf(HORIZON_Y, PLAYER_CONTACT_Y, depth_curve(fraction))


static func lane_span_at(fraction: float) -> float:
	return lerpf(FAR_LANE_SPAN, PLAYER_LANE_SPAN, depth_curve(fraction))


static func lane_center_at(lane: int, fraction: float) -> float:
	return SCREEN_CENTRE_X + float(clampi(lane, 0, 2) - 1) * lane_span_at(fraction)


static func lane_separator_at(separator_index: int, fraction: float) -> float:
	var centered_separator := float(clampi(separator_index, 0, 1)) - 0.5
	return SCREEN_CENTRE_X + centered_separator * lane_span_at(fraction)


static func road_half_width_at(fraction: float) -> float:
	return lerpf(FAR_ROAD_HALF_WIDTH, PLAYER_ROAD_HALF_WIDTH, depth_curve(fraction))


static func road_edge_at(side: int, fraction: float) -> float:
	return SCREEN_CENTRE_X + signf(float(side)) * road_half_width_at(fraction)


static func l01_road_half_width_at(fraction: float) -> float:
	return lerpf(L01_FAR_ROAD_HALF_WIDTH, L01_PLAYER_ROAD_HALF_WIDTH, depth_curve(fraction))


static func l01_road_edge_at(side: int, fraction: float) -> float:
	return SCREEN_CENTRE_X + signf(float(side)) * l01_road_half_width_at(fraction)


static func prop_fit_scale(base_footprint: Vector2, fraction: float) -> float:
	if base_footprint.x <= 0.0 or base_footprint.y <= 0.0:
		return 1.0
	var depth_scale := scale_at(fraction)
	var width_fit := lane_span_at(fraction) * PROP_LANE_FILL_RATIO / (base_footprint.x * depth_scale)
	var height_fit := PROP_MAX_SCREEN_HEIGHT / (base_footprint.y * depth_scale)
	return clampf(minf(1.0, minf(width_fit, height_fit)), 0.0, 1.0)


static func projected_prop_size(base_footprint: Vector2, fraction: float) -> Vector2:
	return base_footprint * scale_at(fraction) * prop_fit_scale(base_footprint, fraction)
