extends SceneTree

const MANIFEST := "res://../Peter_Run_Visual_Production/imagegen_sources/l01_home_passby_v02/layout.json"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(FileAccess.file_exists(MANIFEST), "Home pass-by source layout exists")
	if FileAccess.file_exists(MANIFEST):
		_check_manifest()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN Home pass-by source gate: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_manifest() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	_expect(parsed is Dictionary, "Layout is a JSON object")
	if not parsed is Dictionary:
		return
	var entries: Array = parsed.get("modules", [])
	_expect(entries.size() >= 6, "At least three varied frontages per side")
	var side_count := {"left": 0, "right": 0}
	var paths := {}
	for entry in entries:
		if not entry is Dictionary:
			failures.append("Each module is a JSON object")
			continue
		var side: String = entry.get("side", "")
		_expect(side_count.has(side), "Module uses a named road side")
		if side_count.has(side):
			side_count[side] += 1
		var path: String = entry.get("source", "")
		var dimensions: Array = entry.get("source_size", [])
		_expect(dimensions.size() == 2, "Module records source canvas dimensions")
		var expected_size := Vector2i(int(dimensions[0]), int(dimensions[1])) if dimensions.size() == 2 else Vector2i.ZERO
		_expect(not paths.has(path), "Each module has original source art: " + path)
		paths[path] = true
		_expect(FileAccess.file_exists(path), "Module art exists: " + path)
		if FileAccess.file_exists(path):
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			_expect(image != null and image.get_size() == expected_size, "Source matches its recorded canvas: " + path)
			if image != null:
				_expect(image.get_pixel(0, 0).a < 0.05, "Source exterior is transparent: " + path)
		var contact: Array = entry.get("contact", [])
		_expect(contact.size() == 2, "Module declares ground-contact origin")
		if contact.size() == 2:
			_expect(float(contact[0]) >= 0.0 and float(contact[0]) < expected_size.x
				and float(contact[1]) >= 0.0 and float(contact[1]) < expected_size.y,
				"Ground-contact origin lies in source canvas")
		var phase := float(entry.get("phase", -1.0))
		_expect(phase >= 0.0 and phase < 1.0, "Module phase lies in travel cycle")
	_expect(side_count["left"] >= 3 and side_count["right"] >= 3, "Both sides have three distinct frontages")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
