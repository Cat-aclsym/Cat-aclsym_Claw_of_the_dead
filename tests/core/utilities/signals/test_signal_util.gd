## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [SignalUtil] connections from the dictionary format.
extends GdUnitTestSuite

var _calls: int = 0
var _other_calls: int = 0


func before_test() -> void:
	_calls = 0
	_other_calls = 0


func test_connects_a_signal_once() -> void:
	var timer: Timer = auto_free(Timer.new())

	SignalUtil.connects([{SignalUtil.WHO: timer, SignalUtil.WHAT: "timeout", SignalUtil.TO: _on_timeout}])
	timer.timeout.emit()

	assert_int(_calls).is_equal(1)
	assert_int(timer.timeout.get_connections().size()).is_equal(1)


func test_connects_several_signals_of_several_emitters() -> void:
	var timer: Timer = auto_free(Timer.new())
	var other_timer: Timer = auto_free(Timer.new())

	SignalUtil.connects([
		{SignalUtil.WHO: timer, SignalUtil.WHAT: "timeout", SignalUtil.TO: _on_timeout},
		{SignalUtil.WHO: other_timer, SignalUtil.WHAT: "timeout", SignalUtil.TO: _on_other_timeout},
	])
	timer.timeout.emit()
	other_timer.timeout.emit()
	other_timer.timeout.emit()

	assert_int(_calls).is_equal(1)
	assert_int(_other_calls).is_equal(2)


func test_connects_skips_a_null_emitter_and_connects_the_others() -> void:
	var timer: Timer = auto_free(Timer.new())

	SignalUtil.connects([
		{SignalUtil.WHO: null, SignalUtil.WHAT: "timeout", SignalUtil.TO: _on_timeout},
		{SignalUtil.WHO: timer, SignalUtil.WHAT: "timeout", SignalUtil.TO: _on_timeout},
	])
	timer.timeout.emit()

	assert_int(_calls).is_equal(1)


func _on_other_timeout() -> void:
	_other_calls += 1


func _on_timeout() -> void:
	_calls += 1
