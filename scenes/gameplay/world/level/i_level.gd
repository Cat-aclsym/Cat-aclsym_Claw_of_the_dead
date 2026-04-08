## © [2026] A7 Studio. All rights reserved. Trademark.
## Level script that manages map, waves, state transitions, and enemy spawning.
class_name ILevel extends Node2D

signal stats_updated

# Constants
const STATE_CONFIGURING: String = "CONFIGURING"
const STATE_VICTORY: String = "VICTORY"
const STATE_DEFEAT: String = "DEFEAT"
const STATE_ERROR: String = "ERROR"
const STATE_PAUSE: String = "PAUSE"
const STATE_WAVE: String = "WAVE_%d"
const STATE_WAVE_0: String = "WAVE_0"
const STATE_END: String = "END"

## Extra delay between the last bonus spawn and the first wave.
const POST_SPECIAL_TILE_INTRO_DELAY_SECONDS: float = 2.0

# Exported Variables
@export var level_id: String = "lev.XX"
@export var level_name: String
@export var level_description: String
@export var arc_id: String = "arc.XX"
@export var map_scene: PackedScene

# Public Variables
static var current_level: ILevel = null

var enemies_scene: Dictionary = {}
var state_machine: StateMachine
var map: IMap = null
var waves: Array[Wave] = []
var current_step: WaveStep = null
var current_wave: int = 0
var start_time: float
var end_time: float

# stats
var coins: int = 50: set = _set_coins
var health: int = 20: set = _set_health

# Private Variables
var _enemies_alive: int = 0
var _time_scale_before_pause: float = 1.0


@onready var clock: Clock = $Clock
@onready var popup_spawner: PopupSpawner = $PopupSpawner

# core
## Custom ticker callback
func _process_tick() -> void:
	assert(state_machine)
	state_machine.handle_current_state([])


# public
## Starts the level by initializing map, waves, and state machine.
func start_level() -> void:
	position = Vector2i.ZERO
	ILevel.current_level = self
	_init_map()
	_load_waves()
	ChallengeManager.start_level_challenges(level_id)
	_build_state_machine()
	await map.play_special_tiles_intro_sequence()
	await get_tree().create_timer(POST_SPECIAL_TILE_INTRO_DELAY_SECONDS).timeout
	state_machine.toggle_initial_state()
	start_time = Time.get_unix_time_from_system()
	popup_spawner.wave("Wave %s" % [current_wave+1])

	clock.subscribe(_process_tick, 5)
	clock.start()


# privates
func _init_map() -> void:
	assert(map_scene != null, "Map scene is null. Cannot instantiate map.")
	map = map_scene.instantiate()
	add_child(map)
	Log.trace(Log.Level.INFO, "Map instance created and added to the level.")


func _load_waves() -> void:
	var filepath: String = "res://resources/levels/%s.json" % level_id
	var file := FileAccess.open(filepath, FileAccess.READ)
	assert(file != null, "Failed to open wave file: %s" % filepath)

	var raw_content: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw_content)
	assert(parsed != null and parsed.has("waves"), "Failed to parse waves or missing 'waves' key in JSON.")

	for wave in parsed["waves"]:
		waves.append(Wave.new(wave))


func _build_state_machine() -> void:
	var builder := StateMachineBuilder.new()
	builder.build_initial_state(STATE_CONFIGURING, _on_state_configuring)
	builder.build_state(STATE_VICTORY, _on_state_victory)
	builder.build_state(STATE_DEFEAT, _on_state_defeat)
	builder.build_state(STATE_ERROR, _on_state_error)
	builder.build_state(STATE_PAUSE, _on_state_pause)
	builder.build_state(STATE_END)

	for i in waves.size():
		builder.build_state(STATE_WAVE % i, _on_state_wave)

	for i in waves.size():
		builder.build_transition(STATE_WAVE % i, STATE_CONFIGURING)
		builder.build_transition(STATE_WAVE % i, STATE_DEFEAT)
		builder.build_transition(STATE_WAVE % i, STATE_PAUSE)
		builder.build_transition(STATE_WAVE % i, STATE_ERROR)
		builder.build_transition(STATE_PAUSE, STATE_WAVE % i)
		builder.build_transition(STATE_WAVE % i, STATE_VICTORY if i == waves.size() - 1 else STATE_WAVE % (i + 1))

	builder.build_transition(STATE_CONFIGURING, STATE_WAVE_0)
	builder.build_transition(STATE_CONFIGURING, STATE_DEFEAT)
	builder.build_transition(STATE_CONFIGURING, STATE_ERROR)
	builder.build_transition(STATE_DEFEAT, STATE_PAUSE)
	builder.build_transition(STATE_DEFEAT, STATE_ERROR)
	builder.build_transition(STATE_VICTORY, STATE_CONFIGURING)
	builder.build_transition(STATE_VICTORY, STATE_ERROR)
	builder.build_transition(STATE_VICTORY, STATE_END)
	builder.build_transition(STATE_DEFEAT, STATE_END)

	state_machine = builder.build()
	Log.trace(Log.Level.INFO, "State machine built. Initial state: %s" % state_machine.get_current_state().name)


