extends SceneTree

const ACTIONS := [&"move_left", &"move_right", &"jump", &"slide"]
const ICON_PATHS := [
	"res://art/ui/action_icons/move_left.svg",
	"res://art/ui/action_icons/move_right.svg",
	"res://art/ui/action_icons/jump.svg",
	"res://art/ui/action_icons/slide.svg",
]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in ICON_PATHS:
		_expect(ResourceLoader.exists(path), "Shared action icon exists: " + path)
	var tutorial: Control = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	await process_frame
	var preview := tutorial.get_node_or_null("Panel/Margin/Content/Welcome/MovementPreviewGrid") as GridContainer
	_expect(preview != null and preview.columns == 2 and preview.get_child_count() == 4,
		"Welcome previews all four actions in a two-column grid")
	if preview != null:
		for cell in preview.get_children():
			_expect(cell is HBoxContainer and cell.get_node_or_null("Icon") is TextureRect and cell.get_node_or_null("Action") is Label,
				"Every welcome preview has a shared icon and a readable action word")
	_expect(tutorial.get_node("Panel/Margin/Content/Welcome/Actions/ShowFirstDemoButton").visible,
		"Show me first remains available")
	tutorial.free()

	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var prompt := level.get_node("HUD/HUDRoot/PromptCard") as Control
	var icon := level.get_node_or_null("HUD/HUDRoot/PromptCard/ActionIcon") as TextureRect
	_expect(prompt.size.x >= 150 and prompt.size.y <= 28, "Prompt sign is wider but does not grow over the Hall")
	_expect(icon != null, "Gameplay prompt displays the shared action icon")
	if icon != null:
		for action in ACTIONS:
			level.call("_update_prompt_card", action, "GET READY", Color.WHITE)
			_expect(icon.visible and icon.texture != null, "Prompt icon is shown for " + str(action))
	level.free()

	var summary: Control = load("res://scenes/session_summary.tscn").instantiate()
	root.add_child(summary)
	await process_frame
	var card := summary.get_node("Panel") as Control
	var ratings := summary.get_node("Panel/Margin/Content/Ratings") as GridContainer
	_expect(card.size.x <= 360 and card.size.y <= 250, "Review card remains within focused size cap")
	_expect(ratings != null and ratings.columns == 5 and ratings.get_child_count() == 10,
		"Effort ratings form two rows of five")
	if ratings != null:
		for button in ratings.get_children():
			_expect(button.size.x >= 24 and button.size.y >= 24, "Effort rating has a 24 px native target")
	summary.free()

	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN focused screen readability test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
