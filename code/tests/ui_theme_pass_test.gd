extends SceneTree

var failures: PackedStringArray = []
var capture := false
const SCREENS := {
	"main": Vector2(200, 175), "patient_setup": Vector2(250, 205),
	"controller_check": Vector2(240, 160), "ready": Vector2(240, 160),
	"tutorial": Vector2(330, 235), "session_summary": Vector2(310, 220),
}


func _init() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	for dimensions in [Vector2i(1920, 1080), Vector2i(960, 540), Vector2i(1024, 768)]:
		root.size = dimensions
		for screen_name in SCREENS:
			var screen: Control = load("res://scenes/%s.tscn" % screen_name).instantiate()
			root.add_child(screen)
			current_scene = screen
			await create_timer(0.5 if screen_name == "main" else 0.05).timeout
			var card: Control = screen.get_node("Dashboard" if screen_name == "main" else "Panel")
			_check_card(card, SCREENS[screen_name])
			_check_controls(screen)
			if screen_name == "patient_setup":
				var stepper: SpinBox = screen.get_node("Panel/Margin/Content/TargetRepetitionsSpinBox")
				_expect(stepper.has_node("Stepper/Row/Increase"), "Repetition field offers full-size horizontal controls")
				if stepper.has_node("Stepper/Row/Increase"):
					stepper.value = 10
					stepper.get_node("Stepper/Row/Decrease").pressed.emit()
					_expect(stepper.value == 10, "Stepper retains minimum target")
					stepper.get_node("Stepper/Row/Increase").pressed.emit()
					_expect(stepper.value == 11, "Stepper increments the existing configuration value")
					stepper.value = 15
					stepper.get_node("Stepper/Row/Increase").pressed.emit()
					_expect(stepper.value == 15, "Stepper retains maximum target")
					stepper.value = 10
			if screen_name != "main":
				_expect(screen.has_node("BackdropArt"), screen_name + " carries the shared barangay setting")
			await _capture(screen_name, dimensions)
			if screen_name == "main":
				_expect(screen.get_node("Dashboard/Margin/Content/StartSessionButton").theme_type_variation == &"PrimaryButton", "Start has a distinct primary style")
				for mode in ["open_settings", "request_quit"]:
					screen.call(mode)
					await process_frame
					_check_card(screen.get_node("SettingsOverlay/Panel" if mode == "open_settings" else "QuitOverlay/Panel"), Vector2(190, 130))
					_check_controls(screen)
					await _capture(mode, dimensions)
					screen.call("close_overlays")
			screen.free()
		var runner: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
		root.add_child(runner)
		await process_frame
		_expect(runner.get_node("HUD/HUDRoot/TopBar").size.y <= 30, "HUD band is at most 120px high at 1080p")
		_expect(runner.get_node("HUD/HUDRoot").has_node("FooterBacking"), "Footer text has a consistent contrast surface")
		_check_controls(runner)
		await _capture("gameplay", dimensions)
		runner.call("pause_gameplay")
		_check_card(runner.get_node("PauseOverlay/Panel"), Vector2(180, 115))
		_check_controls(runner)
		await _capture("pause", dimensions)
		runner.call("request_end_session")
		_check_card(runner.get_node("EndConfirmation/Panel"), Vector2(200, 120))
		_check_controls(runner)
		await _capture("end_confirmation", dimensions)
		runner.call("confirm_end")
		_check_card(runner.get_node("EndSessionOverlay/Panel"), Vector2(200, 120))
		_check_controls(runner)
		await _capture("end_review", dimensions)
		runner.free()
	await create_timer(0.15).timeout
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN UI theme pass test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_card(card: Control, maximum: Vector2) -> void:
	_expect(card.size.x <= maximum.x + 1 and card.size.y <= maximum.y + 1, "Content-sized card: %s is %s; cap %s" % [card.get_path(), card.size, maximum])
	_expect(card.get_theme_stylebox("panel").resource_path == "res://art/ui/menu_card.tres", "Cards share one themed surface: " + str(card.get_path()))
	_check_inside(card, card.get_global_rect())


func _check_inside(node: Node, bounds: Rect2) -> void:
	if node is Control and node.is_visible_in_tree():
		_expect(bounds.grow(1).encloses(node.get_global_rect()), "Card contains " + str(node.get_path()))
	for child in node.get_children():
		_check_inside(child, bounds)


func _check_controls(node: Node) -> void:
	if node is Control and node.is_visible_in_tree():
		_expect(Rect2(0, 0, 480, 270).grow(1).encloses(node.get_global_rect()), "Viewport contains " + str(node.get_path()))
		if node is BaseButton:
			_expect(node.size.x >= 16 and node.size.y >= 16, "64px minimum target at 1080p: " + str(node.get_path()))
			_expect(node.size.y <= 20, "Compact button height: " + str(node.get_path()))
	for child in node.get_children():
		_check_controls(child)


func _capture(label: String, dimensions: Vector2i) -> void:
	if not capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://../test_evidence/ui_theme_%s_%dx%d.png" % [label, dimensions.x, dimensions.y]
	_expect(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK, "Save " + path)


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
