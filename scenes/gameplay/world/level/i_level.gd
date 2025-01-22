## © [2024] A7 Studio. All rights reserved. Trademark.
## Base class for all game levels. Manages level state, resources, and map loading.

class_name ILevel extends Node2D

## Victory and defeat states
signal stats_updated
signal level_ready

## Reference to currently active level instance
static var current_level: ILevel = null

## Scene containing the map layout and wave data
@export var map_scene: PackedScene = null

@export var win_condition: WinConditionEntity = null

## Array of differents signal (if more needed)

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
	if map_scene != null:
		var new_map = map_scene.instantiate()
		add_child(new_map)
		map = new_map
		Log.trace(Log.Level.INFO, "ILevel.gd: Map instance created and added to the level")
		win_condition = WinConditionEntity.new()
		win_condition._build_state_machine()
		win_condition._connect_signals()
		if map.has_signal("victory"):
			SignalUtil.connects([ {SignalUtil.WHO: map, SignalUtil.WHAT: "victory", SignalUtil.TO: _on_victory}])
	else:
		Log.trace(Log.Level.ERROR, "ILevel.gd: map_scene is null. Cannot initialize map.")
	emit_signal("level_ready", self)

# public
## Initializes the level with provided metadata
func initialize(meta: LevelMetadata) -> void:
	metadata = meta.duplicate()
	Log.trace(Log.Level.INFO, "Level initializing [{0}] : {1}".format([metadata.id, metadata.level_name]))
	_load_map()

## Starts the next wave of enemies
func start_new_wave() -> void:
	pass

# private
## Updates coin count and emits stats_updated signal
func _set_coins(new_value: int) -> void:
	coins = new_value
	stats_updated.emit()

## Updates health points 
func _set_health(new_value: int) -> void:
	health = new_value
	stats_updated.emit()
	
## Called when a wave ends
func _on_wave_complete(last_wave: bool) -> void:
	Log.trace(Log.Level.INFO, "Wave complete signal received. Last wave: %s" % last_wave)
	win_condition._on_wave_complete(last_wave)

## Called to change the State to victoryState
func _on_victory() -> void:
	Log.trace(Log.Level.INFO, "Victory condition reached")
	win_condition.state_machine.transition_to(WinConditionEntity.STATE_VICTORY)


## Loads and initializes the map scene
func _load_map() -> void:
	var new_map: Node = map_scene.instantiate()
	add_child(new_map)

	Global.cursor.map_ref = map

	if new_map.has_signal("wave_complete"):
		SignalUtil.connects([ {SignalUtil.WHO: new_map, SignalUtil.WHAT: "wave_complete", SignalUtil.TO: _on_wave_complete}])
		Log.trace(Log.Level.INFO, "Connected 'wave_complete' signal from map.")
	else:
		Log.trace(Log.Level.ERROR, "Map does not have 'wave_complete' signal.")
