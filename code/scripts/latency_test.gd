extends RefCounted

# A simple delay test: a cue is shown, the player presses, and the time between them is
# recorded. It measures the player, the screen and the controller together; comparing the
# keyboard with the MOVE controller shows the controller's own share.
const KEEP := 50
const AVERAGE_OVER := 5

var _results: Array[float] = []
var _cue_at := -1.0


func cue_shown(now_seconds: float) -> void:
	_cue_at = now_seconds


# Returns the delay in ms, or -1 when there is no cue waiting for a press.
func record_press(now_seconds: float) -> float:
	if _cue_at < 0.0:
		return -1.0
	var milliseconds := maxf(0.0, (now_seconds - _cue_at) * 1000.0)
	_cue_at = -1.0
	_results.append(milliseconds)
	if _results.size() > KEEP:
		_results.pop_front()
	return milliseconds


func count() -> int:
	return _results.size()


func average_ms() -> float:
	if _results.is_empty():
		return -1.0
	var recent := _results.slice(maxi(0, _results.size() - AVERAGE_OVER))
	var total := 0.0
	for value in recent:
		total += value
	return total / recent.size()


func best_ms() -> float:
	return -1.0 if _results.is_empty() else _results.min()


func reset() -> void:
	_results.clear()
	_cue_at = -1.0
