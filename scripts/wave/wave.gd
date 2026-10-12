## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Wave
extends RefCounted
## Ordered list of the steps (spawns and waits) of one wave.

var steps: Array[WaveStep] = []


# core
func _init(data: Array) -> void:
	for raw_step: Dictionary in data:
		var step: WaveStep = WaveStep.build(raw_step)
		if step == null:
			Log.trace(Log.Level.ERROR, "Skipping invalid wave step: %s" % [raw_step])
			continue
		steps.append(step)


func _to_string() -> String:
	return "Wave({size}): {steps}".format({
		"size": steps.size(),
		"steps": steps
	})


# public
func peak() -> WaveStep:
	if steps.size():
		return steps.front()
	return null


func pop() -> WaveStep:
	return steps.pop_front()
