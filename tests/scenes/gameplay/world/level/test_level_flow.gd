## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The level state sequence, its ticks, the pause, the enemy counting and the victory and defeat flows.
## [br]The level ticker is stopped once the wave flow started and the tests tick the level by hand, so that they don't depend on real time.
extends GdUnitTestSuite

const BIG_DADDY_ID: String = "big_daddy"
const DEFAULT_ID: String = "default_zombie"
const FLOW_START_TIMEOUT_MS: int = 10000
const INTRO_TIME_SCALE: float = 8.0
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const MAX_TICKS: int = 500
const PAUSE_SOURCE: StringName = &"test_pause"
const SPLITTER_ID: String = "splitter_zombie"
const SPLIT_ID: String = "small_zombie"
## Seconds of game time between two ticks of the level.
const TICK_INTERVAL_S: float = 0.5
## Level with three waves: spawns and waits.
const WAVES_LEVEL_ID: String = "lev.02"
## Level with two waves, the shortest one to play until its victory.
const VICTORY_LEVEL_ID: String = "lev.05"
## Game time that makes any wait step over.
const WAIT_SKIP_S: float = 100.0

var _data_before: ProgressionData = null
var _level: ILevel = null
var _persistence_before: bool = true


func before_test() -> void:
	_data_before = ProgressionManager.data
	_persistence_before = ProgressionManager.persistence_enabled
	ProgressionManager.data = ProgressionData.new()
	ProgressionManager.data.parameters.tutorial_completed = true
	ProgressionManager.persistence_enabled = false
	# A first sighting would pop the reveal screen up
	for enemy_id: String in StatsDB.get_enemy_ids():
		ProgressionManager.mark_enemy_seen(enemy_id)


func after_test() -> void:
	Engine.time_scale = 1.0
	# The end screen starts a one-time dialogue, it would still run in the next suite
	await TestDialogic.reset()
	if is_instance_valid(_level):
		_level.queue_free()
		await _level.tree_exited
	_level = null
	ILevel.current_level = null
	if is_instance_valid(Global.ui):
		for child: Node in Global.ui.get_children():
			if child is EndGame:
				child.queue_free()
	ProgressionManager.data = _data_before
	ProgressionManager.persistence_enabled = _persistence_before


@warning_ignore("unused_parameter")
func test_the_level_goes_through_the_configuring_state_then_each_wave_on_ticks(timeout: int = 30000) -> void:
	await _start_level(WAVES_LEVEL_ID)
	var announced_waves: Array[int] = []
	SignalUtil.connects([{SignalUtil.WHO: _level, SignalUtil.WHAT: "wave_started", SignalUtil.TO: announced_waves.append}])
	assert_str(_state_of()).is_equal(ILevel.STATE_CONFIGURING)

	await _tick()
	assert_str(_state_of()).is_equal(ILevel.STATE_WAVE_0)
	assert_object(_level.current_step).is_null()

	# One tick takes the first step of the wave, the next one executes it
	await _tick()
	assert_object(_level.current_step).is_instanceof(WaveStepSpawn)
	assert_int(_level.get_enemies_alive()).is_equal(0)

	await _tick()
	assert_int(_level.get_enemies_alive()).is_equal(1)
	assert_object(_level.current_step).is_instanceof(WaveStepWait)

	# The wait starts at its first execution and lasts game time
	await _tick()
	assert_object(_level.current_step).is_instanceof(WaveStepWait)
	await _tick()
	assert_object(_level.current_step).is_instanceof(WaveStepWait)
	_level.elapsed_time += WAIT_SKIP_S
	await _tick()
	assert_object(_level.current_step).is_instanceof(WaveStepSpawn)

	await _tick()
	assert_int(_level.get_enemies_alive()).is_equal(2)
	assert_object(_level.current_step).is_null()

	# The next wave waits for the last enemy
	await _tick()
	assert_str(_state_of()).is_equal(ILevel.STATE_WAVE_0)
	await _kill_all_enemies()
	assert_int(_level.get_enemies_alive()).is_equal(0)

	await _tick()
	assert_str(_state_of()).is_equal(ILevel.STATE_WAVE % 1)
	assert_int(_level.current_wave).is_equal(1)
	assert_array(announced_waves).contains_exactly([2])


