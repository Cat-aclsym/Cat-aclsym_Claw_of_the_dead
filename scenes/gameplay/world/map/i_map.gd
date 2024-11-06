## © [2024] A7 Studio. All rights reserved. Trademark.
class_name IMap
extends Node2D

signal win
signal loose

@export var tilemap: TileMap

var current_wave: int = -1
var paths: Array[Path2D] = []
var waves: Array[Wave] = []

@onready var waves_timer: Timer = $WavesTimer
@onready var popup_wave_spawner: PopupSpawner = $PopupWaveSpawner
@onready var camera: Camera2D = $Camera2D

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: waves_timer, SignalUtil.WHAT: "timeout", SignalUtil.TO: _on_waves_timer_timeout},
]

# core
func _ready() -> void:
	_load_paths()
	_load_waves()
	_start_wave(current_wave + 1)

	Global.cursor.tm_ref = tilemap

	SignalUtil.connects(signals)


# public


# private
func _start_wave(index: int) -> void:
	if index == waves.size():
		Log.trace(Log.Level.DEBUG, "You WIN !!!")
		win.emit()
		waves_timer.stop()
		return

	waves[index].start_wave()
	popup_wave_spawner.wave("Wave %s" % [index + 1])
	current_wave = index


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

			var callback = func (delay: float):
				waves_timer.wait_time = delay
				waves_timer.start()
			SignalUtil.connects([{SignalUtil.WHO: child, SignalUtil.WHAT: "wave_end", SignalUtil.TO: callback}])

			child.set_paths(paths)
			waves.append(child as Wave)

	if waves.is_empty():
		Log.trace(Log.Level.WARN, "%s don't have waves" % name)


# signal
func _on_waves_timer_timeout() -> void:
	_start_wave(current_wave + 1)


# event


# setget
