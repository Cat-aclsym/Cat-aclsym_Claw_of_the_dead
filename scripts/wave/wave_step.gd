## © [2024] A7 Studio. All rights reserved. Trademark.

class_name WaveStep extends Object

## Order.SPAWN data indexes
const ENEMY_ID := "enemy_id"
const COUNT := "count"
const SPAWNER := "spawner"

## Order.WAIT data indexes
const WAIT_S := "wait_s"

## Order.DIALOG data indexes
const DIALOG_ID := "dialog_id"

enum Order {
	UNDEFINED = 0,
	COMMAND,
	SPAWN,
	WAIT,
	DIALOG,
	CHECK_ENEMIES
}

var _order := WaveStep.Order.UNDEFINED
var _data: Dictionary = {}


# core
func _init(in_order: WaveStep.Order, in_data: Dictionary) -> void:
    assert(in_order != WaveStep.Order.UNDEFINED)
    _order = in_order
    _data = in_data


func _to_string() -> String:
    return "WaveStep({order}): {data}".format({
        "order": _order,
        "data": _data
    })


# public
static func build(in_data: Dictionary) -> WaveStep:
	var keys: Array = in_data.keys()

	if is_spawn(keys):
		return WaveStepSpawn.new(in_data)
	elif is_wait(keys):
		return WaveStepWait.new(in_data)
	elif is_dialog(keys):
		return WaveStepDialog.new(in_data)
	elif is_check_enemies(keys):
		return WaveStepCheckEnemies.new(in_data)
	else:
		Log.trace(Log.Level.ERROR, "Unknown step type: %s" % in_data)
		return null

func exec() -> void:
	Log.trace(Log.Level.WARN, "You are trying to execute WaveStep base class.")


func is_over() -> bool:
	Log.trace(Log.Level.WARN, "You are trying to execute WaveStep base class.")
	return true


func order() -> WaveStep.Order:
	return _order


func data() -> Dictionary:
	return _data


# Type checking methods
static func is_spawn(keys: Array) -> bool:
	return ENEMY_ID in keys and COUNT in keys and SPAWNER in keys


static func is_wait(keys: Array) -> bool:
	return WAIT_S in keys


static func is_dialog(keys: Array) -> bool:
	return DIALOG_ID in keys


static func is_check_enemies(keys: Array) -> bool:
	return "check_enemies" in keys



# signal


# event


# setget
