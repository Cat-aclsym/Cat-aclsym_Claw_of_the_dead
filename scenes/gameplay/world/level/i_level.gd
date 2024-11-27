## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Base class for all game levels. Manages level state, resources and map loading.
## @tutorial: See level_1.tscn for implementation example
class_name ILevel
extends Node2D

## Emitted when level stats (health/coins) are updated
signal stats_updated

## Reference to currently active level instance
static var current_level: ILevel = null

## Scene containing the map layout and wave data
@export var map_scene: PackedScene = null

## Current coin count for purchasing towers
var coins: int = 75:
	set = _set_coins

## Current player health points
var health: int = 20:
	set = _set_health

## Reference to the active map instance
var map: IMap = null

## Metadata containing level configuration
var metadata: LevelMetadata = null

# core
func _ready() -> void:
	assert(map_scene != null, "map_scene must be set in the editor")

# public
## Initializes the level with provided metadata
func initialize(meta: LevelMetadata) -> void:
	metadata = meta.duplicate()
	Log.trace(Log.Level.INFO, "Level initializing [{0}] : {1}".format([metadata.id, metadata.level_name]))
	_load_map()

## Starts the next wave of enemies
func start_new_wave() -> void:
	pass

## Called when player wins the level
func win() -> void:
	pass

## Called when player loses the level
func loose() -> void:
	pass

# private
## Loads and initializes the map scene
func _load_map() -> void:
	Log.trace(Log.Level.INFO, "Loading map ...")
	if not map_scene:
		Log.trace(Log.Level.ERROR, "An IMap must be provided to create a level!")
		return

	var new_map: IMap = map_scene.instantiate()
	add_child(new_map)
	map = new_map

	Global.cursor.map_ref = map

## Updates coin count and emits stats_updated signal
func _set_coins(new_value: int) -> void:
	coins = new_value
	stats_updated.emit()

## Updates health points and emits stats_updated signal
func _set_health(new_value: int) -> void:
	health = new_value
	stats_updated.emit()
