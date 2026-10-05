extends SceneTree

const FLOW_BACKDROP := "res://art/backgrounds/ui_barangay_flow_v01.png"
const SUMMARY_BACKDROP := "res://art/backgrounds/ui_barangay_plaza_review_v01.png"
const FRAME_PATHS := [
	"res://art/ui/menu_card.tres",
	"res://art/ui/dashboard_route_card.tres",
	"res://art/ui/route_ticket.tres",
]
const FLOW_SCREENS := ["patient_setup", "controller_check", "tutorial", "ready"]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_backdrop_resource(FLOW_BACKDROP)
	_check_backdrop_resource(SUMMARY_BACKDROP)
	for screen_name in FLOW_SCREENS:
		await _check_screen(screen_name, FLOW_BACKDROP)
	await _check_screen("session_summary", SUMMARY_BACKDROP)
	for path in FRAME_PATHS:
		_check_frame(path)
	_check_gameplay_hud()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN UI image unification test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_backdrop_resource(path: String) -> void:
	if not ResourceLoader.exists(path):
		failures.append("Illustrated backdrop exists: " + path)
		return
	var texture := load(path) as Texture2D
	_expect(texture != null and texture.get_size() == Vector2(960, 540), "Illustrated backdrop is 960x540: " + path)


func _check_screen(screen_name: String, expected_path: String) -> void:
	var screen: Control = load("res://scenes/%s.tscn" % screen_name).instantiate()
	root.add_child(screen)
	await process_frame
	var backdrop := screen.get_node_or_null(^"BackdropArt") as TextureRect
	_expect(backdrop != null, screen_name + " uses an image-backed TextureRect")
	if backdrop != null:
		_expect(backdrop.texture != null and backdrop.texture.resource_path == expected_path, screen_name + " uses its approved backdrop")
		_expect(backdrop.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, screen_name + " preserves background aspect ratio")
		_expect(backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE, screen_name + " backdrop cannot block controls")
	var card := screen.get_node_or_null(^"Panel") as Control
	_expect(card != null and card.get_theme_stylebox("panel") is StyleBoxTexture, screen_name + " has an image-backed card frame")
	screen.free()


func _check_frame(path: String) -> void:
	var frame := load(path) as StyleBoxTexture
	_expect(frame != null and frame.texture != null, "Nine-slice frame loads: " + path)


func _check_gameplay_hud() -> void:
	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	for node_path in [^"HUD/HUDRoot/TopBar", ^"HUD/HUDRoot/PromptCard", ^"HUD/HUDRoot/FooterBacking"]:
		var panel := level.get_node(node_path) as Panel
		_expect(panel.get_theme_stylebox("panel") is StyleBoxTexture, "HUD frame uses image-backed art: " + str(node_path))
	_expect(level.get_node(^"HUD/HUDRoot/PauseButton") is Button, "Pause remains a live button")
	_expect(level.get_node(^"HUD/HUDRoot/PromptActionLabel") is Label, "Prompt wording remains live text")
	level.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
