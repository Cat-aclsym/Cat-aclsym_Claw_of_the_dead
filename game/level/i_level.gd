## © [2026] A7 Studio. All rights reserved. Trademark.
## Level script that manages map, waves, state transitions, and enemy spawning.
class_name ILevel extends Node2D

signal stats_updated
signal wave_started(wave_number: int)

const BACKGROUND_MUSIC_STREAM: AudioStreamMP3 = preload("res://assets/audio/music/background.mp3")
## Extra delay between the last bonus spawn and the first wave.
const POST_SPECIAL_TILE_INTRO_DELAY_SECONDS: float = 2.0
## Maximum lateral spawn deviation of an enemy, in tile fractions.
const SPAWN_OFFSET_MAX_TILES: float = 0.2
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
var _enemies_spawned: int = 0
var _level_ended: bool = false
var _state_before_pause: String = ""
var _time_frozen: bool = false
var _time_scale_before_pause: float = 1.0
var _wave_flow_started: bool = false

@onready var popup_spawner: PopupSpawner = $PopupSpawner
@onready var _background_music: SoundEntity = $BackgroundMusic
## Ticks the state machine, twice per second of game time.
@onready var _wave_tick_timer: Timer = $WaveTickTimer

# core
func _ready() -> void:
	assert(popup_spawner != null, "popup_spawner node not found")
	assert(_background_music != null, "BackgroundMusic node not found")
	assert(_wave_tick_timer != null, "WaveTickTimer node not found")
	SignalUtil.connects([{SignalUtil.WHO: _wave_tick_timer, SignalUtil.WHAT: "timeout", SignalUtil.TO: _process_tick}])
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


## Puts [param enemy] on [param path] with a small lateral offset and counts it alive until it dies or escapes.
func spawn_enemy(path: Path2D, enemy: IEnemy) -> void:
	var path_follow: PathFollow2D = PathFollow2D.new()
	path_follow.loop = false
	path_follow.rotates = false

	path.add_child(path_follow)
	var spawn_offset: float = (map.get_tile_step_distance() if map else IMap.DEFAULT_TILE_STEP_DISTANCE) * SPAWN_OFFSET_MAX_TILES
	path_follow.v_offset = randf_range(-spawn_offset, spawn_offset)

	enemy.name = "ENEMY_%d" % _enemies_spawned
	_enemies_spawned += 1
	enemy.path = path
	enemy.path_follow = path_follow

	SignalUtil.connects([
		{SignalUtil.WHO: enemy, SignalUtil.WHAT: "died", SignalUtil.TO: _on_enemy_removed},
		{SignalUtil.WHO: enemy, SignalUtil.WHAT: "escaped", SignalUtil.TO: _on_enemy_removed},
	])
	_enemies_alive += 1
	path_follow.add_child(enemy)


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

	_announce_wave()
	_wave_tick_timer.start()


# privates
## Shows the banner of the current wave and tells the listeners that it starts.
func _announce_wave() -> void:
	popup_spawner.wave(tr("LEVEL.WAVE") % (current_wave + 1))
	wave_started.emit(current_wave + 1)


func _build_state_machine() -> void:
	state_machine = StateMachine.new()
	state_machine.add_state(STATE_CONFIGURING, _on_state_configuring, true)
	state_machine.add_state(STATE_VICTORY, _on_state_victory)
	state_machine.add_state(STATE_DEFEAT, _on_state_defeat)
	state_machine.add_state(STATE_PAUSE)
	state_machine.add_state(STATE_END)

	for i in waves.size():
		state_machine.add_state(STATE_WAVE % i, _on_state_wave)

	for i in waves.size():
		state_machine.allow(STATE_WAVE % i, STATE_CONFIGURING)
		state_machine.allow(STATE_WAVE % i, STATE_DEFEAT)
		state_machine.allow(STATE_WAVE % i, STATE_PAUSE)
		state_machine.allow(STATE_PAUSE, STATE_WAVE % i)
		state_machine.allow(STATE_WAVE % i, STATE_VICTORY if i == waves.size() - 1 else STATE_WAVE % (i + 1))

	state_machine.allow(STATE_CONFIGURING, STATE_WAVE_0)
	state_machine.allow(STATE_CONFIGURING, STATE_DEFEAT)
	state_machine.allow(STATE_CONFIGURING, STATE_PAUSE)
	state_machine.allow(STATE_PAUSE, STATE_CONFIGURING)
	state_machine.allow(STATE_DEFEAT, STATE_PAUSE)
	state_machine.allow(STATE_VICTORY, STATE_CONFIGURING)
	state_machine.allow(STATE_VICTORY, STATE_END)
	state_machine.allow(STATE_DEFEAT, STATE_END)
	Log.trace(Log.Level.INFO, "State machine built. Initial state: %s" % state_machine.current_state_id)


func _init_map() -> void:
	assert(map_scene != null, "Map scene is null. Cannot instantiate map.")
	map = map_scene.instantiate()
	add_child(map)
	Log.trace(Log.Level.INFO, "Map instance created and added to the level.")


## Reads the waves, the starting coins and the max health from the level JSON.
func _load_level_data() -> void:
	var parsed: Dictionary = JsonUtil.load_dict("res://data/levels/%s.json" % level_id)
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


func _on_level_end(victory: bool) -> void:
	_level_ended = true
	_wave_tick_timer.stop()
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

	var current_state_id: String = state_machine.current_state_id
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
func _on_state_configuring() -> void:
	state_machine.toggle_state(STATE_WAVE_0)


func _on_state_defeat() -> void:
	Log.trace(Log.Level.INFO, "Entering DEFEAT state.")

	_on_level_end(false)


func _on_state_victory() -> void:
	Log.trace(Log.Level.INFO, "Entering VICTORY state.")
	ChallengeManager.check_victory_conditions()

	_on_level_end(true)


func _on_state_wave() -> void:
	var wave: Wave = waves.front()

	# if no more steps and no enemy alive -> trigger next wave
	if (wave == null or wave.peak() == null) and _enemies_alive == 0 and current_step == null:
		_next_wave()
		return

	# if no current step -> tigger next step
	if current_step == null:
		current_step = wave.pop()
		return

	# execute current step then check if it is over
	current_step.exec()
	if current_step.is_over():
		current_step = wave.pop()


## Called by the wave tick timer.
func _process_tick() -> void:
	assert(state_machine)
	state_machine.tick()


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
