## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Base class for game maps. Manages tile-based map layout and wave spawning.
## @tutorial: See map_1.tscn for implementation example
class_name IMap
extends Node2D

signal wave_complete(last_wave: bool)
signal victory

## Reference to the TileMap node for map layout
@export var tilemap: TileMap

## Returns true if all waves are completed
var all_waves_completed: bool = false

# Instance of win condition
var win_condition : WinConditionEntity = null;

## Index of current active wave
var current_wave: int = -1

## Array of paths that enemies can follow
var paths: Array[Path2D] = []

## Array of waves to spawn
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

# private
## Starts a new wave at the given index
func _start_wave(index: int) -> void:
	if index == waves.size():
		Log.trace(Log.Level.DEBUG, "You WIN !!!")
		waves_timer.stop()
		victory.emit()
		return

	waves[index].start_wave()
	popup_wave_spawner.wave("Wave %s" % [index + 1])
	current_wave = index

## Loads path nodes from the Paths node
func _load_paths() -> void:
	var children: Array[Node] = $Paths.get_children()

	for child in children:
		if (child is Path2D):
			paths.append(child as Path2D)

## Loads and initializes wave nodes from the Waves node
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
			SignalUtil.connects([ {SignalUtil.WHO: child, SignalUtil.WHAT: "wave_end", SignalUtil.TO: callback}])

			child.set_paths(paths)
			waves.append(child as Wave)

	if waves.is_empty():
		Log.trace(Log.Level.WARN, "%s don't have waves" % name)

# signals
## Called when the wave timer expires to start next wave
func _on_waves_timer_timeout() -> void:
	_start_wave(current_wave + 1)
