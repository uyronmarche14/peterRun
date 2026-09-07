class_name MainDashboard
extends Control

const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"
const AudioSettings = preload("res://scripts/menu_audio_settings.gd")
const MUSIC_PATH := "res://art/audio/hakbang_sa_umaga.wav"

var _leaving := false
var _music_fade: Tween

@onready var session_status: Label = $Dashboard/Margin/Content/SessionStatus
@onready var start_session_button: Button = $Dashboard/Margin/Content/StartSessionButton
@onready var tutorial_button: Button = $Dashboard/Margin/Content/SecondaryActions/TutorialButton
@onready var settings_button: Button = $Dashboard/Margin/Content/SecondaryActions/SettingsButton
@onready var quit_button: Button = $Dashboard/Margin/Content/SecondaryActions/QuitButton
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var music_button: Button = $MusicButton
@onready var settings_overlay: Control = $SettingsOverlay
@onready var quit_overlay: Control = $QuitOverlay
@onready var volume_slider: HSlider = $SettingsOverlay/Panel/Margin/Content/VolumeSlider


func _ready() -> void:
	start_session_button.pressed.connect(open_patient_setup)
	tutorial_button.pressed.connect(open_tutorial)
	settings_button.pressed.connect(open_settings)
	quit_button.pressed.connect(request_quit)
	music_button.pressed.connect(toggle_music)
	volume_slider.value_changed.connect(set_music_volume)
	$SettingsOverlay/Panel/Margin/Content/CloseButton.pressed.connect(close_overlays)
	$SettingsOverlay/Panel/Margin/Content/SetupButton.pressed.connect(_open_setup_from_settings)
	$QuitOverlay/Panel/Margin/Content/CancelButton.pressed.connect(close_overlays)
	$QuitOverlay/Panel/Margin/Content/ConfirmButton.pressed.connect(confirm_quit)
	_start_music()
	$Dashboard.modulate.a = 0.0
	create_tween().tween_property($Dashboard, "modulate:a", 1.0, 0.45)


func get_patient_setup_scene_path() -> String:
	return PATIENT_SETUP_SCENE_PATH


func get_tutorial_scene_path() -> String:
	return TUTORIAL_SCENE_PATH


func open_patient_setup() -> void:
	if _leaving or settings_overlay.visible or quit_overlay.visible:
		return
	var result := get_tree().change_scene_to_file(PATIENT_SETUP_SCENE_PATH)
	if result != OK:
		session_status.text = "Unable to open Patient Setup. Please restart the app."
	else:
		_leaving = true


func open_tutorial() -> void:
	if _leaving or settings_overlay.visible or quit_overlay.visible:
		return
	var result := get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)
	if result != OK:
		session_status.text = "Unable to open Tutorial. Please restart the app."
	else:
		_leaving = true


func show_coming_soon(message: String) -> void:
	session_status.text = message


func open_settings() -> void:
	if not _leaving and not quit_overlay.visible:
		settings_overlay.show()


func request_quit() -> void:
	if not _leaving and not settings_overlay.visible:
		quit_overlay.show()


func close_overlays() -> void:
	settings_overlay.hide()
	quit_overlay.hide()


func _open_setup_from_settings() -> void:
	close_overlays()
	open_patient_setup()


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
		music_button.text = "Music unavailable"
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


func toggle_music() -> void:
	if menu_music.stream == null:
		return
	AudioSettings.enabled = not AudioSettings.enabled
	menu_music.stream_paused = not AudioSettings.enabled
	_update_music_label()


func _update_music_label() -> void:
	music_button.text = "Music: On" if AudioSettings.enabled else "Music: Off"


func _exit_tree() -> void:
	if is_instance_valid(menu_music):
		menu_music.stop()
