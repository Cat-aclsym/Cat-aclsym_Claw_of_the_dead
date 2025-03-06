
## © 2024 A7 Studio. All rights reserved. Trademark.
## Base class for all game levels. Manages level state, resources, and map loading.

class_name ILevel extends Node2D


## Signals for game state changes
signal stats_updated

# Constants for state names
const STATE_CONFIGURING: String = "CONFIGURING"
const STATE_PLAYING: String = "PLAYING"
const STATE_VICTORY: String = "VICTORY"
const STATE_DEFEAT: String = "DEFEAT"
const STATE_ERROR: String = "ERROR"
const STATE_PAUSE: String = "PAUSE"
const END_GAME_MENU: PackedScene = preload("res://scenes/ui/menus/end_game/end_game.tscn")

## Reference to currently active level instance
static var current_level: ILevel = null

## Scene containing the map layout and wave data
@export var map_scene: PackedScene = null

## Time when the level started and ended
var start_time: float
var end_time: float

## StateMachine handling the level logic
var state_machine: StateMachine

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

## Current state of the level
var current_state: String

## Last state of the level
var last_state: String = ""

# core
func _ready() -> void:
	if map_scene != null:
		var new_map = map_scene.instantiate()
		add_child(new_map)
		map = new_map
		Log.trace(Log.Level.INFO, "ILevel.gd: Map instance created and added to the level")
		if map.has_signal("victory"):
			SignalUtil.connects([ {SignalUtil.WHO: map, SignalUtil.WHAT: "victory", SignalUtil.TO: _on_victory}])

	else:
		Log.trace(Log.Level.ERROR, "ILevel.gd: map_scene is null. Cannot initialize map.")

	_build_state_machine()
	state_machine.toggle_initial_state()
	start_time = Time.get_unix_time_from_system()

func _physics_process(delta: float) -> void:
	current_state = state_machine.get_current_state().name
	if current_state != last_state:
		state_machine.handle_current_state([delta])
		last_state = current_state


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
func _set_health(new_value: int) -> void:
	if health <= 0:
		return
	health = new_value
	stats_updated.emit()

	if health <= 0 and state_machine.transition_to(STATE_DEFEAT):
		Log.trace(Log.Level.INFO, "Player defeated.")

## Update player's coin count
func _set_coins(new_value: int) -> void:
	coins = new_value
	stats_updated.emit()


## Loads and initializes the map scene
func _load_map() -> void:
	var new_map: Node = map_scene.instantiate()
	add_child(new_map)

	Global.cursor.map_ref = map
	if map.has_signal("wave_complete"):
		SignalUtil.connects([
			{SignalUtil.WHO: map, SignalUtil.WHAT: "wave_complete", SignalUtil.TO: _on_wave_complete}
		])
		Log.trace(Log.Level.INFO, "Connected 'wave_complete' signal from IMap to ILevel.")
	else:
		Log.trace(Log.Level.ERROR, "IMap does not have 'wave_complete' signal.")


## Builds the state machine
func _build_state_machine() -> void:
	var builder: StateMachineBuilder = StateMachineBuilder.new()

	builder.build_initial_state(STATE_CONFIGURING, _on_configuring)
	builder.build_state(STATE_PLAYING, _on_playing)
	builder.build_state(STATE_VICTORY, _on_victory)
	builder.build_state(STATE_DEFEAT, _on_defeat)
	builder.build_state(STATE_ERROR, _on_error)
	builder.build_state(STATE_PAUSE, _on_pause)

	builder.build_transition(STATE_CONFIGURING, STATE_PLAYING)
	builder.build_transition(STATE_PLAYING, STATE_VICTORY)
	builder.build_transition(STATE_PLAYING, STATE_DEFEAT)
	builder.build_transition(STATE_CONFIGURING, STATE_DEFEAT)
	builder.build_transition(STATE_ERROR, STATE_CONFIGURING)
	builder.build_transition(STATE_DEFEAT, STATE_PAUSE)
	builder.build_transition(STATE_PAUSE, STATE_PLAYING)
	builder.build_transition(STATE_VICTORY, STATE_CONFIGURING)
	builder.build_transition(STATE_DEFEAT, STATE_ERROR)


	state_machine = builder.build()
	Log.trace(Log.Level.INFO, "State Machine built. Initial State: %s" % state_machine.get_current_state().name)

## Getter current state
func get_current_state() -> String:
	return state_machine.get_current_state().name if state_machine else STATE_CONFIGURING

## State: Configuring
func _on_configuring(args = []) -> bool:
	var delta: float = args[0] if args.size() > 0 else 0.0
	Log.trace(Log.Level.INFO, "Entering CONFIGURING state. Delta: %s" % delta)
	Log.trace(Log.Level.INFO, "Configuration complete. Transitioning to PLAYING...")
	var success: bool = state_machine.toggle_state(STATE_PLAYING)
	if not success:
		Log.trace(Log.Level.ERROR, "Transition to PLAYING failed.")
		return false

	return true

var has_logged_playing: bool = false

## State: Playing
func _on_playing(args = []) -> bool:
	var delta: float = args[0] if args.size() > 0 else 0.0
	if not has_logged_playing:
		Log.trace(Log.Level.INFO, "Entering PLAYING state with delta: %s" % delta)
		has_logged_playing = true

	return true


## State: Victory
func _on_victory(args = []) -> bool:
	var last_wave: bool                 = args[0] if args.size() > 0 and args[0] is bool else true
	end_time = Time.get_unix_time_from_system()
	var end_game_menu_instance: EndGame = END_GAME_MENU.instantiate()
	Global.ui.add_child(end_game_menu_instance)
	Log.trace(Log.Level.INFO, "Entering VICTORY state. Last wave: %s" % last_wave)

	return true

## State: Defeat
func _on_defeat(args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering DEFEAT state.")
	end_time = Time.get_unix_time_from_system()
	var end_game_menu_instance: EndGame = END_GAME_MENU.instantiate()
	Global.ui.add_child(end_game_menu_instance)

	return true

### State: Pause
func _on_pause(args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering PAUSE state")
	get_tree().paused = true
	Engine.time_scale = 0
	Log.trace(Log.Level.INFO, "Game paused")
	return true

## State: Error
func _on_error(args = []) -> bool:
	Log.trace(Log.Level.ERROR, "Entering ERROR state")
	if state_machine.toggle_state(STATE_CONFIGURING):
		Log.trace(Log.Level.INFO, "Successfully transitioned from ERROR to CONFIGURING")
		return true
	else:
		Log.trace(Log.Level.ERROR, "Map does not have 'wave_complete' signal.")
		Log.trace(Log.Level.ERROR, "Transition to CONFIGURING failed from ERROR")
		return false

func _on_wave_complete(last_wave: bool) -> void:
	Log.trace(Log.Level.INFO, "Wave complete signal received. Last wave: %s" % last_wave)

	if last_wave:
		Log.trace(Log.Level.INFO, "All waved passed. transition to VICTORY")
		if state_machine.toggle_state(STATE_VICTORY):
			Log.trace(Log.Level.INFO, "transition to VICTORY succeed")
		else:
			Log.trace(Log.Level.ERROR, "can't passed to victory")

## Returns a tower instance by name
func get_tower_by_name(name: String) -> ITower:
	for child in map.get_children():
		if child is ITower:
			var tower: ITower = child as ITower
			if tower.name == name:
				return tower
	return null