func _next_wave() -> void:
	waves.pop_front() # NOTE : may shit later with save system

	if waves.is_empty() and current_step == null:
		state_machine.toggle_state(STATE_VICTORY)
		return
	current_wave += 1
	popup_spawner.wave("Wave %s" % [current_wave+1])
	state_machine.toggle_state(STATE_WAVE % current_wave)


func _next_step() -> void:
	current_step = waves.front().pop()


# states
func _on_state_configuring(_args = []) -> bool:
	state_machine.toggle_state(STATE_WAVE_0)
	return true


func _on_state_wave(_args = []) -> bool:
	var wave: Wave = waves.front()

	# if no more steps and no enemy alive -> trigger next wave
	if (wave == null or wave.peak() == null) and _enemies_alive == 0 and current_step == null:
		_next_wave()
		return true

	# if no current step -> tigger next step
	if current_step == null:
		_next_step()
		return true

	# execute current step then check if it is over
	current_step.exec()
	if current_step.is_over():
		_next_step()

	return true

func _on_level_end(_args = []) -> void:
	clock.stop()
	Global.paused = true

	end_time = Time.get_unix_time_from_system()
	var end_game_menu_instance: EndGame = ScenesLoader.END_GAME_MENU.instantiate()
	Global.ui.add_child(end_game_menu_instance)
	end_game_menu_instance.init(true)
	state_machine.toggle_state(STATE_END)


func _on_state_victory(_args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering VICTORY state.")
	ChallengeManager.check_victory_conditions()

	_on_level_end()
	return true


func _on_state_defeat(_args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering DEFEAT state.")

	_on_level_end()
	return true


func _on_state_pause(_args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering PAUSE state.")
	_time_scale_before_pause = Engine.time_scale if Engine.time_scale > 0 else 1.0
	Engine.time_scale = 0
	Global.paused = true
	Log.trace(Log.Level.INFO, "Game paused")
	return true


func _on_state_error(_args = []) -> bool:
	Log.trace(Log.Level.ERROR, "Entering ERROR state.")
	return false


# setget
## Updates coin count and emits stats_updated signal
func _set_health(new_value: int) -> void:
	if health <= 0:
		return

	if new_value < health:
		ChallengeManager.notify_damage(health - new_value)

	health = new_value
	stats_updated.emit()

	if health <= 0 and state_machine.toggle_state(STATE_DEFEAT):
		Log.trace(Log.Level.INFO, "Player defeated.")


func _on_enemy_die() -> void:
	_enemies_alive -= 1


func _on_enemy_spawn() -> void:
	_enemies_alive += 1


## Sets the game to paused state, affecting both time scale and state machine.
func pause() -> void:
	if state_machine.get_current_state().name != STATE_PAUSE:
		state_machine.toggle_state(STATE_PAUSE)


## Resumes the game from pause state.
## [br]Restores time scale, then transitions back to current wave if in PAUSE state.
func resume_from_pause() -> void:
	if state_machine.get_current_state().name == STATE_PAUSE:
		Engine.time_scale = _time_scale_before_pause
		Global.paused = false
		state_machine.toggle_state(STATE_WAVE % current_wave)


## Update player's coin count
func _set_coins(new_value: int) -> void:
	coins = new_value
	stats_updated.emit()
