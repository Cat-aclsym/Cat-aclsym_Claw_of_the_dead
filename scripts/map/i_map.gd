class_name IMap
extends Node2D
signal win
signal loose

@export var tilemap: TileMap

var paths: Array[Path2D] = []

var current_wave: int = -1
var waves: Array[Wave] = []

@onready var waves_timer: Timer = $WavesTimer
@onready var PopupWaveSpawner: PopupSpawner = $PopupWaveSpawner
@onready var camera: Camera2D = $Camera2D


# core
func _ready() -> void:
	_load_paths()
	_load_waves()
	_start_next_wave()

	Global.cursor.tm_ref = tilemap

	for wave in waves:
		wave.wave_end.connect(func(_delay: float): _start_next_wave())


# functionnal
func get_paths() -> Array[Path2D]:
	return paths


# internal
func _start_next_wave() -> void:
	current_wave += 1

	if current_wave == waves.size():
		Log.debug("You win!")
		win.emit()
		return

	waves[current_wave].start_wave()
	PopupWaveSpawner.wave("Wave {0}".format([current_wave + 1]))


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

	if waves.is_empty():
		Log.warning("{0} don't have waves".format([name]))


# signals
func _on_waves_timer_timeout() -> void:
	_start_next_wave()