@warning_ignore("unused_parameter")
func test_an_invalid_transition_is_refused(timeout: int = 30000) -> void:
	await _start_level(WAVES_LEVEL_ID)

	assert_bool(_level.state_machine.toggle_state(ILevel.STATE_VICTORY)).is_false()
	assert_bool(_level.state_machine.toggle_state(ILevel.STATE_END)).is_false()
	assert_bool(_level.state_machine.toggle_state("NO_SUCH_STATE")).is_false()
	assert_str(_state_of()).is_equal(ILevel.STATE_CONFIGURING)

	assert_bool(_level.state_machine.toggle_state(ILevel.STATE_WAVE_0)).is_true()
	assert_str(_state_of()).is_equal(ILevel.STATE_WAVE_0)
	assert_bool(_level.state_machine.toggle_state(ILevel.STATE_WAVE % 2)).is_false()
	assert_str(_state_of()).is_equal(ILevel.STATE_WAVE_0)


@warning_ignore("unused_parameter")
func test_the_victory_ends_the_level_and_a_defeat_after_it_is_ignored(timeout: int = 60000) -> void:
	await _start_level(VICTORY_LEVEL_ID)
	await _play_until_victory()
	assert_str(_state_of()).is_equal(ILevel.STATE_VICTORY)
	assert_bool(Global.paused).is_false()

	# The level is already won: the lethal damage can not turn it into a defeat
	_level.health = 0
	assert_str(_state_of()).is_equal(ILevel.STATE_VICTORY)

	# The end of the level stops the ticker
	var ticker: Timer = _level.get_node("WaveTickTimer")
	ticker.start()
	await _tick()
	assert_str(_state_of()).is_equal(ILevel.STATE_END)
	assert_bool(Global.paused).is_true()
	assert_int(_level.get_enemies_alive()).is_equal(0)
	assert_bool(ticker.is_stopped()).is_true()

	_level.health = 0
	assert_str(_state_of()).is_equal(ILevel.STATE_END)


@warning_ignore("unused_parameter")
func test_a_big_daddy_escaping_defeats_the_level(timeout: int = 30000) -> void:
	await _start_level(WAVES_LEVEL_ID)
	await _tick()
	assert_str(_state_of()).is_equal(ILevel.STATE_WAVE_0)

	var boss: IEnemy = await _spawn(BIG_DADDY_ID)
	assert_int(_level.get_enemies_alive()).is_equal(1)
	boss._path_finished_state()

	assert_int(_level.health).is_equal(0)
	assert_int(_level.get_enemies_alive()).is_equal(0)
	assert_str(_state_of()).is_equal(ILevel.STATE_DEFEAT)
	assert_bool(Global.paused).is_false()

	await _tick()
	assert_str(_state_of()).is_equal(ILevel.STATE_END)
	assert_bool(Global.paused).is_true()


@warning_ignore("unused_parameter")
func test_an_escaping_enemy_costs_health(timeout: int = 30000) -> void:
	await _start_level(WAVES_LEVEL_ID)
	await _tick()
	var enemy: IEnemy = await _spawn(DEFAULT_ID)
	var health_before: int = _level.health

	enemy._path_finished_state()

	assert_int(_level.get_enemies_alive()).is_equal(0)
	assert_int(_level.health).is_equal(health_before - enemy.escape_damage)
	assert_str(_state_of()).is_equal(ILevel.STATE_WAVE_0)


@warning_ignore("unused_parameter")
func test_the_pause_freezes_the_configuring_state(timeout: int = 30000) -> void:
	await _start_level(WAVES_LEVEL_ID)

	Global.request_pause(PAUSE_SOURCE)
	assert_str(_state_of()).is_equal(ILevel.STATE_PAUSE)
	await _tick()
	assert_str(_state_of()).is_equal(ILevel.STATE_PAUSE)

	Global.release_pause(PAUSE_SOURCE)
	assert_str(_state_of()).is_equal(ILevel.STATE_CONFIGURING)
	await _tick()
	assert_str(_state_of()).is_equal(ILevel.STATE_WAVE_0)


