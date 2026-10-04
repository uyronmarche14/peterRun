extends SpinBox

# Retain the existing Range/value_changed contract; replace tiny vertical arrows
# with two labelled 64x64 screen-pixel targets at the 1080p output scale.
var _readout: Label
var _decrease: Button
var _increase: Button


func _ready() -> void:
	editable = false
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_line_edit().hide()
	var surface := PanelContainer.new()
	surface.name = "Stepper"
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel", get_theme_stylebox("normal", "LineEdit"))
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 4)
	surface.add_child(row)
	_decrease = _button("Decrease", "−", "Decrease repetitions", -1)
	row.add_child(_decrease)
	_readout = Label.new()
	_readout.name = "Value"
	_readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_readout)
	_increase = _button("Increase", "+", "Increase repetitions", 1)
	row.add_child(_increase)
	value_changed.connect(_refresh)
	_refresh(value)


func _button(node_name: String, caption: String, hint: String, direction: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(16, 16)
	button.pressed.connect(func(): value = clampf(value + direction * step, min_value, max_value))
	return button


func _refresh(amount: float) -> void:
	_readout.text = str(int(amount))
	_decrease.disabled = amount <= min_value
	_increase.disabled = amount >= max_value
