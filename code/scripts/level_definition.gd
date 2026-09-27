class_name LevelDefinition
extends Resource

const DEFAULT_PATTERN_SETS := [
	{"actions": [&"move_left", &"jump", &"move_right", &"slide"], "lanes": [1, 0, 0, 1]},
	{"actions": [&"move_right", &"jump", &"move_left", &"slide"], "lanes": [1, 2, 2, 1]},
	{"actions": [&"jump", &"move_left", &"slide", &"move_right"], "lanes": [1, 1, 0, 0]},
	{"actions": [&"slide", &"move_right", &"jump", &"move_left"], "lanes": [1, 1, 2, 2]},
	{"actions": [&"jump", &"slide", &"move_left", &"move_right"], "lanes": [1, 1, 1, 0]},
	{"actions": [&"move_right", &"slide", &"move_left", &"jump"], "lanes": [1, 2, 2, 1]},
	{"actions": [&"slide", &"move_left", &"jump", &"move_right"], "lanes": [1, 1, 0, 0]},
	{"actions": [&"jump", &"move_right", &"slide", &"move_left"], "lanes": [1, 1, 2, 2]},
]

const Config = preload("res://scripts/session_config.gd")
const Pattern = preload("res://scripts/pattern_definition.gd")
const LABELS := {&"move_left": "MOVE LEFT", &"move_right": "MOVE RIGHT", &"jump": "JUMP", &"slide": "SLIDE"}
const ICONS := {&"move_left": "‹", &"move_right": "›", &"jump": "▲", &"slide": "▼"}

@export var level_id: StringName = &""
@export var short_name := ""
@export var title := ""
@export var sequence: Array[StringName] = []
@export var prompt_lanes: Array[int] = []
@export var pattern_sets: Array[Dictionary] = []
@export var formation_library: Array[Dictionary] = []
@export var move_prop: PackedScene
@export var jump_prop: PackedScene
@export var slide_prop: PackedScene
@export var move_prop_id: StringName = &"crate"
@export var jump_prop_id: StringName = &"puddle"
@export var slide_prop_id: StringName = &"laundry_line"
@export var sky_color := Color(0.035, 0.141, 0.196, 1)
@export var distant_color := Color(0.075, 0.278, 0.29, 1)
@export var horizon_color := Color(0.098, 0.37, 0.337, 1)
@export var road_color := Color(0.102, 0.145, 0.169, 1)
@export var background_texture: Texture2D
# Hidden routes stay in the catalog for development but are not offered in Setup.
@export var show_in_setup := true
# Data describes the existing cadence; a theme cannot silently change it.
@export var warning_seconds := 2.5
@export var response_seconds := 2.0
@export var resolved_seconds := 0.75


func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if level_id == &"" or short_name.strip_edges().is_empty() or title.strip_edges().is_empty():
		errors.append("Level identity is required.")
	if sequence.is_empty():
		errors.append("A planned sequence is required.")
	for action in sequence:
		if not Config.ACTIONS.has(action):
			errors.append("Unknown action: " + str(action))
	for action in Config.ACTIONS:
		if not sequence.has(action):
			errors.append("Sequence must cover every prescribed action: " + str(action))
	if not prompt_lanes.is_empty() and prompt_lanes.size() != sequence.size():
		errors.append("Prompt lanes must match the planned sequence length.")
	for lane in prompt_lanes:
		if lane < 0 or lane > 2:
			errors.append("Prompt lanes must be 0, 1 or 2.")
	for pattern in pattern_sets:
		var actions: Array = pattern.get("actions", [])
		var lanes: Array = pattern.get("lanes", [])
		if actions.is_empty() or actions.size() != lanes.size():
			errors.append("Each pattern needs aligned action and lane arrays.")
			continue
		for action in actions:
			if not Config.ACTIONS.has(StringName(action)):
				errors.append("Pattern has an unknown action: " + str(action))
		for lane in lanes:
			if int(lane) < 0 or int(lane) > 2:
				errors.append("Pattern lanes must be 0, 1 or 2.")
	for formation in formation_library:
		if not formation is Dictionary:
			errors.append("Each formation must be a dictionary.")
		else:
			errors.append_array(Pattern.validate(formation))
	if level_id == &"l01_barangay" and formation_library.is_empty():
		errors.append("L01 requires its authored formation library.")
	for scene in [move_prop, jump_prop, slide_prop]:
		if scene == null or not scene.can_instantiate():
			errors.append("Each action family requires a prop scene.")
		else:
			var state: SceneState = scene.get_state()
			if state.get_node_count() == 0 or not ClassDB.is_parent_class(state.get_node_type(0), "Node2D"):
				errors.append("Prop scene roots must be Node2D.")
	if warning_seconds != 2.5 or response_seconds != 2.0 or resolved_seconds != 0.75:
		errors.append("Theme changes must retain the existing 2.5 / 2.0 / 0.75 second cadence.")
	return errors


