class_name RouteJourney
extends RefCounted

const LANDMARKS := ["Home", "Waiting Shed", "Sari-sari Store", "Palengke Approach", "Barangay Plaza"]
const STAMP_INDICES := [0, 1, 2, 2, 3]


static func get_landmark(route_progress: int) -> String:
	return LANDMARKS[clampi(route_progress, 0, LANDMARKS.size() - 1)]


static func get_progress(completed_repetitions: int, target_repetitions: int) -> int:
	if completed_repetitions <= 0 or target_repetitions <= 0:
		return 0
	var capped_completed := mini(completed_repetitions, target_repetitions)
	var fraction := float(capped_completed) / float(target_repetitions)
	if fraction >= 0.9:
		return 4
	if fraction >= 0.75:
		return 3
	if fraction >= 0.5:
		return 2
	if fraction >= 0.25:
		return 1
	return 0


static func get_hud_text(route_progress: int) -> String:
	return "Journey: " + get_landmark(route_progress)


static func get_summary_text(route_progress: int) -> String:
	return "Journey landmark: " + get_landmark(route_progress)


static func get_stamp_index(route_progress: int) -> int:
	return STAMP_INDICES[clampi(route_progress, 0, STAMP_INDICES.size() - 1)]
