class_name RunnerLevelController
extends Node2D

const InputAdapterModel = preload("res://scripts/input_adapter.gd")

signal named_action_received(action_name: StringName)

var input_adapter := InputAdapterModel.new()

@onready var player: PlayerController = $Player


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventAction:
		return
	if not InputAdapterModel.ACCEPTED_ACTIONS.has(event.action):
		return

	receive_input(event.action, event.pressed, Time.get_ticks_msec() / 1000.0)
	get_viewport().set_input_as_handled()


func receive_input(source_action: StringName, pressed: bool, now_seconds: float) -> void:
	if not pressed:
		input_adapter.release_action(source_action)
		return

	var logical_action := input_adapter.accept_action(source_action, now_seconds)
	if logical_action == &"":
		return

	named_action_received.emit(logical_action)
	player.handle_action(logical_action)
