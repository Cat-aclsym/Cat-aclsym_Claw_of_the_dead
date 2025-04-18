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
@export var map_scene: PackedScene

var is_completed := false
var state_machine: StateMachine

var map: IMap = null
var waves: Array
var current_step: WaveStep = null
var current_wave: int = 0

var start_time: float
var end_time: float

# core
func _ready() -> void:
	# initialisation procedure
	# _init_map()
	_load_waves()
	_build_state_machine()
	state_machine.toggle_initial_state()


func _process(_delta: float) -> void:
	state_machine.handle_current_state([])

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

	for wave in parsed["waves"]:
		waves.append(Wave.new(wave))
		print(waves.back())


func _build_state_machine() -> void:
	var builder := StateMachineBuilder.new()
	builder.build_initial_state(STATE_CONFIGURING, _on_state_configuring)
	builder.build_state(STATE_VICTORY, _on_state_victory)
	builder.build_state(STATE_DEFEAT, _on_state_defeat)
	builder.build_state(STATE_ERROR, _on_state_error)
	builder.build_state(STATE_PAUSE, _on_state_pause)

	for i in waves.size():
		builder.build_state(STATE_WAVE % i, _on_state_wave)
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


func _next() -> void:
	Log.trace(Log.Level.DEBUG, "Wave(%d) completed." % current_step);
	current_step = null
	waves.pop_front()
	
	if waves.size() == 0:
		state_machine.toggle_state(STATE_VICTORY)
		return

	current_wave += 1
	Log.trace(Log.Level.DEBUG, "Starting Wave(%d)" % current_wave);
	state_machine.toggle_state(STATE_WAVE % current_wave)


func _execute_spawn_order(step: WaveStep) -> void:
	Log.trace(Log.Level.DEBUG, "Executing spawn order");
	pass


func _execute_wait_order(step: WaveStep) -> void:
	Log.trace(Log.Level.DEBUG, "Executing wait order");
	pass


## State: Configuring
func _on_state_configuring(args = []) -> bool:
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
func _on_state_wave(_args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering WAVE state.");
	
	var wave: Wave = waves.front()
	if wave.peak() == null:
		# Trigger next wave
		_next()
		return true
	
	if current_step == null:
		current_step = wave.pop()
		return true
	
	match current_step.order():
		WaveStep.Order.SPAWN:
			# TODO : execute spawn order
			pass

		WaveStep.Order.WAIT:
			# TODO : handle wait time
			pass

		_:
			Log.trace(Log.Level.ERROR, "Unhandled WaveStep Order.");
			return false

	return true


func _on_state_victory(_args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering VICTORY state.")
	return true

## State: Defeat
func _on_state_defeat(args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering DEFEAT state.")
	return true

## State: Pause
func _on_state_pause(args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering PAUSE state")
	get_tree().paused = true
	Engine.time_scale = 0
	Log.trace(Log.Level.INFO, "Game paused")
	return true

## State: Error
func _on_state_error(args = []) -> bool:
	Log.trace(Log.Level.ERROR, "Entering ERROR state")
	return true


func _on_wave_complete(last_wave: bool) -> void:
	Log.trace(Log.Level.INFO, "Wave complete signal received.")


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
