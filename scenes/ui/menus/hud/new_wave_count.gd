## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the countdown display for new enemy waves.
## Shows a countdown timer until the next wave starts.
class_name NewWaveCount
extends Label

## The target time for the countdown to end.
var _to: int = -1

# core
func _process(_delta: float) -> void:
	if _to == -1:
		return
	_update()

# public
## Starts the countdown timer with the specified delay.
## [br]Makes the countdown visible and begins updating.
## [param delay] The delay in seconds until the next wave
func start(delay: float) -> void:
	_to = floor(Time.get_unix_time_from_system() + delay)
	visible = true
	_update()

# private
## Updates the countdown display.
## [br]Calculates and formats the remaining time, hides when complete.
func _update() -> void:
	if Time.get_unix_time_from_system() > _to:
		_to = -1
		visible = false
		return

	var time_remaining: float = _to - Time.get_unix_time_from_system()
	var sec: int = floor(time_remaining)
	var ms: int = floor((time_remaining - sec) * 10)

	text = "New wave in {0}.{1}s".format([sec, ms])