@warning_ignore("unused_parameter")
func test_the_pause_freezes_a_wave_and_resumes_it(timeout: int = 30000) -> void:
	await _start_level(WAVES_LEVEL_ID)
	await _tick()
	assert_str(_state_of()).is_equal(ILevel.STATE_WAVE_0)

	Global.request_pause(PAUSE_SOURCE)
	assert_str(_state_of()).is_equal(ILevel.STATE_PAUSE)
	await _tick()
	assert_object(_level.current_step).is_null()

	Global.release_pause(PAUSE_SOURCE)
	assert_str(_state_of()).is_equal(ILevel.STATE_WAVE_0)
	await _tick()
	assert_object(_level.current_step).is_not_null()


@warning_ignore("unused_parameter")
func test_the_pause_does_not_reopen_an_ended_level(timeout: int = 60000) -> void:
	await _start_level(VICTORY_LEVEL_ID)
	await _play_until_victory()
	await _tick()
	assert_str(_state_of()).is_equal(ILevel.STATE_END)

	Global.request_pause(PAUSE_SOURCE)
	assert_str(_state_of()).is_equal(ILevel.STATE_END)
	Global.release_pause(PAUSE_SOURCE)
	assert_str(_state_of()).is_equal(ILevel.STATE_END)


@warning_ignore("unused_parameter")
func test_the_enemies_alive_include_the_children_of_a_splitter(timeout: int = 30000) -> void:
	await _start_level(WAVES_LEVEL_ID)
	await _tick()
	var spawn_count: int = int(StatsDB.get_enemy(SPLITTER_ID)["extra"]["spawn_count"])

	var splitter: IEnemy = await _spawn(SPLITTER_ID)
	assert_int(_level.get_enemies_alive()).is_equal(1)

	splitter._dead_state()
	await get_tree().process_frame
	assert_int(_level.get_enemies_alive()).is_equal(spawn_count)
	assert_int(_enemies_in_group(SPLIT_ID)).is_equal(spawn_count)

	await _kill_all_enemies()
	assert_int(_level.get_enemies_alive()).is_equal(0)


func _enemies_in_group(enemy_id: String) -> int:
	return get_tree().get_nodes_in_group("enemies").filter(func(node: Node) -> bool: return (node as IEnemy).enemy_id == enemy_id and not (node as IEnemy).is_already_dead).size()


func _kill_all_enemies() -> void:
	for _attempt: int in MAX_TICKS:
		if _level.get_enemies_alive() == 0:
			return
		for node: Node in get_tree().get_nodes_in_group("enemies"):
			var enemy: IEnemy = node as IEnemy
			if not enemy.is_already_dead:
				enemy._dead_state()
		await get_tree().process_frame


## Plays the waves until the level is won: the waits are skipped and the enemies die as soon as they spawn.
func _play_until_victory() -> void:
	for _attempt: int in MAX_TICKS:
		if _state_of() == ILevel.STATE_VICTORY:
			return
		_level.elapsed_time += WAIT_SKIP_S
		await _tick()
		await _kill_all_enemies()


func _spawn(enemy_id: String) -> IEnemy:
	WaveStep.build({WaveStep.ENEMY_ID: enemy_id, WaveStep.COUNT: 1, WaveStep.SPAWNER: 0}).exec()
	await get_tree().process_frame
	return get_tree().get_nodes_in_group("enemies").filter(func(node: Node) -> bool: return (node as IEnemy).enemy_id == enemy_id)[0]


## Starts the level and stops its ticker once the wave flow runs, the level is in its CONFIGURING state.
func _start_level(level_id: String) -> void:
	scene_runner(MAIN_SCENE_PATH)
	# The special tiles intro and its delay are real time, the wave flow resets the time scale
	Engine.time_scale = INTRO_TIME_SCALE
	_level = await ScenesLoader.start_level(level_id)
	await await_signal_on(_level, "wave_started", [1], FLOW_START_TIMEOUT_MS)
	await get_tree().process_frame
	var ticker: Timer = _level.get_node("WaveTickTimer")
	assert_bool(ticker.is_stopped()).is_false()
	assert_float(ticker.wait_time).is_equal(TICK_INTERVAL_S)
	ticker.stop()


func _state_of() -> String:
	return _level.state_machine.current_state_id


## Runs one tick of the level, a frame later its spawned enemies are ready.
func _tick() -> void:
	_level._process_tick()
	await get_tree().process_frame
