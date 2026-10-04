class_name MainDashboard
extends Control

const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"
const CONTROLLER_CHECK_SCENE_PATH := "res://scenes/controller_check.tscn"
const AudioSettings = preload("res://scripts/menu_audio_settings.gd")
const GameSettings = preload("res://scripts/game_settings.gd")
const ControlHints = preload("res://scripts/control_hints.gd")
const MenuFocus = preload("res://scripts/menu_focus.gd")
const MUSIC_PATH := "res://art/audio/hakbang_sa_umaga.wav"

var _leaving := false
var _music_fade: Tween
var _opening_elapsed := 0.0

@onready var session_status: Label = $Dashboard/Margin/Content/SessionStatus
@onready var start_session_button: Button = $Dashboard/Margin/Content/StartSessionButton
@onready var tutorial_button: Button = $Dashboard/Margin/Content/SecondaryActions/TutorialButton
@onready var settings_button: Button = $Dashboard/Margin/Content/SecondaryActions/SettingsButton
@onready var quit_button: Button = $Dashboard/Margin/Content/SecondaryActions/QuitButton
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var music_button: Button = %MusicButton
@onready var music_control: Control = $MusicControl
@onready var character_mount: Node2D = $CharacterMount
@onready var settings_overlay: Control = $SettingsOverlay
@onready var quit_overlay: Control = $QuitOverlay
@onready var volume_slider: HSlider = $SettingsOverlay/Panel/Margin/Content/VolumeSlider
@onready var route_pace_option: OptionButton = $SettingsOverlay/Panel/Margin/Content/RoutePaceOption
@onready var effects_option: OptionButton = $SettingsOverlay/Panel/Margin/Content/EffectsOption
@onready var reduced_motion_toggle: Button = $SettingsOverlay/Panel/Margin/Content/ReducedMotionToggle
@onready var controller_check_button: Button = $SettingsOverlay/Panel/Margin/Content/ControllerCheckButton


func _ready() -> void:
	$CharacterMount/OpeningPlayer.set_resting_preview()
	start_session_button.pressed.connect(open_patient_setup)
	tutorial_button.pressed.connect(open_tutorial)
	settings_button.pressed.connect(open_settings)
	quit_button.pressed.connect(request_quit)

	music_button.pressed.connect(toggle_music)
	for button in [start_session_button, tutorial_button, settings_button, quit_button]:
		button.button_down.connect(_soften_button.bind(button))
		button.button_up.connect(_restore_button.bind(button))
	volume_slider.value_changed.connect(set_music_volume)
	route_pace_option.item_selected.connect(set_route_pace)
	effects_option.item_selected.connect(set_effects_intensity)
	reduced_motion_toggle.toggled.connect(set_reduced_motion)
	$SettingsOverlay/Panel/Margin/Content/CloseButton.pressed.connect(close_overlays)
	controller_check_button.pressed.connect(_open_controller_check_from_settings)
	$QuitOverlay/Panel/Margin/Content/CancelButton.pressed.connect(close_overlays)
	$QuitOverlay/Panel/Margin/Content/ConfirmButton.pressed.connect(confirm_quit)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh_safety_note()
	_start_music()
	_configure_route_pace()
	_configure_comfort_preferences()
	$Dashboard.modulate.a = 0.0
	create_tween().tween_property($Dashboard, "modulate:a", 1.0, 0.45)
	MenuFocus.focus(start_session_button)


func _unhandled_input(event: InputEvent) -> void:
	if not MenuFocus.is_back(event) or _leaving:
		return
	get_viewport().set_input_as_handled()
	if settings_overlay.visible or quit_overlay.visible:
		close_overlays()
	else:
		request_quit()



func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh_safety_note()


func _refresh_safety_note() -> void:
	var source := ControlHints.menu_hint(true) if ControlHints.uses_gamepad() else "Keyboard or MOVE controller"
	$Dashboard/Margin/Content/SafetyNote.text = "Supervised session · " + source


func _process(delta: float) -> void:
	if GameSettings.reduced_motion:
		character_mount.position.y = 0.0
		return
	_opening_elapsed = fmod(_opening_elapsed + delta, TAU)
	character_mount.position.y = sin(_opening_elapsed * 1.15) * 0.7


func _soften_button(button: Button) -> void:
	if GameSettings.reduced_motion:
		return
	var tween := create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 0.90, 0.67, 1.0), 0.07)


func _restore_button(button: Button) -> void:
	if GameSettings.reduced_motion:
		return
	var tween := create_tween()
	tween.tween_property(button, "modulate", Color.WHITE, 0.16)


func get_patient_setup_scene_path() -> String:
	return PATIENT_SETUP_SCENE_PATH


func get_tutorial_scene_path() -> String:
	return TUTORIAL_SCENE_PATH


func get_controller_check_scene_path() -> String:
	return CONTROLLER_CHECK_SCENE_PATH


func open_patient_setup() -> void:
	if _leaving or settings_overlay.visible or quit_overlay.visible:
		return
	var result := get_tree().change_scene_to_file(PATIENT_SETUP_SCENE_PATH)
	if result != OK:
		_show_status("Unable to open Patient Setup. Please restart the app.")
	else:
		_leaving = true


func open_tutorial() -> void:
	if _leaving or settings_overlay.visible or quit_overlay.visible:
		return
	var result := get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)
	if result != OK:
		_show_status("Unable to open Tutorial. Please restart the app.")
	else:
		_leaving = true


# The status line only takes space when there is something to report.
func _show_status(message: String) -> void:
	session_status.text = message
	session_status.visible = not message.is_empty()


