extends Control

const Review = preload("res://scripts/session_review_store.gd")
const Setup = preload("res://scripts/session_setup_store.gd")
const Config = preload("res://scripts/session_config.gd")
const LevelSelection = preload("res://scripts/level_selection.gd")
const ACTION_LABELS := ["Move left", "Move right", "Jump", "Slide"]
const ACTION_NODES := ["Left", "Right", "Jump", "Slide"]

var is_resting := false
var _leaving := false
var _result: Variant
var _config: Variant
var _level: Resource

@onready var content: VBoxContainer = $Panel/Margin/Content
@onready var retry_button: Button = $Panel/Margin/Content/Actions/RetryButton
@onready var finish_button: Button = $Panel/Margin/Content/Actions/FinishButton
@onready var status: Label = $Panel/Margin/Content/Status


func _ready() -> void:
	_result = Review.get_result()
	_config = Review.get_config()
	_level = LevelSelection.resolve(_config)
	var group := ButtonGroup.new()
	for rating in range(1, 11):
		var button := Button.new()
		button.name = "Rating%d" % rating
		button.text = str(rating)
		button.custom_minimum_size = Vector2(26, 24)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = "Record effort: %d out of 10" % rating
		button.disabled = _result == null
		button.pressed.connect(select_rating.bind(rating))
		content.get_node("Ratings").add_child(button)
	content.get_node("Actions/RestButton").pressed.connect(rest_session)
	retry_button.pressed.connect(retry_session)
	finish_button.pressed.connect(finish_session)
	if _result == null or _config == null:
		content.get_node("Title").text = "No session to review"
		content.get_node("Subtitle").text = "Return to the menu to set up a session."
		content.get_node("Repetitions").hide()
		content.get_node("Misses").hide()
		content.get_node("Actions/RestButton").disabled = true
		_refresh_rating()
		return
	match Review.get_end_reason():
		&"completed":
			content.get_node("Title").text = (_level.short_name + " complete") if _level != null else "Session review"
		&"level_ended":
			content.get_node("Title").text = "Level review"
		_:
			content.get_node("Title").text = "Session review"
	var side := "Left" if _config.affected_side == Config.AffectedSide.LEFT else "Right"
	content.get_node("Subtitle").text = "%s  ·  %s affected side" % [_level.title if _level != null else "Level unavailable", side]
	retry_button.text = ("Retry " + _level.short_name) if _level != null else "Retry"
	for index in range(Config.ACTIONS.size()):
		var action: StringName = Config.ACTIONS[index]
		content.get_node("Repetitions/" + ACTION_NODES[index]).text = "%s: %d / %d" % [
			ACTION_LABELS[index], _result.get_completed(action), _config.get_target(action)]
	content.get_node("Misses").text = "Neutral misses: %d" % _result.neutral_misses
	_refresh_rating()


func select_rating(value: Variant) -> bool:
	if _leaving or _result == null or not _result.set_rpe(value):
		return false
	_refresh_rating()
	return true


func _refresh_rating() -> void:
	var rating := int(_result.rpe) if _result != null else 0
	retry_button.disabled = rating == 0 or _level == null
	finish_button.text = "Finish without rating" if rating == 0 and _result != null else "Finish"
	content.get_node("Effort").text = "How much effort did it take?  %s" % (
		"Choose 1–10" if rating == 0 else "%d / 10" % rating)
	for button in content.get_node("Ratings").get_children():
		button.set_pressed_no_signal(int(button.text) == rating)
	if is_resting:
		status.text = "Rest as long as needed. Nothing starts automatically."
	elif rating == 0:
		status.text = "Record effort before retrying, or finish without a rating."
	else:
		status.text = "Discuss your effort with the therapist before retrying."


func rest_session() -> void:
	if _leaving or _result == null:
		return
	is_resting = true
	Review.set_decision(&"rest")
	_refresh_rating()


func retry_session() -> void:
	if _leaving or _result == null or _level == null or _result.rpe < 1 or _result.rpe > 10:
		return
	Setup.restore_session_config(_config)
	_navigate("res://scenes/ready.tscn", &"retry")


func finish_session() -> void:
	_navigate("res://scenes/main.tscn", &"finish")


func _navigate(path: String, decision: StringName) -> void:
	if _leaving:
		return
	_leaving = true
	if get_tree().change_scene_to_file(path) == OK:
		Review.set_decision(decision)
	else:
		_leaving = false
		status.text = "Could not open the next screen. Please try again."
