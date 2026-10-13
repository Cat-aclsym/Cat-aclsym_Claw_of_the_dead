## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The level ticks its state machine from a timer that runs on game time, twice per second.
extends GdUnitTestSuite

const FLOW_START_TIMEOUT_MS: int = 10000
const INTRO_TIME_SCALE: float = 8.0
const MAIN_SCENE_PATH: String = "res://main.tscn"
const LEVEL_ID: String = "lev.02"
## Game time between two ticks.
const TICK_INTERVAL_S: float = 0.5
## Tolerance on the game time of a tick: a frame or two.
const TICK_TOLERANCE_S: float = 0.15
const TICK_TIME_SCALE: float = 4.0
## Real time the first tick takes at [constant TICK_TIME_SCALE]: a quarter of a second at full speed, with room for a slow frame.
const TICK_MAX_REAL_MS: int = 400

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
func test_the_wave_flow_starts_a_repeating_game_time_timer_that_ticks_after_half_a_second(timeout: int = 30000) -> void:
	scene_runner(MAIN_SCENE_PATH)
	# The special tiles intro and its delay are real time, the wave flow resets the time scale
	Engine.time_scale = INTRO_TIME_SCALE
	_level = await ScenesLoader.start_level(LEVEL_ID)
	await await_signal_on(_level, "wave_started", [1], FLOW_START_TIMEOUT_MS)
	await get_tree().process_frame
	var ticker: Timer = _level.get_node("WaveTickTimer")

	assert_object(ticker.get_parent()).is_same(_level)
	assert_float(ticker.wait_time).is_equal(TICK_INTERVAL_S)
	assert_bool(ticker.one_shot).is_false()
	assert_bool(ticker.autostart).is_false()
	assert_int(ticker.process_callback).is_equal(Timer.TIMER_PROCESS_IDLE)
	assert_bool(ticker.is_stopped()).is_false()
	assert_float(Engine.time_scale).is_equal(1.0)

	# The timer follows the engine time scale: a tick of half a second of game time comes sooner at a higher scale
	var game_time_before: float = _level.elapsed_time
	Engine.time_scale = TICK_TIME_SCALE
	var real_before_ms: int = Time.get_ticks_msec()
	await await_signal_on(ticker, "timeout", [], TICK_MAX_REAL_MS * 4)

	assert_int(Time.get_ticks_msec() - real_before_ms).is_less(TICK_MAX_REAL_MS)
	assert_float(_level.elapsed_time - game_time_before).is_equal_approx(TICK_INTERVAL_S, TICK_TOLERANCE_S)
