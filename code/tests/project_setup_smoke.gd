extends SceneTree

const REQUIRED_ACTIONS := ["move_left", "move_right", "jump", "slide", "pause_session"]
const REQUIRED_PATHS := [
	"res://scenes/main.tscn",
	"res://art/_references/comfyui_prompts",
	"res://art/_references/comfyui_workflows",
	"res://art/_references/l01_barangay",
	"res://data/levels",
	"res://scripts",
]


func _init() -> void:
	var failures: PackedStringArray = []

	for action_name in REQUIRED_ACTIONS:
		if not InputMap.has_action(action_name):
			failures.append("Missing InputMap action: %s" % action_name)
		elif InputMap.action_get_events(action_name).is_empty():
			failures.append("InputMap action has no event: %s" % action_name)

	for project_path in REQUIRED_PATHS:
		var absolute_path := ProjectSettings.globalize_path(project_path)
		if project_path.ends_with(".tscn"):
			if not FileAccess.file_exists(project_path):
				failures.append("Missing required file: %s" % project_path)
		elif not DirAccess.dir_exists_absolute(absolute_path):
			failures.append("Missing required directory: %s" % project_path)

	if failures.is_empty():
		print("PETER RUN project setup smoke test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)
