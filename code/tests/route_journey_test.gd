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
			_expect(journey.get_hud_text(3) == "Journey: Palengke Approach", "Third route progress reaches the market approach")
			_expect(journey.get_hud_text(4) == "Journey: Barangay Plaza", "Final route progress reaches the plaza")
			_expect(journey.get_hud_text(9) == "Journey: Barangay Plaza", "Journey landmark text caps at the plaza")
			_expect(not journey.get_hud_text(2).contains("Clear") and not journey.get_hud_text(2).contains("Score"), "Journey text is not competitive scoring")
		_expect(journey != null and journey.has_method("get_progress"), "Route journey derives landmarks from completed repetitions")
		if journey != null and journey.has_method("get_progress"):
			_expect(journey.get_progress(0, 40) == 0, "No completed movement remains at Home")
			_expect(journey.get_progress(9, 40) == 0, "Home persists until the first stage threshold")
			_expect(journey.get_progress(10, 40) == 1, "Ten of forty planned movements reach the waiting shed")
			_expect(journey.get_progress(20, 40) == 2, "Twenty of forty reach the sari-sari store")
			_expect(journey.get_progress(30, 40) == 3, "Thirty of forty reach the market approach")
			_expect(journey.get_progress(35, 40) == 3, "Market approach remains visible before plaza arrival")
			_expect(journey.get_progress(36, 40) == 4, "Plaza is visible before the session completes")
			_expect(journey.get_progress(40, 40) == 4, "All planned movements remain at the plaza")
			_expect(journey.get_progress(0, 0) == 0, "An empty test session remains at Home")
		_expect(journey != null and journey.has_method("get_stamp_index"), "Route journey maps five stages onto the four existing summary stamps")
		if journey != null and journey.has_method("get_stamp_index"):
			_expect(journey.get_stamp_index(3) == 2, "Market approach keeps the market/shop stamp")
			_expect(journey.get_stamp_index(4) == 3, "Plaza uses the Hall stamp")
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN route journey test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
