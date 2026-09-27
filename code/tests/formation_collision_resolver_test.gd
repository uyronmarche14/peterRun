extends SceneTree

const CollisionResolver = preload("res://scripts/formation_collision_resolver.gd")
const PromptDirectorModel = preload("res://scripts/prompt_director.gd")

var failures: PackedStringArray = []


func _init() -> void:
	_test_blocked_crate_lane_ends_the_run()
	_test_jump_clears_a_puddle_in_its_lane()
	_test_leaving_a_puddle_lane_avoids_collision()
	_test_slide_clears_a_laundry_line_in_its_lane()
	_finish()


func _test_blocked_crate_lane_ends_the_run() -> void:
	var formation := {
		"obstacles": [{"kind": &"crate", "lane": 1}],
	}
	_expect(CollisionResolver.player_hits_formation(formation, 1, PromptDirectorModel.Resolution.NEUTRAL_MISS), "Peter collides when a crate reaches his final lane")


func _test_jump_clears_a_puddle_in_its_lane() -> void:
	var formation := {
		"obstacles": [{"kind": &"puddle", "lane": 1}],
	}
	_expect(not CollisionResolver.player_hits_formation(formation, 1, PromptDirectorModel.Resolution.SUCCESS), "A correct jump clears a puddle at contact")
	_expect(CollisionResolver.player_hits_formation(formation, 1, PromptDirectorModel.Resolution.NEUTRAL_MISS), "An unresolved puddle contact ends the run")


func _test_leaving_a_puddle_lane_avoids_collision() -> void:
	var formation := {
		"obstacles": [{"kind": &"puddle", "lane": 1}],
	}
	_expect(not CollisionResolver.player_hits_formation(formation, 0, PromptDirectorModel.Resolution.NEUTRAL_MISS), "A player outside the obstacle lane does not collide")


func _test_slide_clears_a_laundry_line_in_its_lane() -> void:
	var formation := {
		"obstacles": [{"kind": &"laundry_line", "lane": 2}],
	}
	_expect(not CollisionResolver.player_hits_formation(formation, 2, PromptDirectorModel.Resolution.SUCCESS), "A correct slide clears a laundry line at contact")
	_expect(CollisionResolver.player_hits_formation(formation, 2, PromptDirectorModel.Resolution.NEUTRAL_MISS), "An unresolved laundry-line contact ends the run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN formation collision resolver test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
