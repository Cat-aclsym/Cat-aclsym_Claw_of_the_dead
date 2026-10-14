## © [2026] A7 Studio. All rights reserved. Trademark.

@abstract
class_name WaveStep
extends RefCounted
## Base class for a single step in a wave (spawn, wait, etc.), [method build] creates the concrete steps.

const COUNT := "count"
## Spawn step data keys.
const ENEMY_ID := "enemy_id"
const SPAWNER := "spawner"

## Wait step data keys.
const WAIT_S := "wait_s"

var _data: Dictionary = {}


# core
func _init(in_data: Dictionary) -> void:
	_data = in_data


func _to_string() -> String:
	return "{type}: {data}".format({
		"type": get_script().get_global_name(),
		"data": _data
	})


# public
## Factory method to create a specific WaveStep from data.
static func build(in_data: Dictionary) -> WaveStep:
	var keys: Array = in_data.keys()

	if _is_spawn(keys):
		return WaveStepSpawn.new(in_data)
	elif _is_wait(keys):
		return WaveStepWait.new(in_data)

	Log.trace(Log.Level.ERROR, "Failed to create adequat WaveStep")
	return null


## Returns the data dictionary.
func data() -> Dictionary:
	return _data


## Executes the step logic.
@abstract func exec() -> void


## Returns true if the step is finished.
@abstract func is_over() -> bool


# private
static func _is_spawn(keys: Array) -> bool:
	return ENEMY_ID in keys and COUNT in keys and SPAWNER in keys


static func _is_wait(keys: Array) -> bool:
	return WAIT_S in keys
