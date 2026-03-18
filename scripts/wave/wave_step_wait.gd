## © [2026] A7 Studio. All rights reserved. Trademark.

class_name WaveStepWait
extends WaveStep
## A wave step that waits for a certain amount of time.


# core
func _init(in_data: Dictionary) -> void:
	super._init(WaveStep.Order.WAIT, in_data)


# public
## Records the start time of the wait if it hasn't been set yet.
func exec() -> void:
	if not _data.has("start"):
		_data["start"] = Time.get_unix_time_from_system()


## Returns true if the wait time has elapsed.
func is_over() -> bool:
	var elapsed: float = Time.get_unix_time_from_system() - _data["start"]
	return elapsed >= _data[WaveStep.WAIT_S]
