extends SceneTree

var output_dir := "res://../test_evidence/l01_full_lane_action_cues"
const RoadProjection = preload("res://scripts/road_projection.gd")
const FORMATIONS := [
	"l01_p01_move_left",
	"l01_p02_move_right",
	"l01_p10_jump_gate_center",
	"l01_p11_slide_gate_center",
	"l01_p21_jump_gate_left",
	"l01_p22_jump_gate_right",
	"l01_p34_slide_gate_left",
	"l01_p35_slide_gate_right",
]


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Full-lane visual capture needs graphical Godot")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	root.mode = Window.MODE_WINDOWED
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	var motion := level.get_node(^"WorldMotion")
	motion.set_process(false)
	var route := level.get_node(^"LevelWorld/L01BarangayLayers")
	route.set_process(false)
	var library: Array = level.get("_formation_library")
	var captures := 0
	for id in FORMATIONS:
		var formation: Dictionary = {}
		for candidate in library:
			if String(candidate.get("pattern_id", &"")) == id:
				formation = candidate.duplicate(true)
				break
		assert(not formation.is_empty(), "Missing formation " + id)
		var director := level.get_node(^"PromptDirector")
		director.call("_set_state", 0)
		level.set("_active_formation", formation)
		level.set("active_formation_id", StringName(id))
		var action := StringName(formation.get("required_action", &""))
		var lane := int(formation.get("action_lane", 1))
		var player := level.get_node(^"Player") as Node2D
		player.call("reset_for_practice")
		player.get("_lane_state").set("lane_index", lane)
		player.position.x = RoadProjection.PLAYER_LANE_X[lane]
		player.call("set_walking", true)
		assert(director.call("schedule", action, lane))
		motion.set("_prompt_elapsed", 3.6)
		motion.call("_apply_prompt_projection")
		motion.call("set_motion_paused", true)
		for size in [Vector2i(480, 270), Vector2i(960, 540)]:
			root.size = size
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "%s/%s_%dx%d.png" % [output_dir, id, size.x, size.y]
			var result := root.get_texture().get_image().save_png(path)
			assert(result == OK, "Cannot save " + path)
			captures += 1
		motion.call("set_motion_paused", false)
	level.free()
	print("L01 full-lane cue capture: %d images" % captures)
	quit(0)
