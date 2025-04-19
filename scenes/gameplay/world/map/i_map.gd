## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Base class for game maps. Manages tile-based map layout and wave spawning.
## @tutorial: See map_1.tscn for implementation example
class_name IMap
extends Node2D

## Reference to the TileMap node for map layout
@export var tilemap: TileMap

## Array of paths that enemies can follow
var paths: Array[Path2D] = []


@onready var popup_wave_spawner: PopupSpawner = $PopupWaveSpawner
@onready var camera: Camera2D = $Camera2D

# core
func _ready() -> void:
	_load_paths()

	Global.cursor.tm_ref = tilemap



# private

## Loads path nodes from the Paths node
func _load_paths() -> void:
	Log.trace(Log.Level.DEBUG, "Loading mappaths");
	var children: Array[Node] = $Paths.get_children()

	for child in children:
		if (child is Path2D):
			paths.append(child as Path2D)


