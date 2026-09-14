class_name RouteJourney
extends RefCounted

const LANDMARKS := ["Home", "Waiting Shed", "Sari-sari Store", "Barangay Plaza"]


static func get_landmark(route_progress: int) -> String:
	return LANDMARKS[clampi(route_progress, 0, LANDMARKS.size() - 1)]


static func get_hud_text(route_progress: int) -> String:
	return "Journey: " + get_landmark(route_progress)


static func get_summary_text(route_progress: int) -> String:
	return "Journey landmark: " + get_landmark(route_progress)