func show_coming_soon(message: String) -> void:
	_show_status(message)


func open_settings() -> void:
	if not _leaving and not quit_overlay.visible:
		settings_overlay.show()
		MenuFocus.focus($SettingsOverlay/Panel/Margin/Content/CloseButton)


func request_quit() -> void:
	if not _leaving and not settings_overlay.visible:
		quit_overlay.show()
		MenuFocus.focus($QuitOverlay/Panel/Margin/Content/CancelButton)


func close_overlays() -> void:
	settings_overlay.hide()
	quit_overlay.hide()
	MenuFocus.focus(start_session_button)


func _open_controller_check_from_settings() -> void:
	if _leaving:
		return
	var result := get_tree().change_scene_to_file(CONTROLLER_CHECK_SCENE_PATH)
	if result != OK:
		_show_status("Unable to open Controller Check. Please restart the app.")
		return
	_leaving = true


func confirm_quit() -> void:
	if quit_overlay.visible and not _leaving:
		_leaving = true
		menu_music.stop()
		# A busy frame can consume a newly created SceneTreeTimer immediately.
		# Give the audio thread actual wall time, without blocking the UI thread.
		var release_at := Time.get_ticks_msec() + 150
		while Time.get_ticks_msec() < release_at:
			await get_tree().process_frame
		get_tree().quit()


func _start_music() -> void:
	if ResourceLoader.exists(MUSIC_PATH):
		menu_music.stream = load(MUSIC_PATH) as AudioStreamWAV
	if menu_music.stream == null:
		music_button.disabled = true
		music_button.tooltip_text = "Music unavailable"
		volume_slider.editable = false
		return
	var track := menu_music.stream as AudioStreamWAV
	track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	track.loop_begin = 0
	# Imported WAVs may use compression; byte length is not a PCM frame count.
	track.loop_end = int(round(track.get_length() * track.mix_rate))
	set_music_volume(AudioSettings.volume)
	var target_db := menu_music.volume_db
	menu_music.volume_db = -60.0
	menu_music.play()
	menu_music.stream_paused = not AudioSettings.enabled
	_music_fade = create_tween()
	_music_fade.tween_property(menu_music, "volume_db", target_db, 1.2)
	_update_music_label()


func set_music_volume(value: float) -> void:
	if not is_finite(value):
		return
	AudioSettings.volume = clampf(value, 0.0, 100.0)
	if _music_fade != null:
		_music_fade.kill()
	menu_music.volume_db = -80.0 if AudioSettings.volume == 0.0 else linear_to_db(AudioSettings.volume / 100.0) - 12.0
	volume_slider.set_value_no_signal(AudioSettings.volume)
	$SettingsOverlay/Panel/Margin/Content/VolumeLabel.text = "Menu music · %d%%" % int(AudioSettings.volume)


func _configure_route_pace() -> void:
	route_pace_option.clear()
	route_pace_option.add_item("Route pace: Calm", 0)
	route_pace_option.add_item("Route pace: Standard", 1)
	route_pace_option.add_item("Route pace: Lively", 2)
	var selected := 0 if is_equal_approx(GameSettings.visual_pace, GameSettings.CALM_PACE) else 2 if is_equal_approx(GameSettings.visual_pace, GameSettings.LIVELY_PACE) else 1
	route_pace_option.select(selected)
	_update_route_pace_label()


func set_route_pace(index: int) -> void:
	match index:
		0: GameSettings.set_visual_pace(GameSettings.CALM_PACE)
		2: GameSettings.set_visual_pace(GameSettings.LIVELY_PACE)
		_: GameSettings.set_visual_pace(GameSettings.STANDARD_PACE)
	_update_route_pace_label()


func _update_route_pace_label() -> void:
	$SettingsOverlay/Panel/Margin/Content/RoutePaceLabel.text = "Route pace · %s (visual only)" % GameSettings.get_pace_label()


func _configure_comfort_preferences() -> void:
	effects_option.clear()
	effects_option.add_item("Effects: Subtle", 0)
	effects_option.add_item("Effects: Standard", 1)
	effects_option.select(0 if is_equal_approx(GameSettings.effects_intensity, 0.5) else 1)
	reduced_motion_toggle.button_pressed = GameSettings.reduced_motion
	_update_comfort_labels()


func set_effects_intensity(index: int) -> void:
	GameSettings.set_effects_intensity(0.5 if index == 0 else 1.0)
	_update_comfort_labels()


func set_reduced_motion(enabled: bool) -> void:
	GameSettings.set_reduced_motion(enabled)
	_update_comfort_labels()


func _update_comfort_labels() -> void:
	var intensity_label := "Subtle" if is_equal_approx(GameSettings.effects_intensity, 0.5) else "Standard"
	$SettingsOverlay/Panel/Margin/Content/EffectsLabel.text = "Contact effects - %s" % intensity_label
	reduced_motion_toggle.text = "Reduced motion: %s" % ("On" if GameSettings.reduced_motion else "Off")


func toggle_music() -> void:
	if menu_music.stream == null:
		return
	AudioSettings.enabled = not AudioSettings.enabled
	menu_music.stream_paused = not AudioSettings.enabled
	_update_music_label()


func _update_music_label() -> void:
	music_button.tooltip_text = "Music on · click to mute" if AudioSettings.enabled else "Music off · click to play"
	# Dim the whole control when muted; the tooltip carries the state in words.
	music_control.modulate.a = 1.0 if AudioSettings.enabled else 0.55


func _exit_tree() -> void:
	if is_instance_valid(menu_music):
		menu_music.stop()
