extends SceneTree

const AudioSettings = preload("res://scripts/menu_audio_settings.gd")
const DASHBOARD_SCENE := "res://scenes/main.tscn"
const RUNNER_SCENE := "res://scenes/levels/runner_level.tscn"
const AUDIO_FILES := [
	"res://art/audio/l01_barangay_ambience_v01.wav",
	"res://art/audio/l01_prompt_ready_v01.wav",
	"res://art/audio/l01_action_ack_v01.wav",
	"res://art/audio/l01_jump_v01.wav",
	"res://art/audio/l01_slide_v01.wav",
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
	await _test_distinct_action_sounds()
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
	var jump := level.get_node_or_null(^"GameplayAudio/JumpCue") as AudioStreamPlayer
	var slide := level.get_node_or_null(^"GameplayAudio/SlideCue") as AudioStreamPlayer
	var success := level.get_node_or_null(^"GameplayAudio/SuccessCue") as AudioStreamPlayer
	_expect(ambience != null and prompt != null and action != null and jump != null and slide != null and success != null, "Runner has separate ambience and movement cue players")
	if ambience == null or prompt == null or action == null or jump == null or slide == null or success == null:
		level.free()
		return
	_expect(ambience.stream != null and ambience.playing, "Gameplay ambience starts when the route starts")
	_expect(ambience.volume_db > -28.0 and ambience.volume_db < -12.0, "Default ambience is audible but quieter than menu music")
	_expect(prompt.volume_db > -24.0 and prompt.volume_db < -10.0, "Default prompt cue is audible but restrained")
	level.call("pause_gameplay")
	_expect(ambience.stream_paused and not prompt.playing and not action.playing and not jump.playing and not slide.playing and not success.playing, "Pause immediately silences gameplay audio")
	level.call("resume_gameplay")
	_expect(not ambience.stream_paused, "Resume continues the same ambience")
	AudioSettings.enabled = false
	if level.has_method("sync_audio_settings"):
		level.call("sync_audio_settings")
	_expect(ambience.stream_paused and jump.stream_paused and slide.stream_paused, "The shared Sound mute also silences gameplay")
	level.call("end_session_neutrally")
	_expect(not ambience.playing and not prompt.playing and not action.playing and not jump.playing and not slide.playing and not success.playing, "End Session stops all gameplay audio")
	level.free()


func _test_distinct_action_sounds() -> void:
	for action_name in [&"jump", &"slide"]:
		AudioSettings.enabled = true
		AudioSettings.volume = 35.0
		var level: Node = (load(RUNNER_SCENE) as PackedScene).instantiate()
		root.add_child(level)
		await process_frame
		var jump := level.get_node_or_null(^"GameplayAudio/JumpCue") as AudioStreamPlayer
		var slide := level.get_node_or_null(^"GameplayAudio/SlideCue") as AudioStreamPlayer
		if jump == null or slide == null:
			_expect(false, "Jump and Slide each have an original sound player")
			level.free()
			continue
		level.call("receive_input", action_name, true, 10.0)
		var intended := jump if action_name == &"jump" else slide
		var other := slide if action_name == &"jump" else jump
		_expect(intended.playing and not other.playing, "%s starts only its own cue on accepted input" % action_name)
		level.call("pause_gameplay")
		_expect(not intended.playing, "%s stops immediately on Pause" % action_name)
		level.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
