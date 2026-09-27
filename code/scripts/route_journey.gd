class_name RouteJourney
extends RefCounted

const LANDMARKS := ["Home", "Waiting Shed", "Sari-sari Store", "Barangay Plaza"]


static func get_landmark(route_progress: int) -> String:
	return LANDMARKS[clampi(route_progress, 0, LANDMARKS.size() - 1)]


static func get_progress(completed_repetitions: int, target_repetitions: int) -> int:
	if completed_repetitions <= 0 or target_repetitions <= 0:
		return 0
	var capped_completed := mini(completed_repetitions, target_repetitions)
	return floori(float(capped_completed * (LANDMARKS.size() - 1)) / float(target_repetitions))


static func get_hud_text(route_progress: int) -> String:
	return "Journey: " + get_landmark(route_progress)


static func get_summary_text(route_progress: int) -> String:
	return "Journey landmark: " + get_landmark(route_progress)
