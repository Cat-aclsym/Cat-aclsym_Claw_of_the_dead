class_name Wave extends Object

var steps: Array[WaveStep] = []


# core
func _init(data: Array) -> void:
    for raw_step in data:
        var step := WaveStep.build(raw_step)
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


# private


# signal


# event


# setget