func get_planned_sequence() -> Array[StringName]:
	return sequence.duplicate()


func get_prompt_lane(sequence_index: int, fallback_lane: int = 1) -> int:
	if prompt_lanes.is_empty():
		return clampi(fallback_lane, 0, 2)
	return prompt_lanes[posmod(sequence_index, prompt_lanes.size())]


func get_pattern_sets() -> Array:
	if not pattern_sets.is_empty():
		return pattern_sets.duplicate(true)
	if level_id == &"l01_barangay":
		return DEFAULT_PATTERN_SETS.duplicate(true)
	var fallback_lanes: Array[int] = prompt_lanes.duplicate()
	while fallback_lanes.size() < sequence.size():
		fallback_lanes.append(1)
	return [{"actions": get_planned_sequence(), "lanes": fallback_lanes}]


func get_pattern_definitions() -> Array:
	if formation_library.is_empty() and level_id in [&"l02_market", &"l03_rainy_crossing"]:
		return _build_shared_formation_library()
	return formation_library.duplicate(true)


func _build_shared_formation_library() -> Array:
	# L02/L03 deliberately use the same safe formation contract as L01. Their
	# palette and scenery remain level-specific; their response cadence remains
	# the prescribed 2.5 / 2.0 / 0.75 seconds.
	var formations: Array = []
	for entry_lane in [1, 2]:
		formations.append(_make_movement_formation(&"move_left", entry_lane, entry_lane - 1, entry_lane == 2))
	for entry_lane in [0, 1]:
		formations.append(_make_movement_formation(&"move_right", entry_lane, entry_lane + 1, entry_lane == 0))
	for action_name in [&"jump", &"slide"]:
		for action_lane in [0, 1, 2]:
			formations.append(_make_lane_action_formation(action_name, action_lane))
	return formations


func _make_movement_formation(action_name: StringName, entry_lane: int, ending_lane: int, recovery: bool) -> Dictionary:
	var obstacles: Array[Dictionary] = []
	for lane in [0, 1, 2]:
		if lane != ending_lane:
			obstacles.append({"kind": &"crate", "lane": lane})
	return {
		"pattern_id": StringName("%s_%s_from_%d" % [level_id, action_name, entry_lane]),
		"category": &"recovery" if recovery else &"normal",
		"required_action": action_name,
		"obstacles": obstacles,
		"open_lanes": [ending_lane],
		"entry_lanes": [entry_lane],
		"ending_lane": ending_lane,
		"allow_idle_safe_clear": false,
	}


func _make_lane_action_formation(action_name: StringName, action_lane: int) -> Dictionary:
	var kind: StringName = &"puddle" if action_name == &"jump" else &"laundry_line"
	var category: StringName = &"recovery" if action_lane == 2 else &"normal"
	return {
		"pattern_id": StringName("%s_%s_lane_%d" % [level_id, action_name, action_lane]),
		"category": category,
		"required_action": action_name,
		"obstacles": [{"kind": kind, "lane": action_lane}],
		"open_lanes": [0, 1, 2],
		"action_lanes": [action_lane],
		"entry_lanes": [action_lane],
		"ending_lane": action_lane,
		"allow_idle_safe_clear": false,
	}


func get_prop_scene(action: StringName) -> PackedScene:
	match action:
		&"move_left", &"move_right": return move_prop
		&"jump": return jump_prop
		&"slide": return slide_prop
	return null


func get_prop_id(action: StringName) -> StringName:
	match action:
		&"move_left", &"move_right": return move_prop_id
		&"jump": return jump_prop_id
		&"slide": return slide_prop_id
	return &""


func get_action_label(action: StringName) -> String:
	return LABELS.get(action, "")


func get_action_icon(action: StringName) -> String:
	return ICONS.get(action, "•")
