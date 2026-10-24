extends RefCounted

const Config = preload("res://scripts/session_config.gd")

# Local session log. Counts only: no names, identifiers, or free text.
static var history_path := "user://session_history.json"
static var csv_path := "user://session_history.csv"
const CSV_HEADER := "timestamp,route,end_reason,completed,target,speed_choice"


static func record(config, result, end_reason: StringName, timestamp: int = -1) -> bool:
	var completed := 0
	var target := 0
	for action in Config.ACTIONS:
		completed += result.get_completed(action)
		target += config.get_target(action)
	var entries := load_entries()
	entries.append({
		"timestamp": timestamp if timestamp >= 0 else int(Time.get_unix_time_from_system()),
		"route": String(config.selected_level_id),
		"end_reason": String(end_reason),
		"completed": completed,
		"target": target,
		"speed_choice": result.rpe,
	})
	var file := FileAccess.open(history_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(entries))
	return true


static func load_entries() -> Array:
	if not FileAccess.file_exists(history_path):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(history_path))
	if typeof(parsed) != TYPE_ARRAY:
		return []
	var entries: Array = []
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			item["timestamp"] = int(item.get("timestamp", 0))
			item["completed"] = int(item.get("completed", 0))
			item["target"] = int(item.get("target", 0))
			item["speed_choice"] = int(item.get("speed_choice", 0))
			entries.append(item)
	return entries


static func to_csv() -> String:
	var lines: PackedStringArray = [CSV_HEADER]
	for entry in load_entries():
		lines.append("%d,%s,%s,%d,%d,%d" % [
			entry["timestamp"], entry.get("route", ""), entry.get("end_reason", ""),
			entry["completed"], entry["target"], entry["speed_choice"]])
	return "\n".join(lines) + "\n"


static func export_csv() -> Error:
	var file := FileAccess.open(csv_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(to_csv())
	return OK


static func clear() -> void:
	if FileAccess.file_exists(history_path):
		DirAccess.remove_absolute(history_path)
