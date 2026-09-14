class_name PatternDefinition
extends RefCounted

## Validates one authored, non-punitive obstacle formation.
## Rendering remains on the legacy action/lane bridge until PR-14C.

const VALID_ACTIONS := [&"move_left", &"move_right", &"jump", &"slide"]
const VALID_CATEGORIES := [&"beginner", &"normal", &"recovery", &"mixed"]
const VALID_OBSTACLE_KINDS := [&"crate", &"puddle", &"laundry_line"]


static func validate(pattern: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var pattern_id := StringName(pattern.get("pattern_id", &""))
	if pattern_id == &"":
		errors.append("Pattern identity is required.")
	var category := StringName(pattern.get("category", &""))
	if not VALID_CATEGORIES.has(category):
		errors.append("Pattern category is invalid.")

	var required_action := StringName(pattern.get("required_action", &""))
	if not VALID_ACTIONS.has(required_action):
		errors.append("Pattern requires a supported action.")

	var obstacles: Array = []
	var obstacle_value: Variant = pattern.get("obstacles", [])
	if obstacle_value is Array:
		obstacles = obstacle_value
	else:
		errors.append("Pattern obstacles must be an array.")
	if obstacles.is_empty():
		errors.append("Pattern needs at least one obstacle.")
	var obstacle_lanes: Array[int] = []
	for obstacle_value_item in obstacles:
		if not obstacle_value_item is Dictionary:
			errors.append("Each obstacle must be a dictionary.")
			continue
		var obstacle: Dictionary = obstacle_value_item
		var kind := StringName(obstacle.get("kind", &""))
		if not VALID_OBSTACLE_KINDS.has(kind):
			errors.append("Pattern has an unknown obstacle kind.")
		var lane_value: Variant = obstacle.get("lane", -1)
		if not _is_valid_lane(lane_value):
			errors.append("Obstacle lanes must be 0, 1 or 2.")
			continue
		var lane: int = lane_value
		if obstacle_lanes.has(lane):
			errors.append("Obstacle lanes cannot be duplicated.")
		else:
			obstacle_lanes.append(lane)

	var open_lanes := _read_lanes(pattern, "open_lanes", errors)
	for lane in open_lanes:
		if obstacle_lanes.has(lane):
			errors.append("Open lanes cannot contain an obstacle.")
	var entry_lanes := _read_lanes(pattern, "entry_lanes", errors)
	if entry_lanes.is_empty():
		errors.append("Pattern needs at least one entry lane.")
	var ending_lane_value: Variant = pattern.get("ending_lane", -1)
	if not _is_valid_lane(ending_lane_value):
		errors.append("Pattern needs a valid ending lane.")
	var ending_lane := int(ending_lane_value) if _is_valid_lane(ending_lane_value) else -1

	var idle_value: Variant = pattern.get("allow_idle_safe_clear", null)
	if not idle_value is bool:
		errors.append("Pattern must state whether idle safe clear is allowed.")
	var allows_idle_safe_clear: bool = idle_value == true

	if required_action == &"move_left" or required_action == &"move_right":
		_validate_movement_gate(required_action, obstacles, obstacle_lanes, open_lanes, entry_lanes, ending_lane, allows_idle_safe_clear, errors)
	elif required_action == &"jump" or required_action == &"slide":
		_validate_lane_action(required_action, obstacles, open_lanes, entry_lanes, ending_lane, allows_idle_safe_clear, pattern, errors)
	return errors


static func _validate_movement_gate(required_action: StringName, obstacles: Array, obstacle_lanes: Array[int], open_lanes: Array[int], entry_lanes: Array[int], ending_lane: int, allows_idle_safe_clear: bool, errors: PackedStringArray) -> void:
	if open_lanes.is_empty():
		errors.append("Movement gates need at least one open lane.")
	if ending_lane >= 0 and not open_lanes.has(ending_lane):
		errors.append("Movement-gate ending lane must be open.")
	for obstacle_value in obstacles:
		if obstacle_value is Dictionary and StringName(obstacle_value.get("kind", &"")) != &"crate":
			errors.append("Movement gates require crate obstacles.")
			break
	for entry_lane in entry_lanes:
		var reachable := allows_idle_safe_clear and open_lanes.has(entry_lane)
		var moved_lane := entry_lane - 1 if required_action == &"move_left" else entry_lane + 1
		if moved_lane >= 0 and moved_lane <= 2 and open_lanes.has(moved_lane):
			reachable = true
		if not reachable:
			errors.append("Every declared movement-gate entry lane must reach an open lane.")
			break


static func _validate_lane_action(required_action: StringName, obstacles: Array, _open_lanes: Array[int], entry_lanes: Array[int], ending_lane: int, allows_idle_safe_clear: bool, pattern: Dictionary, errors: PackedStringArray) -> void:
	if allows_idle_safe_clear:
		errors.append("Jump and slide formations cannot allow idle safe clear.")
	var action_lane_value: Variant = pattern.get("action_lane", -1)
	if not _is_valid_lane(action_lane_value):
		errors.append("Jump and slide formations need an action lane.")
		return
	var action_lane: int = action_lane_value
	if ending_lane >= 0 and ending_lane != action_lane:
		errors.append("Jump and slide ending lane must match the action lane.")
	for entry_lane in entry_lanes:
		if entry_lane != action_lane:
			errors.append("Jump and slide entry lanes must match the action lane.")
			break
	var expected_kind := &"puddle" if required_action == &"jump" else &"laundry_line"
	var has_action_prop := false
	for obstacle_value in obstacles:
		if not obstacle_value is Dictionary:
			continue
		var obstacle: Dictionary = obstacle_value
		if StringName(obstacle.get("kind", &"")) == expected_kind and obstacle.get("lane", -1) == action_lane:
			has_action_prop = true
	if not has_action_prop:
		errors.append("Jump and slide formations need their matching prop in the action lane.")


static func _read_lanes(pattern: Dictionary, property_name: String, errors: PackedStringArray) -> Array[int]:
	var lanes: Array[int] = []
	var value: Variant = pattern.get(property_name, [])
	if not value is Array:
		errors.append(property_name + " must be an array.")
		return lanes
	for lane_value in value:
		if not _is_valid_lane(lane_value):
			errors.append(property_name + " values must be 0, 1 or 2.")
			continue
		var lane: int = lane_value
		if lanes.has(lane):
			errors.append(property_name + " values cannot be duplicated.")
		else:
			lanes.append(lane)
	return lanes


static func _is_valid_lane(value: Variant) -> bool:
	return value is int and value >= 0 and value <= 2
