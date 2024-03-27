class_name IMap 
extends Node2D
signal win
signal loose


var paths: Array[Path2D] = []

var current_wave: int = -1
var waves_count: int = 0
var waves: Array[Wave] = []

@onready var waves_timer: Timer = $WavesTimer


# core
func _ready() -> void:
	_load_paths()
	_load_waves()
	_start_next_wave()


# functionnal
func get_paths() -> Array[Path2D]:
	return paths


# internal
func _start_next_wave() -> void:
	current_wave += 1

	if (current_wave == waves_count):
		Log.debug("You win!")
		win.emit()
		return

	waves[current_wave].start_wave()


func _load_paths() -> void:
	var children: Array[Node] = $Paths.get_children()

	for child in children:
		if (child is Path2D):
			paths.append(child as Path2D)


func _load_waves() -> void:
	var children: Array = $Waves.get_children()
	var i: int = 0

	for child in children:
		if (child is Wave):
			i += 1
			child.name = "Wave_{0}".format([i])

			child.connect(
				"wave_end",
				 func (delay: float):
					waves_timer.wait_time = delay
					waves_timer.start()
			)

			child.set_paths(paths)
			waves.append(child as Wave)

	waves_count = waves.size()

	if (waves_count == 0):
		Log.warning("{0} don't have waves".format([name]))


# signals
func _on_waves_timer_timeout() -> void:
	_start_next_wave()
