## © [2026] A7 Studio. All rights reserved. Trademark.

class_name WaveStepWait
extends WaveStep
## A wave step that waits for a certain amount of game time, so pausing the level freezes it.

## Level game time at the first [method exec], negative until then.
var _start: float = -1.0


# public
## Records the start time of the wait if it hasn't been set yet.
func exec() -> void:
	if _start < 0.0:
		_start = ILevel.current_level.elapsed_time


## Returns true if the wait time has elapsed.
func is_over() -> bool:
	return ILevel.current_level.elapsed_time - _start >= _data[WaveStep.WAIT_S]
