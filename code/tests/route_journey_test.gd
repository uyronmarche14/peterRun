extends SceneTree

const JOURNEY_PATH := "res://scripts/route_journey.gd"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(ResourceLoader.exists(JOURNEY_PATH), "Route journey model exists")
	if ResourceLoader.exists(JOURNEY_PATH):
		var journey: Script = load(JOURNEY_PATH)
		_expect(journey != null and journey.has_method("get_hud_text"), "Route journey provides HUD text")
		if journey != null and journey.has_method("get_hud_text"):
			_expect(journey.get_hud_text(0) == "Journey: Home", "A route begins at Home")
			_expect(journey.get_hud_text(1) == "Journey: Waiting Shed", "First route progress reaches the waiting shed")
			_expect(journey.get_hud_text(2) == "Journey: Sari-sari Store", "Second route progress reaches the sari-sari store")
			_expect(journey.get_hud_text(9) == "Journey: Barangay Plaza", "Journey landmark text caps at the plaza")
			_expect(not journey.get_hud_text(2).contains("Clear") and not journey.get_hud_text(2).contains("Score"), "Journey text is not competitive scoring")
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN route journey test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
