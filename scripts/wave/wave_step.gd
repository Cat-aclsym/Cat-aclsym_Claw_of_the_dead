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
    var o := WaveStep.Order.UNDEFINED

    if ENEMY_ID in keys and COUNT in keys and SPAWNER in keys:
        o = WaveStep.Order.SPAWN
    elif WAIT_S in keys:
        o = WaveStep.Order.WAIT
    
    assert(o != WaveStep.Order.UNDEFINED)
    return WaveStep.new(o, in_data)


func order() -> WaveStep.Order:
    return _order


func data() -> Dictionary:
    return _data

# private


# signal


# event


# setget

