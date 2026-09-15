class_name L01LayeredRouteMotion
extends Node2D

## Restrained, visual-only parallax for the Blender-authored L01 layer stack.
## No lane, prompt, timing, input, or repetition state is read or changed here.

var is_motion_paused := false
var motion_phase := 0.0
var _base_positions: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is Node2D:
			_base_positions[child.name] = child.position


func _process(delta: float) -> void:
	advance_layer_motion(delta)


func set_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func set_motion_paused(should_pause: bool) -> void:
	is_motion_paused = should_pause


func advance_layer_motion(delta: float) -> void:
	if is_motion_paused:
		return
	motion_phase += delta
	if not is_node_ready():
		return
	# Sub-pixel amplitudes keep the world calm and never move scenery into a lane.
	_set_layer_offset(^"Far", sin(motion_phase * 0.10) * 0.22, 0.0)
	_set_layer_offset(^"Mid", sin(motion_phase * 0.13 + 0.8) * 0.38, 0.0)
	_set_layer_offset(^"Near", sin(motion_phase * 0.17 + 1.7) * 0.62, 0.0)
	_set_layer_offset(^"Foreground", sin(motion_phase * 0.21 + 2.4) * 0.80, 0.0)


func _set_layer_offset(path: NodePath, x_offset: float, y_offset: float) -> void:
	var layer := get_node_or_null(path) as Node2D
	if layer == null:
		return
	var base: Vector2 = _base_positions.get(layer.name, Vector2.ZERO)
	layer.position = base + Vector2(x_offset, y_offset)
