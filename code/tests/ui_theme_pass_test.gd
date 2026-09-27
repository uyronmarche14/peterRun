extends SceneTree

var failures: PackedStringArray = []
var capture := false
const COMPACT_THEME_PATH := "res://art/ui/compact_theme.tres"
const SCREENS := {
	"main": Vector2(205, 195), "patient_setup": Vector2(340, 265),
	"controller_check": Vector2(340, 255), "ready": Vector2(320, 200),
	"tutorial": Vector2(330, 235), "session_summary": Vector2(310, 220),
}


func _init() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	_check_game_font()
	_check_effort_rating_theme()
	for dimensions in [Vector2i(1920, 1080), Vector2i(960, 540), Vector2i(1024, 768)]:
		root.size = dimensions
		for screen_name in SCREENS:
			var screen: Control = load("res://scenes/%s.tscn" % screen_name).instantiate()
			root.add_child(screen)
			current_scene = screen
			await create_timer(0.5 if screen_name == "main" else 0.05).timeout
			var card: Control = screen.get_node("Dashboard" if screen_name == "main" else "Panel")
			_check_card(card, SCREENS[screen_name], "res://art/ui/dashboard_route_card.tres" if screen_name == "main" else "res://art/ui/menu_card.tres")
			_check_controls(screen)
			if screen_name == "patient_setup":
				var stepper: SpinBox = screen.get_node("Panel/Margin/Content/TargetRepetitionsSpinBox")
				_expect(stepper.has_node("Stepper/Row/Increase"), "Repetition field offers full-size horizontal controls")
				if stepper.has_node("Stepper/Row/Increase"):
					stepper.value = 1
					stepper.get_node("Stepper/Row/Decrease").pressed.emit()
					_expect(stepper.value == 1, "Stepper retains the customizable minimum target")
					await _click(stepper.get_node("Stepper/Row/Increase"))
					_expect(stepper.value == 2, "Stepper increments the customizable target")
					stepper.value = 15
					stepper.get_node("Stepper/Row/Increase").pressed.emit()
					_expect(stepper.value == 15, "Stepper retains maximum target")
					stepper.value = 1
			if screen_name != "main":
				_expect(screen.has_node("BackdropArt"), screen_name + " carries the shared barangay setting")
			await _capture(screen_name, dimensions)
			if screen_name == "main":
				_expect(screen.get_node("Dashboard/Margin/Content/StartSessionButton").theme_type_variation == &"PrimaryButton", "Start has a distinct primary style")
				for mode in ["open_settings", "request_quit"]:
					screen.call(mode)
					await process_frame
					_check_card(screen.get_node("SettingsOverlay/Panel" if mode == "open_settings" else "QuitOverlay/Panel"), Vector2(190, 180 if mode == "open_settings" else 130), "res://art/ui/menu_card.tres")
					if mode == "open_settings":
						_check_settings_spacing(screen)
					_check_controls(screen)
					await _capture(mode, dimensions)
					screen.call("close_overlays")
			screen.free()
		var runner: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
		root.add_child(runner)
		await process_frame
		_check_gameplay_hud(runner)
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
		var review: Control = load("res://scenes/session_summary.tscn").instantiate()
		root.add_child(review)
		await process_frame
		_check_effort_rating_buttons(review)
		for rating in [1, 10]:
			review.call("select_rating", rating)
			await process_frame
			_check_card(review.get_node("Panel"), SCREENS["session_summary"])
			_check_controls(review)
		review.call("rest_session")
		await process_frame
		_check_card(review.get_node("Panel"), SCREENS["session_summary"])
		await _capture("review_rated_rest", dimensions)
		review.free()
	await create_timer(0.15).timeout
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN UI theme pass test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_game_font() -> void:
	var compact_theme := load(COMPACT_THEME_PATH) as Theme
	_expect(compact_theme != null, "Compact UI theme loads")
	if compact_theme == null:
		return
	_expect(compact_theme.default_font is SystemFont, "UI uses a readable system-font stack instead of the bundled display font")
	if compact_theme.default_font is SystemFont:
		var font := compact_theme.default_font as SystemFont
		_expect(font.font_names.has("Trebuchet MS"), "UI font stack starts with the friendly Trebuchet face")


