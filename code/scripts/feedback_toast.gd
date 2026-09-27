extends PanelContainer

const SUCCESS_MESSAGES: Array[String] = [
	"Nicely done!",
	"You're doing great!",
	"Nice step!",
	"Good effort!",
	"Movement recorded.",
	"Great movement!",
]
const DURATION := 1.65
const FADE_IN := 0.18
const FADE_OUT := 0.3

var elapsed := DURATION
var _paused := false
var _success_index := 0
var _last_milestone := 0
var _rest_y := 0.0

@onready var message: Label = $Message


func _ready() -> void:
	_rest_y = position.y
	dismiss()


func show_result(success: bool, completed: int) -> void:
	if success:
		var milestone := completed / 10
		if milestone > _last_milestone:
			_last_milestone = milestone
			message.text = "%d movements completed!" % completed
		else:
			message.text = SUCCESS_MESSAGES[_success_index % SUCCESS_MESSAGES.size()]
			_success_index += 1
	else:
		message.text = "Take your time."
	_show_message()


func show_safe_passage() -> void:
	message.text = "Path is clear."
	_show_message()


func _show_message() -> void:
	# Replace the current message; never build a backlog of stale notifications.
	elapsed = 0.0
	modulate.a = 0.0
	position.y = _rest_y + 3.0
	visible = not _paused
	set_process(not _paused)


func _process(delta: float) -> void:
	if _paused or elapsed >= DURATION:
		return
	elapsed = minf(DURATION, elapsed + delta)
	var entrance := smoothstep(0.0, FADE_IN, elapsed)
	modulate.a = entrance * (1.0 - smoothstep(DURATION - FADE_OUT, DURATION, elapsed))
	position.y = _rest_y + 3.0 * (1.0 - entrance)
	if elapsed >= DURATION:
		dismiss()


func set_feedback_paused(paused: bool) -> void:
	_paused = paused
	visible = not paused and elapsed < DURATION
	set_process(visible)


func dismiss() -> void:
	elapsed = DURATION
	visible = false
	modulate.a = 0.0
	position.y = _rest_y
	set_process(false)
