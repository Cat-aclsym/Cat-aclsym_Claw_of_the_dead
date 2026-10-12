## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A level freezes (PAUSE state and time scale 0) while a pause source is active and resumes its state when it is released.
extends GdUnitTestSuite

const LEVEL_ID: String = "lev.02"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const PAUSE_SOURCE: StringName = &"test_pause"
const WAVE_START_TIME_SCALE: float = 8.0
const WAVE_START_TIMEOUT_MS: int = 10000

var _data_before: ProgressionData = null
var _level: ILevel = null
var _persistence_before: bool = true


func before_test() -> void:
	_data_before = ProgressionManager.data
	_persistence_before = ProgressionManager.persistence_enabled
	ProgressionManager.data = ProgressionData.new()
	ProgressionManager.data.parameters.tutorial_completed = true
	ProgressionManager.persistence_enabled = false


func after_test() -> void:
	Engine.time_scale = 1.0
	Global.clear_pauses()
	if is_instance_valid(_level):
		_level.queue_free()
		await _level.tree_exited
	_level = null
	ILevel.current_level = null
	ProgressionManager.data = _data_before
	ProgressionManager.persistence_enabled = _persistence_before


@warning_ignore("unused_parameter")
func test_a_pause_source_freezes_the_level_until_it_is_released(timeout: int = 20000) -> void:
	scene_runner(MAIN_SCENE_PATH)
	_level = await ScenesLoader.start_level(LEVEL_ID)

	assert_object(_level).is_not_null()
	assert_str(_state_of(_level)).is_equal(ILevel.STATE_CONFIGURING)

	Global.request_pause(PAUSE_SOURCE)

	assert_str(_state_of(_level)).is_equal(ILevel.STATE_PAUSE)
	assert_float(Engine.time_scale).is_equal(0.0)

	Global.release_pause(PAUSE_SOURCE)

	assert_str(_state_of(_level)).is_equal(ILevel.STATE_CONFIGURING)
	assert_float(Engine.time_scale).is_equal(1.0)

	# The level start coroutine must finish before the level is freed, it would resume on a freed instance otherwise
	Engine.time_scale = WAVE_START_TIME_SCALE
	await await_signal_on(_level, "wave_started", [1], WAVE_START_TIMEOUT_MS)


func _state_of(level: ILevel) -> String:
	return level.state_machine.get_current_state().name
