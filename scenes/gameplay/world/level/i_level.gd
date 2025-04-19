## © [2024] A7 Studio. All rights reserved. Trademark.
## Level script that manages map, waves, state transitions, and enemy spawning.
## @experimental
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

# Exported Variables
@export var level_id: String = "lev.XX"
@export var level_name: String
@export var map_scene: PackedScene

# Public Variables
static var current_level: ILevel = null

var enemies_scene: Dictionary = {}
var is_completed: bool = false
var state_machine: StateMachine
var map: IMap = null
var waves: Array = []
var current_step: WaveStep = null
var current_wave: int = 0
var start_time: float
var end_time: float

var coins: int = 75: set = _set_coins
var health: int = 20000: set = _set_health

# Private Variables
var _frame_counter: int = 0 # Temporary frame counter for spawn delay
var _enemies_alive: int = 0

var tmp_current_state: String = "n/a"

@onready var popup_spawner: PopupSpawner = $PopupSpawner

# core
func _process(_delta: float) -> void:
	if state_machine:
		state_machine.handle_current_state([])
		tmp_current_state = state_machine.get_current_state().name


# public
## Starts the level by initializing map, waves, and state machine.
func start_level() -> void:
	ILevel.current_level = self
	_init_map()
	_load_waves()
	_build_state_machine()
	state_machine.toggle_initial_state()
	start_time = Time.get_unix_time_from_system()
	popup_spawner.wave("Wave %s" % [current_wave+1])


## Returns a tower instance by name.
func get_tower_by_name(tower_name: String) -> ITower:
	for child in map.get_children():
		if child is ITower:
			var tower: ITower = child as ITower
			if tower.name == tower_name:
				return tower
	return null


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
	waves.pop_front()
	if waves.is_empty() and current_step == null: # oupsi 
		state_machine.toggle_state(STATE_VICTORY)
		return
	current_wave += 1
	popup_spawner.wave("Wave %s" % [current_wave+1])
	state_machine.toggle_state(STATE_WAVE % current_wave)


func _next_step() -> void:
	current_step = waves.front().pop()


func _process_frame_counter() -> bool:
	if _frame_counter < 60:
		_frame_counter += 1
		return true
	_frame_counter = 0
	return false


func _execute_spawn_order(step: WaveStep) -> void:
	var enemy_id: String = step.data()[WaveStep.ENEMY_ID]
	var spawner_index: int = step.data()[WaveStep.SPAWNER]

	if not enemies_scene.has(enemy_id):
		enemies_scene[enemy_id] = load("res://scenes/gameplay/entities/enemy/enemies/%s.tscn" % enemy_id)

	var enemy: IEnemy = enemies_scene[enemy_id].instantiate()
	enemy.connect("die", func(): _enemies_alive -= 1)
	EnemySpawner.spawn_enemy(map.paths[spawner_index], enemy)
	step.data()[WaveStep.COUNT] -= 1
	_enemies_alive += 1


func _spawn_order_post_execution() -> void:
	if current_step.data()[WaveStep.COUNT] == 0:
		_next_step()


func _execute_wait_order(step: WaveStep) -> void:
	if not step.data().has("start"):
		step.data()["start"] = Time.get_unix_time_from_system()


func _wait_order_post_execution() -> void:
	var elapsed: float = Time.get_unix_time_from_system() - start_time
	if elapsed >= current_step.data()[WaveStep.WAIT_S]:
		_next_step()

# states
func _on_state_configuring(_args = []) -> bool:
	state_machine.toggle_state(STATE_WAVE_0)
	return true


func _on_state_wave(_args = []) -> bool:
	var wave: Wave = waves.front()

	if wave.peak() == null and _enemies_alive == 0:
		_next_wave()
		return true

	if current_step == null:
		_next_step()
		return true

	match current_step.order():
		WaveStep.Order.SPAWN:
			if _process_frame_counter():
				return true
			_execute_spawn_order(current_step)
			_spawn_order_post_execution()
			return true

		WaveStep.Order.WAIT:
			_execute_wait_order(current_step)
			_wait_order_post_execution()
			return true

		_:
			Log.trace(Log.Level.ERROR, "Unhandled WaveStep order.")
			return false


func _on_state_victory(_args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering VICTORY state.")
	end_time = Time.get_unix_time_from_system()
	var end_game_menu_instance: EndGame = ScenesLoader.END_GAME_MENU.instantiate()
	Global.ui.add_child(end_game_menu_instance)
	end_game_menu_instance.init(true)
	state_machine.toggle_state(STATE_END)
	return true


func _on_state_defeat(_args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering DEFEAT state.")
	end_time = Time.get_unix_time_from_system()
	var end_game_menu_instance: EndGame = ScenesLoader.END_GAME_MENU.instantiate()
	Global.ui.add_child(end_game_menu_instance)
	end_game_menu_instance.init(false)
	state_machine.toggle_state(STATE_END)
	return true


func _on_state_pause(_args = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering PAUSE state.")
	get_tree().paused = true
	Engine.time_scale = 0
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
	health = new_value
	stats_updated.emit()

	if health <= 0 and state_machine.toggle_state(STATE_DEFEAT):
		Log.trace(Log.Level.INFO, "Player defeated.")


## Update player's coin count
func _set_coins(new_value: int) -> void:
	coins = new_value
	stats_updated.emit()
