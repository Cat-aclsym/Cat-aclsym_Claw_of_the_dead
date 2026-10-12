## © [2026] A7 Studio. All rights reserved. Trademark.
## Level script that manages map, waves, state transitions, and enemy spawning.
class_name ILevel extends Node2D

signal stats_updated
signal wave_started(wave_number: int)

const BACKGROUND_MUSIC_STREAM: AudioStreamMP3 = preload("res://assets/audio/music/background.mp3")
## Extra delay between the last bonus spawn and the first wave.
const POST_SPECIAL_TILE_INTRO_DELAY_SECONDS: float = 2.0
const STATE_CONFIGURING: String = "CONFIGURING"
const STATE_DEFEAT: String = "DEFEAT"
const STATE_END: String = "END"
const STATE_PAUSE: String = "PAUSE"
const STATE_VICTORY: String = "VICTORY"
const STATE_WAVE: String = "WAVE_%d"
const STATE_WAVE_0: String = "WAVE_0"

# Exported Variables
@export var arc_id: String = "arc.XX"
@export var level_description: String
@export var level_id: String = "lev.XX"
@export var level_name: String
@export var map_scene: PackedScene

# Public Variables
static var current_level: ILevel = null

# stats, the placeholders below are replaced by the level JSON values in _load_level_data
var coins: int = 0: set = _set_coins
var current_step: WaveStep = null
var current_wave: int = 0
## Seconds of game time since the wave flow started. Frozen while paused and once the level has ended.
var elapsed_time: float = 0.0
var health: int = 1: set = _set_health
var map: IMap = null
var max_health: int = 1
var state_machine: StateMachine
var waves: Array[Wave] = []

# Private Variables
var _enemies_alive: int = 0
var _level_ended: bool = false
var _state_before_pause: String = ""
var _time_frozen: bool = false
var _time_scale_before_pause: float = 1.0
var _wave_flow_started: bool = false

@onready var clock: Clock = $Clock
@onready var popup_spawner: PopupSpawner = $PopupSpawner
@onready var _background_music: SoundEntity = $BackgroundMusic

# core
func _ready() -> void:
	assert(clock != null, "clock node not found")
	assert(popup_spawner != null, "popup_spawner node not found")
	assert(_background_music != null, "BackgroundMusic node not found")
	_background_music.stream = BACKGROUND_MUSIC_STREAM


func _process(delta: float) -> void:
	if _wave_flow_started and not _level_ended and not Global.paused:
		elapsed_time += delta


func _exit_tree() -> void:
	if _time_frozen:
		Engine.time_scale = _time_scale_before_pause
		_time_frozen = false


# public
## Returns the number of enemies currently alive on the map.
func get_enemies_alive() -> int:
	return _enemies_alive


## Starts the level by initializing map, waves, and state machine.
func start_level() -> void:
	position = Vector2i.ZERO
	ILevel.current_level = self
	Log.trace(Log.Level.INFO, "ILevel.start_level begin: level_id=%s tutorial_completed=%s" % [level_id, ProgressionManager.is_tutorial_completed()])
	_background_music.play()
	_init_map()
	_load_level_data()
	ChallengeManager.start_level_challenges(level_id)
	_build_state_machine()
	SignalUtil.connects([{SignalUtil.WHO: Global, SignalUtil.WHAT: "pause_changed", SignalUtil.TO: _on_pause_changed}])
	await map.play_special_tiles_intro_sequence()
	await get_tree().create_timer(POST_SPECIAL_TILE_INTRO_DELAY_SECONDS).timeout
	if _should_defer_wave_start_for_tutorial():
		Log.trace(Log.Level.INFO, "ILevel.start_level deferring wave start for tutorial")
		return
	Log.trace(Log.Level.INFO, "ILevel.start_level starting wave flow immediately")
	start_wave_flow()


