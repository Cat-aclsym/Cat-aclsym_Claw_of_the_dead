class_name WaveStep extends Object

## Order.SPAWN data indexes
const ENEMY_ID := "enemy_id"
const COUNT := "count"
const SPAWNER := "spawner"

## Order.WAIT data indexes
const WAIT_S := "wait_s"

enum Order {
    UNDEFINED = 0,
    COMMAND,
    SPAWN,
    WAIT,
    DIALOG
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

    if _is_spawn(keys):
        return WaveStepSpawn.new(in_data)
    elif _is_wait(keys):
        return WaveStepWait.new(in_data)
    
    Log.trace(Log.Level.ERROR, "Failed to create adequat WaveStep");
    return null


func exec() -> void:
    Log.trace(Log.Level.WARN, "You are trying to execute WaveStep base class.");


func is_over() -> bool:
    Log.trace(Log.Level.WARN, "You are trying to execute WaveStep base class.");
    return true


func order() -> WaveStep.Order:
    return _order


func data() -> Dictionary:
    return _data


# private
static func _is_spawn(keys: Array) -> bool:
    return ENEMY_ID in keys and COUNT in keys and SPAWNER in keys

static func _is_wait(keys: Array) -> bool:
    return WAIT_S in keys

# signal


# event


# setget

