# Opening music provenance

## Hakbang sa Umaga

- Created for this PETER RUN prototype on 2026-09-07 using the original score and synthesis code in `../../tools/build_menu_music.gd`.
- No downloaded recording, commercial runner audio, vocals or national-anthem melody was used. This is not an arrangement of an existing song.
- Direction: welcoming, restrained, plucked-string-style instrumental. Cultural reference: the bandurria, laud, octavina, guitar and bass ensemble described by [UP Alumni & Friends Rondalla](https://www.upafrondalla.org/instruments.html). That source informed the instrumentation direction only; no audio was taken from it. The synthesized timbres are not authentic instrument recordings.
- WAV source: 20 seconds, eight bars of 3/4 at 72 BPM, 22,050 Hz, stereo, 16-bit PCM. The builder normalizes the source peak to 0.65 and wraps note tails/quiet echo across the loop boundary.
- Runtime uses Godot's imported WAV resource. Loop boundaries are computed in sample frames from duration and sample rate, not compressed byte size.
- Opening-only playback, 1.2-second fade-in, visible mute and volume control. Default slider value is 35%; maximum player gain is -12 dB. This is a software output limit, not a guarantee about physical speaker loudness.
- Release status: synthesized prototype awaiting listening, cultural/art direction and final audio approval. No claim of professional mastering or clinical approval. Review on the actual target speakers before release.

From the `code/` directory, explicitly rebuild the generated WAV with:

```text
godot --headless --path . -s res://tools/build_menu_music.gd
godot --headless --editor --path . --import
```

The first command overwrites only `art/audio/hakbang_sa_umaga.wav`. The builder runs offline; the shipped menu plays the prepared asset, not the synthesis algorithm. Keep the source score with the audio so it remains editable and reproducible.

## Opening illustration

`../../scripts/barangay_opening_art.gd` draws the original flat-color barangay opening in code: sari-sari store, home, plants, path, hills and a restrained woven-border motif. It contains no external images. The character is the existing shared prototype player scene. Both remain prototype visuals, not the approved final pixel-art asset set.