## Starts the wave/state-machine loop if it is not already running.
func start_wave_flow() -> void:
	if _wave_flow_started:
		Log.trace(Log.Level.DEBUG, "ILevel.start_wave_flow ignored: already started")
		return
	_wave_flow_started = true
	Log.trace(Log.Level.INFO, "ILevel.start_wave_flow begin: level_id=%s current_wave=%d time_scale=%s" % [level_id, current_wave, Engine.time_scale])
	if not _time_frozen:
		Engine.time_scale = 1.0

	state_machine.toggle_initial_state()
	_announce_wave()

	clock.subscribe(_process_tick, 5)
	clock.start()


# privates
## Shows the banner of the current wave and tells the listeners that it starts.
func _announce_wave() -> void:
	popup_spawner.wave(tr("LEVEL.WAVE") % (current_wave + 1))
	wave_started.emit(current_wave + 1)


func _build_state_machine() -> void:
	var builder := StateMachineBuilder.new()
	builder.build_initial_state(STATE_CONFIGURING, _on_state_configuring)
	builder.build_state(STATE_VICTORY, _on_state_victory)
	builder.build_state(STATE_DEFEAT, _on_state_defeat)
	builder.build_state(STATE_PAUSE, _on_state_pause)
	builder.build_state(STATE_END)

	for i in waves.size():
		builder.build_state(STATE_WAVE % i, _on_state_wave)

	for i in waves.size():
		builder.build_transition(STATE_WAVE % i, STATE_CONFIGURING)
		builder.build_transition(STATE_WAVE % i, STATE_DEFEAT)
		builder.build_transition(STATE_WAVE % i, STATE_PAUSE)
		builder.build_transition(STATE_PAUSE, STATE_WAVE % i)
		builder.build_transition(STATE_WAVE % i, STATE_VICTORY if i == waves.size() - 1 else STATE_WAVE % (i + 1))

	builder.build_transition(STATE_CONFIGURING, STATE_WAVE_0)
	builder.build_transition(STATE_CONFIGURING, STATE_DEFEAT)
	builder.build_transition(STATE_CONFIGURING, STATE_PAUSE)
	builder.build_transition(STATE_PAUSE, STATE_CONFIGURING)
	builder.build_transition(STATE_DEFEAT, STATE_PAUSE)
	builder.build_transition(STATE_VICTORY, STATE_CONFIGURING)
	builder.build_transition(STATE_VICTORY, STATE_END)
	builder.build_transition(STATE_DEFEAT, STATE_END)

	state_machine = builder.build()
	Log.trace(Log.Level.INFO, "State machine built. Initial state: %s" % state_machine.get_current_state().name)


func _init_map() -> void:
	assert(map_scene != null, "Map scene is null. Cannot instantiate map.")
	map = map_scene.instantiate()
	add_child(map)
	Log.trace(Log.Level.INFO, "Map instance created and added to the level.")


## Reads the waves, the starting coins and the max health from the level JSON.
func _load_level_data() -> void:
	var parsed: Dictionary = JsonUtil.load_dict("res://resources/levels/%s.json" % level_id)
	assert(parsed.has("waves") and parsed.has("start_coins") and parsed.has("max_health"), "Missing 'waves', 'start_coins' or 'max_health' key for level %s." % level_id)

	coins = int(parsed.get("start_coins", coins))
	max_health = int(parsed.get("max_health", max_health))
	health = max_health

	for wave_data: Array in parsed.get("waves", []):
		waves.append(Wave.new(wave_data))


func _next_wave() -> void:
	waves.pop_front()

	if waves.is_empty() and current_step == null:
		state_machine.toggle_state(STATE_VICTORY)
		return
	current_wave += 1
	_announce_wave()
	state_machine.toggle_state(STATE_WAVE % current_wave)


## Called when an enemy dies or escapes, both take it out of the map.
func _on_enemy_removed() -> void:
	_enemies_alive -= 1


func _on_enemy_spawn() -> void:
	_enemies_alive += 1


