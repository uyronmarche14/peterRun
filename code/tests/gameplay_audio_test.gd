extends SceneTree

const AudioSettings = preload("res://scripts/menu_audio_settings.gd")
const DASHBOARD_SCENE := "res://scenes/main.tscn"
const RUNNER_SCENE := "res://scenes/levels/runner_level.tscn"
const AUDIO_FILES := [
	"res://art/audio/l01_barangay_ambience_v01.wav",
	"res://art/audio/l01_prompt_ready_v01.wav",
	"res://art/audio/l01_action_ack_v01.wav",
	"res://art/audio/l01_success_v01.wav",
]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var was_enabled: bool = AudioSettings.enabled
	var was_volume: float = AudioSettings.volume
	for path in AUDIO_FILES:
		_expect(ResourceLoader.exists(path), "Original gameplay audio imports: " + path)
	await _test_master_control()
	await _test_runner_pause_and_end()
	AudioSettings.enabled = was_enabled
	AudioSettings.volume = was_volume
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN gameplay audio test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_master_control() -> void:
	var dashboard: Node = (load(DASHBOARD_SCENE) as PackedScene).instantiate()
	root.add_child(dashboard)
	await process_frame
	var sound_button: Button = dashboard.get_node(^"MusicControl/Pill/Row/MusicButton")
	_expect(sound_button.tooltip_text.contains("Sound"), "Dashboard mute is clearly labeled Sound")
	dashboard.call("set_music_volume", 20.0)
	_expect(AudioSettings.volume == 20.0, "The existing slider remains the session-wide master volume")
	_expect(dashboard.get_node(^"SettingsOverlay/Panel/Margin/Content/VolumeLabel").text.contains("Sound"), "Settings names its master Sound control")
	dashboard.free()


func _test_runner_pause_and_end() -> void:
	AudioSettings.enabled = true
	AudioSettings.volume = 20.0
	var level: Node = (load(RUNNER_SCENE) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var ambience := level.get_node_or_null(^"GameplayAudio/Ambience") as AudioStreamPlayer
	var prompt := level.get_node_or_null(^"GameplayAudio/PromptCue") as AudioStreamPlayer
	var action := level.get_node_or_null(^"GameplayAudio/ActionCue") as AudioStreamPlayer
	var success := level.get_node_or_null(^"GameplayAudio/SuccessCue") as AudioStreamPlayer
	_expect(ambience != null and prompt != null and action != null and success != null, "Runner has separate ambience and positive cue players")
	if ambience == null or prompt == null or action == null or success == null:
		level.free()
		return
	_expect(ambience.stream != null and ambience.playing, "Gameplay ambience starts when the route starts")
	_expect(ambience.volume_db < -12.0, "Gameplay ambience stays quieter than menu music")
	level.call("pause_gameplay")
	_expect(ambience.stream_paused and not prompt.playing and not action.playing and not success.playing, "Pause immediately silences gameplay audio")
	level.call("resume_gameplay")
	_expect(not ambience.stream_paused, "Resume continues the same ambience")
	AudioSettings.enabled = false
	if level.has_method("sync_audio_settings"):
		level.call("sync_audio_settings")
	_expect(ambience.stream_paused, "The shared Sound mute also silences gameplay")
	level.call("end_session_neutrally")
	_expect(not ambience.playing and not prompt.playing and not action.playing and not success.playing, "End Session stops all gameplay audio")
	level.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
