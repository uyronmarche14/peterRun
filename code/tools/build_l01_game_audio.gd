extends SceneTree

# Offline, deterministic synthesis for original prototype gameplay audio.
# No runtime synthesis, sampled recordings, or borrowed melodies.
const RATE := 22050
const OUTPUT := "res://art/audio/"


func _init() -> void:
	call_deferred("_build")


func _build() -> void:
	var success := true
	success = _save("l01_barangay_ambience_v01.wav", _ambience()) and success
	success = _save("l01_prompt_ready_v01.wav", _cue(0.32, [392.0, 523.25], 0.115)) and success
	success = _save("l01_action_ack_v01.wav", _cue(0.18, [440.0], 0.105)) and success
	success = _save("l01_success_v01.wav", _cue(0.48, [523.25, 659.25], 0.14)) and success
	quit(0 if success else 1)


func _ambience() -> PackedFloat32Array:
	var seconds := 12.0
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	var rng := RandomNumberGenerator.new()
	rng.seed = 190923
	var breeze := 0.0
	for index in samples.size():
		var t := float(index) / RATE
		# A quiet filtered-air bed, with three sparse, distant decorative calls.
		breeze = lerpf(breeze, rng.randf_range(-1.0, 1.0), 0.006)
		var soft_air := breeze * (0.035 + 0.008 * sin(t * 0.7))
		var warm_hum := 0.008 * sin(TAU * 110.0 * t) * (0.7 + 0.3 * sin(t * 0.23))
		var birds := 0.0
		for start in [2.15, 6.85, 9.9]:
			var local: float = t - float(start)
			if local >= 0.0 and local <= 0.34:
				var envelope := sin(PI * local / 0.34) * sin(PI * local / 0.34)
				var phase: float = TAU * (920.0 * local + 320.0 * local * local)
				birds += sin(phase) * envelope * 0.048
		var loop_fade := minf(1.0, minf(t / 0.35, (seconds - t) / 0.35))
		samples[index] = (soft_air + warm_hum + birds) * loop_fade
	return samples


func _cue(seconds: float, notes: Array[float], amplitude: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	for index in samples.size():
		var t := float(index) / RATE
		var value := 0.0
		for note_index in notes.size():
			var local := t - note_index * (seconds * 0.36)
			if local < 0.0:
				continue
			var envelope := minf(1.0, local / 0.012) * exp(-local * 13.0) * minf(1.0, (seconds - t) / 0.045)
			value += (sin(TAU * notes[note_index] * local) + 0.16 * sin(TAU * notes[note_index] * 2.0 * local)) * envelope * amplitude
		samples[index] = value
	return samples


func _save(file_name: String, samples: PackedFloat32Array) -> bool:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in samples.size():
		bytes.encode_s16(index * 2, int(clampf(samples[index], -0.95, 0.95) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	var result := stream.save_to_wav(OUTPUT + file_name)
	print("L01 game audio %s: %s" % [file_name, error_string(result)])
	return result == OK
