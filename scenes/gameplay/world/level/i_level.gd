class_name ILevel2 extends Node2D


const STATE_CONFIGURING: String = "CONFIGURING"
const STATE_VICTORY: String = "VICTORY"
const STATE_DEFEAT: String = "DEFEAT"
const STATE_ERROR: String = "ERROR"
const STATE_PAUSE: String = "PAUSE"
const STATE_WAVE: String = "WAVE_%d"
const STATE_WAVE_0: String = "WAVE_0"

@export var level_id: String = "lev.XX"
@export var level_name: String
@export var map_scene: PackedScene = null

var state_machine: StateMachine

var map: IMap = null
var waves: Array

var start_time: float
var end_time: float

# core
func _ready() -> void:
	# initialisation procedure
	# _init_map()
	_load_waves()
	_build_state_machine()

# public


# private
func _init_map() -> void:
	assert(map_scene != null)
	map = map_scene.instantiate()
	add_child(map)
	Log.trace(Log.Level.INFO, "ILevel.gd: Map instance created and added to the level");


func _load_waves() -> void:
	Log.trace(Log.Level.DEBUG, "LAODING WAVES");
	var filepath: String = "res://resources/levels/%s.json" % level_id
	var file := FileAccess.open(filepath, FileAccess.READ)
	assert(file, "Failed to open file %s" % filepath)

	var raw_content: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw_content)
	assert(parsed and parsed.has("waves"))

	waves = parsed["waves"]
	for i in range(len(waves)):
		print("%d :" % i)
		print(waves[i])
		print("")


func _build_state_machine() -> void:
	var builder := StateMachineBuilder.new()
	builder.build_initial_state(STATE_CONFIGURING)
	builder.build_state(STATE_VICTORY)
	builder.build_state(STATE_DEFEAT)
	builder.build_state(STATE_ERROR)
	builder.build_state(STATE_PAUSE)

	for i in waves.size():
		builder.build_state(STATE_WAVE % i)
		builder.build_transition(STATE_WAVE % i, STATE_CONFIGURING)
		builder.build_transition(STATE_WAVE % i, STATE_DEFEAT)
		builder.build_transition(STATE_WAVE % i, STATE_PAUSE)
		builder.build_transition(STATE_WAVE % i, STATE_ERROR)
		builder.build_transition(STATE_PAUSE, STATE_WAVE % i)
		if i == waves.size() - 1:
			builder.build_transition(STATE_WAVE % i, STATE_VICTORY)
		else:
			builder.build_transition(STATE_WAVE % i, STATE_WAVE % (i + 1))

	builder.build_transition(STATE_CONFIGURING, STATE_WAVE % 0)
	builder.build_transition(STATE_CONFIGURING, STATE_DEFEAT)
	builder.build_transition(STATE_DEFEAT, STATE_PAUSE)
	builder.build_transition(STATE_VICTORY, STATE_CONFIGURING)

	builder.build_transition(STATE_CONFIGURING, STATE_ERROR)
	builder.build_transition(STATE_DEFEAT, STATE_ERROR)
	builder.build_transition(STATE_VICTORY, STATE_ERROR)

	state_machine = builder.build()
	Log.trace(Log.Level.INFO, "State Machine built. Initial State: %s" % state_machine.get_current_state().name)


## State: Configuring
func _on_configuring(args = []) -> bool:
	var delta: float = args[0] if args.size() > 0 else 0.0
	Log.trace(Log.Level.INFO, "Entering CONFIGURING state. Delta: %s" % delta)
	Log.trace(Log.Level.INFO, "Configuration complete. Transitioning to PLAYING...")
	var success: bool = state_machine.toggle_state(STATE_WAVE_0)
	if not success:
		Log.trace(Log.Level.ERROR, "Transition to State(WAVE_0) failed.")
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
	var last_wave: bool = args[0] if args.size() > 0 and args[0] is bool else true
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


# signal


# event


# setget
