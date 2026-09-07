extends SceneTree

# Original score: Hakbang sa Umaga. No sampled recordings or quoted melodies.
# Offline asset builder, never executed by the runtime game.
const RATE := 22050
const BEAT := 60.0 / 72.0
const SECONDS := 24.0 * BEAT
var left := PackedFloat32Array()
var right := PackedFloat32Array()


func _init() -> void:
	call_deferred("_build")


func _build() -> void:
	var frames := int(SECONDS * RATE)
	left.resize(frames)
	right.resize(frames)
	var chords := [[55, 59, 62], [52, 55, 59], [48, 52, 55], [50, 57, 60],
		[55, 59, 62], [48, 52, 57], [50, 54, 57], [55, 59, 62]]
	# Six eighth-note slots per bar. -1 leaves a breath.
	var melody := [[71, -1, 74, 71, 69, -1], [67, 71, 76, -1, 74, -1],
		[72, -1, 71, 67, 69, -1], [69, 66, 62, -1, 66, 69],
		[71, 74, 79, -1, 76, 74], [76, -1, 72, 71, 69, -1],
		[69, 74, 72, -1, 69, 66], [67, -1, 71, 69, 67, -1]]
	for bar in range(8):
		var chord: Array = chords[bar]
		_note(int(chord[0]) - 12, bar * 3.0, 2.4, 0.16, 0.0, true)
		for slot in range(6):
			_note(int(chord[slot % 3]), bar * 3.0 + slot * 0.5, 1.4, 0.075, -0.45, false)
			var pitch: int = melody[bar][slot]
			if pitch >= 0:
				_note(pitch, bar * 3.0 + slot * 0.5, 1.2, 0.13, 0.35, false)
	# A very quiet, circular stereo echo softens the synthesized plucks.
	var dry_left := left.duplicate()
	var dry_right := right.duplicate()
	var delay := int(0.28 * RATE)
	var peak := 0.0
	for i in range(frames):
		left[i] += dry_right[posmod(i - delay, frames)] * 0.16
		right[i] += dry_left[posmod(i - delay, frames)] * 0.16
		peak = maxf(peak, maxf(absf(left[i]), absf(right[i])))
	var gain := 0.65 / maxf(peak, 0.01)
	var bytes := PackedByteArray()
	bytes.resize(frames * 4)
	for i in range(frames):
		bytes.encode_s16(i * 4, int(clampf(left[i] * gain, -0.99, 0.99) * 32767))
		bytes.encode_s16(i * 4 + 2, int(clampf(right[i] * gain, -0.99, 0.99) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = true
	stream.data = bytes
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/audio"))
	var result := stream.save_to_wav("res://art/audio/hakbang_sa_umaga.wav")
	print("Original menu loop: %.2fs, peak %.3f, %d PCM bytes, save %s" % [SECONDS, peak * gain, bytes.size(), error_string(result)])
	quit(0 if result == OK else 1)


func _note(midi: int, beat_start: float, beats_long: float, amplitude: float, pan: float, bass: bool) -> void:
	var frequency := 440.0 * pow(2.0, (midi - 69) / 12.0)
	var start := int(beat_start * BEAT * RATE)
	var length := int(beats_long * BEAT * RATE)
	for sample in range(length):
		var t := float(sample) / RATE
		var phase := TAU * frequency * t
		var attack := minf(t / 0.012, 1.0)
		var release := minf(float(length - sample) / (RATE * 0.08), 1.0)
		var envelope := attack * release * exp(-t * (2.2 if bass else 4.0))
		var tone := sin(phase) + 0.25 * sin(phase * 2.0) * exp(-t * 3.0)
		if not bass:
			tone += 0.13 * sin(phase * 3.0) * exp(-t * 5.0)
		var value := tone * envelope * amplitude
		var index := (start + sample) % left.size()
		left[index] += value * (1.0 - pan) * 0.5
		right[index] += value * (1.0 + pan) * 0.5
