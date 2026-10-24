extends SceneTree

const HistoryStore = preload("res://scripts/session_history_store.gd")
const Config = preload("res://scripts/session_config.gd")
const Result = preload("res://scripts/session_result.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	HistoryStore.history_path = "user://test_sessions_history.json"
	HistoryStore.csv_path = "user://test_sessions_history.csv"
	HistoryStore.clear()

	_expect(HistoryStore.load_entries().is_empty(), "history starts empty")

	var config := Config.new()
	config.set_target(&"jump", 4)
	var result := Result.new()
	result.record_success(&"jump")
	result.record_success(&"jump")
	result.record_success(&"move_left")
	result.neutral_misses = 2
	result.rpe = 7
	HistoryStore.record(config, result, &"collision", 1234567890)
	var entries := HistoryStore.load_entries()
	_expect(entries.size() == 1, "one entry saved")
	var entry: Dictionary = entries[0]
	_expect(entry["timestamp"] == 1234567890, "timestamp saved")
	_expect(entry["route"] == "l01_barangay", "route id saved")
	_expect(entry["end_reason"] == "collision", "end reason saved")
	_expect(entry["completed"] == 3, "completed total saved")
	_expect(entry["target"] == 4 + 30, "target total saved (jump 4 + 3 x 10)")
	_expect(entry["speed_choice"] == 7, "speed choice saved")
	_expect(not entry.has("name") and not entry.has("patient"), "no identifiers are stored")

	HistoryStore.record(config, result, &"completed", 1234567999)
	_expect(HistoryStore.load_entries().size() == 2, "entries append")

	var csv := HistoryStore.to_csv()
	var lines: PackedStringArray = csv.strip_edges().split("\n")
	_expect(lines.size() == 3, "csv has header plus two rows (got %d)" % lines.size())
	_expect(lines[0] == "timestamp,route,end_reason,completed,target,speed_choice", "csv header")
	_expect(HistoryStore.export_csv() == OK and FileAccess.file_exists(HistoryStore.csv_path), "csv exported to a file")

	HistoryStore.clear()
	_expect(HistoryStore.load_entries().is_empty(), "clear removes history")
	DirAccess.remove_absolute(HistoryStore.csv_path)
	_finish()


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN session history store test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("FAIL: " + failure)
	quit(1)