func _on_level_end(victory: bool) -> void:
	_level_ended = true
	clock.stop()
	_background_music.stop()
	Global.request_pause(&"level_end")

	var end_game_menu_instance: EndGame = ScenesLoader.END_GAME_MENU.instantiate()
	if is_instance_valid(Global.ui):
		# A tutorial still running owns Dialogic, it stops here so that it doesn't block the end screen dialogues
		Global.ui.tutorial_manager.on_level_ended()
		Global.ui.add_child(end_game_menu_instance)
	end_game_menu_instance.init(victory)
	state_machine.toggle_state(STATE_END)


## Freezes the level (time scale and PAUSE state) when the game gets paused, and restores it on resume.
## [br]Applied right away, the state machine tick is not involved.
func _on_pause_changed(is_paused: bool) -> void:
	if _level_ended or state_machine == null:
		return

	var current_state_id: String = state_machine.get_current_state().name
	var should_freeze_time: bool = is_paused and Global.is_time_frozen()
	if should_freeze_time and not _time_frozen:
		_time_scale_before_pause = Engine.time_scale if Engine.time_scale > 0.0 else 1.0
		Engine.time_scale = 0.0
		_time_frozen = true
	elif not should_freeze_time and _time_frozen:
		Engine.time_scale = _time_scale_before_pause
		_time_frozen = false

	if is_paused:
		if current_state_id == STATE_CONFIGURING or current_state_id.begins_with("WAVE_"):
			_state_before_pause = current_state_id
			state_machine.toggle_state(STATE_PAUSE)
		return

	if current_state_id == STATE_PAUSE and not _state_before_pause.is_empty():
		state_machine.toggle_state(_state_before_pause)


# states
func _on_state_configuring(_args: Array = []) -> bool:
	state_machine.toggle_state(STATE_WAVE_0)
	return true


func _on_state_defeat(_args: Array = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering DEFEAT state.")

	_on_level_end(false)
	return true


## The pause itself is applied right away by [method _on_pause_changed], nothing is left to do on a tick.
func _on_state_pause(_args: Array = []) -> bool:
	return true


func _on_state_victory(_args: Array = []) -> bool:
	Log.trace(Log.Level.INFO, "Entering VICTORY state.")
	ChallengeManager.check_victory_conditions()

	_on_level_end(true)
	return true


func _on_state_wave(_args: Array = []) -> bool:
	var wave: Wave = waves.front()

	# if no more steps and no enemy alive -> trigger next wave
	if (wave == null or wave.peak() == null) and _enemies_alive == 0 and current_step == null:
		_next_wave()
		return true

	# if no current step -> tigger next step
	if current_step == null:
		current_step = wave.pop()
		return true

	# execute current step then check if it is over
	current_step.exec()
	if current_step.is_over():
		current_step = wave.pop()

	return true


## Custom ticker callback
func _process_tick() -> void:
	assert(state_machine)
	state_machine.handle_current_state([])


# setget
## Update player's coin count and emits stats_updated signal
func _set_coins(new_value: int) -> void:
	coins = new_value
	stats_updated.emit()


## Clamps the health to [0, max_health], notifies the damage actually taken and triggers the defeat at 0.
func _set_health(new_value: int) -> void:
	if health <= 0:
		return

	var clamped_value: int = clampi(new_value, 0, max_health)
	var damage_taken: int = maxi(health - clamped_value, 0)
	health = clamped_value
	# The challenges read the new health, e.g. a lethal hit
	if damage_taken > 0:
		ChallengeManager.notify_damage(damage_taken)
	stats_updated.emit()

	if health <= 0 and state_machine.toggle_state(STATE_DEFEAT):
		Log.trace(Log.Level.INFO, "Player defeated.")


func _should_defer_wave_start_for_tutorial() -> bool:
	return level_id == "lev.01" and not ProgressionManager.is_tutorial_completed()
