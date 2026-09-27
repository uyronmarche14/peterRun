extends SceneTree

## Setup, Controller Check and Ready: centred content-sized cards, balanced
## rows (no lopsided tile grid), one footer action row, and controller-aware hints.

const Store = preload("res://scripts/session_setup_store.gd")
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Store.reset()
	root.mode = Window.MODE_WINDOWED
	for dimensions in [Vector2i(1920, 1080), Vector2i(1024, 768)]:
		root.size = dimensions
		for screen_name in ["patient_setup", "controller_check", "ready"]:
			var screen: Control = load("res://scenes/%s.tscn" % screen_name).instantiate()
			root.add_child(screen)
			await process_frame
			await process_frame
			_check_centred(screen.get_node("Panel"), screen_name)
			_check_one_footer_row(screen, screen_name)
			match screen_name:
				"patient_setup":
					_check_setup(screen)
				"controller_check":
					_check_controller_tiles(screen)
			screen.free()
	Store.reset()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN setup screens layout test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_centred(card: Control, screen_name: String) -> void:
	var centre := card.get_global_rect().get_center()
	_expect(absf(centre.x - 240.0) <= 1.0, "%s card is horizontally centred (%.1f)" % [screen_name, centre.x])
	_expect(absf(centre.y - 135.0) <= 1.5, "%s card is vertically centred (%.1f)" % [screen_name, centre.y])
	_expect(card.get_global_rect().position.y >= 12.0, "%s card keeps a top margin (%.1f)" % [screen_name, card.get_global_rect().position.y])


func _check_one_footer_row(screen: Node, screen_name: String) -> void:
	var footer := screen.get_node_or_null("%Footer") as HBoxContainer
	_expect(footer != null, "%s has one footer action row" % screen_name)
	if footer == null:
		return
	var primary_count := 0
	for child in footer.get_children():
		if child is Button and child.theme_type_variation == &"PrimaryButton":
			primary_count += 1
	_expect(primary_count == 1, "%s footer has exactly one primary action" % screen_name)
	var last := footer.get_child(footer.get_child_count() - 1) as Button
	_expect(last != null and last.theme_type_variation == &"PrimaryButton", "%s primary action sits on the right" % screen_name)


func _check_setup(screen: Node) -> void:
	var side := screen.get_node("%AffectedSideOption") as Control
	var stepper := screen.get_node("%TargetRepetitionsSpinBox") as Control
	_expect(absf(side.get_global_rect().position.y - stepper.get_global_rect().position.y) <= 0.5, "Affected side and repetitions share one row")
	_expect(absf(side.size.x - stepper.size.x) <= 1.0, "Setup columns have equal width (%.1f vs %.1f)" % [side.size.x, stepper.size.x])
	_expect((screen.get_node("%SessionSummary") as Label).text.contains("40"), "Setup summarises the session total")


func _check_controller_tiles(screen: Node) -> void:
	var row := screen.get_node("%ActionTiles") as Container
	var content := screen.get_node("Panel/Margin/Content") as Control
	var widths: Array[float] = []
	for tile in row.get_children():
		widths.append((tile as Control).size.x)
		var tile_rect := (tile as Control).get_global_rect()
		for label in tile.find_children("*", "Label", true, false):
			var text_width: float = (label as Label).get_minimum_size().x
			_expect(text_width <= tile_rect.size.x, "%s text fits its tile" % label.get_path())
	_expect(widths.size() == 5, "Controller Check shows five action tiles in one row")
	if widths.size() == 5:
		_expect(widths.max() - widths.min() <= 1.0, "Action tiles share one width (%s)" % [widths])
	_expect(absf(row.size.x - content.size.x) <= 1.0, "Action tiles span the full card width")
	var detail := screen.get_node("%StatusDetail") as Label
	_expect(detail.get_line_count() == 1, "Controller hint stays on one line")


func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
