## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Pause sources of [Global]: stacking, tree pausing and time freezing.
extends GdUnitTestSuite

const CUSTOM_SOURCE: StringName = &"test_custom_source"
const OTHER_SOURCE: StringName = &"test_other_source"

var _emitted: Array[bool] = []


func before_test() -> void:
	Global.clear_pauses()
	_emitted.clear()
	SignalUtil.connects([{SignalUtil.WHO: Global, SignalUtil.WHAT: "pause_changed", SignalUtil.TO: _on_pause_changed}])


func after_test() -> void:
	Global.pause_changed.disconnect(_on_pause_changed)
	Global.clear_pauses()


func test_clear_pauses_releases_every_source() -> void:
	Global.request_pause(CUSTOM_SOURCE)
	Global.request_pause(Global.TREE_PAUSING_SOURCES[0])

	Global.clear_pauses()

	assert_bool(Global.paused).is_false()
	assert_bool(Global.is_time_frozen()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_clear_pauses_without_source_emits_nothing() -> void:
	Global.clear_pauses()

	assert_array(_emitted).is_empty()


func test_is_time_frozen_ignores_time_running_sources() -> void:
	for source: StringName in Global.TIME_RUNNING_SOURCES:
		Global.request_pause(source)
		assert_bool(Global.paused).is_true()
		assert_bool(Global.is_time_frozen()).override_failure_message("%s must keep the time running" % source).is_false()
		Global.release_pause(source)


func test_is_time_frozen_once_a_gameplay_source_is_active() -> void:
	Global.request_pause(Global.TIME_RUNNING_SOURCES[0])
	Global.request_pause(CUSTOM_SOURCE)

	assert_bool(Global.is_time_frozen()).is_true()

	Global.release_pause(CUSTOM_SOURCE)

	assert_bool(Global.is_time_frozen()).is_false()
	assert_bool(Global.paused).is_true()


func test_pause_changed_carries_the_resulting_state() -> void:
	Global.request_pause(CUSTOM_SOURCE)
	Global.request_pause(OTHER_SOURCE)
	Global.release_pause(CUSTOM_SOURCE)
	Global.release_pause(OTHER_SOURCE)

	assert_array(_emitted).is_equal([true, true, true, false])


func test_release_keeps_the_pause_while_another_source_is_active() -> void:
	Global.request_pause(CUSTOM_SOURCE)
	Global.request_pause(OTHER_SOURCE)

	Global.release_pause(CUSTOM_SOURCE)

	assert_bool(Global.paused).is_true()

	Global.release_pause(OTHER_SOURCE)

	assert_bool(Global.paused).is_false()


func test_release_of_an_unknown_source_does_nothing() -> void:
	Global.request_pause(CUSTOM_SOURCE)
	_emitted.clear()

	Global.release_pause(OTHER_SOURCE)

	assert_bool(Global.paused).is_true()
	assert_array(_emitted).is_empty()


func test_request_with_the_same_source_twice_counts_once() -> void:
	Global.request_pause(CUSTOM_SOURCE)
	Global.request_pause(CUSTOM_SOURCE)

	assert_array(_emitted).is_equal([true])

	Global.release_pause(CUSTOM_SOURCE)

	assert_bool(Global.paused).is_false()


func test_tree_is_not_paused_by_the_other_sources() -> void:
	Global.request_pause(CUSTOM_SOURCE)
	assert_bool(Global.paused).is_true()
	assert_bool(get_tree().paused).is_false()

	var non_tree_source: StringName = Global.TIME_RUNNING_SOURCES.filter(func(source: StringName) -> bool: return source not in Global.TREE_PAUSING_SOURCES)[0]
	Global.request_pause(non_tree_source)

	assert_bool(get_tree().paused).is_false()


func test_tree_is_paused_by_the_tree_pausing_sources() -> void:
	for source: StringName in Global.TREE_PAUSING_SOURCES:
		Global.request_pause(source)
		assert_bool(get_tree().paused).override_failure_message("%s must pause the tree" % source).is_true()
		Global.release_pause(source)
		assert_bool(get_tree().paused).is_false()


func test_tree_stays_paused_until_the_last_tree_pausing_source_is_released() -> void:
	var first: StringName = Global.TREE_PAUSING_SOURCES[0]
	var second: StringName = Global.TREE_PAUSING_SOURCES[1]
	Global.request_pause(first)
	Global.request_pause(second)

	Global.release_pause(first)

	assert_bool(get_tree().paused).is_true()

	Global.release_pause(second)

	assert_bool(get_tree().paused).is_false()


func _on_pause_changed(paused: bool) -> void:
	_emitted.append(paused)
