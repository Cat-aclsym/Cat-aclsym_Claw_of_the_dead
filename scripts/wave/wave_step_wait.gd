class_name WaveStepWait extends WaveStep


# core
func _init(in_data: Dictionary) -> void:
    super._init(WaveStep.Order.WAIT, in_data)


# public
func exec() -> void:
    if not _data.has("start"):
        _data["start"] = Time.get_unix_time_from_system()


func is_over() -> bool:
    var elapsed: float = Time.get_unix_time_from_system() - _data["start"]
    return elapsed >= _data[WaveStep.WAIT_S]



# private


# signal


# event


# setget