func _check_effort_rating_theme() -> void:
	var compact_theme := load(COMPACT_THEME_PATH) as Theme
	if compact_theme == null:
		return
	var normal := compact_theme.get_stylebox("normal", &"EffortRatingButton") as StyleBoxFlat
	var hover := compact_theme.get_stylebox("hover", &"EffortRatingButton") as StyleBoxFlat
	var selected := compact_theme.get_stylebox("pressed", &"EffortRatingButton") as StyleBoxFlat
	_expect(normal != null and hover != null and selected != null, "Effort ratings use dedicated normal, hover, and selected surfaces")
	if normal != null and hover != null:
		_expect(normal.bg_color != hover.bg_color, "Effort-rating hover has a visibly distinct background")
		var hover_font := compact_theme.get_color("font_hover_color", &"EffortRatingButton")
		_expect(hover_font.r > 0.85 and hover_font.g > 0.85 and hover_font.b > 0.75, "Effort-rating hover uses a light foreground on its stronger surface")


func _check_effort_rating_buttons(review: Control) -> void:
	for rating in review.get_node("Panel/Margin/Content/Ratings").get_children():
		_expect(rating.theme_type_variation == &"EffortRatingButton", "Each effort rating uses the dedicated rating-button treatment")


func _check_settings_spacing(screen: Control) -> void:
	var margin := screen.get_node("SettingsOverlay/Panel/Margin") as MarginContainer
	var content := margin.get_node("Content") as VBoxContainer
	_expect(margin.get_theme_constant("margin_top") >= 8 and margin.get_theme_constant("margin_bottom") >= 8, "Settings card keeps comfortable vertical padding")
	_expect(content.get_theme_constant("separation") >= 3, "Settings controls have clear vertical spacing")


func _check_card(card: Control, maximum: Vector2, expected_surface: String = "res://art/ui/menu_card.tres") -> void:
	_expect(card.size.x <= maximum.x + 1 and card.size.y <= maximum.y + 1, "Content-sized card: %s is %s; cap %s" % [card.get_path(), card.size, maximum])
	_expect(card.get_theme_stylebox("panel").resource_path == expected_surface, "Cards use the intended themed surface: " + str(card.get_path()))
	_check_inside(card, card.get_global_rect())
	if root.size == Vector2i(1920, 1080):
		print("UI SIZE %s: %s native" % [card.get_path(), card.size])


func _click(button: Control) -> void:
	var pointer := InputEventMouseMotion.new()
	pointer.position = button.get_global_rect().get_center()
	root.push_input(pointer, true)
	var click := InputEventMouseButton.new()
	click.position = pointer.position
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, true)
	await process_frame


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


func _check_gameplay_hud(runner: Node) -> void:
	var hud_root := runner.get_node("HUD/HUDRoot") as Control
	var header := hud_root.get_node("TopBar") as Control
	var footer := hud_root.get_node("FooterBacking") as Control
	var prompt := hud_root.get_node("PromptCard") as Control
	var pause_button := hud_root.get_node("PauseButton") as BaseButton
	_expect(header.size.y <= 30, "Gameplay status surface remains compact")
	_expect(header.position.x > 0 and header.size.x < hud_root.size.x, "Gameplay status surface floats clear of both screen edges")
	_expect(footer.position.x > 0 and footer.size.x < hud_root.size.x, "Gameplay control tray floats clear of both screen edges")
	_expect(footer.size.y <= 20, "Gameplay control tray remains compact")
	_expect(prompt.is_visible_in_tree() and prompt.size.x > 0, "Active action prompt remains visible")
	_expect(pause_button.is_visible_in_tree() and pause_button.size.x >= 16, "Pause remains visible and reachable")


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
