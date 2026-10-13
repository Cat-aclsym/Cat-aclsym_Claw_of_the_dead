## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [ButtonEffects] setup of a button, applied once whatever the number of calls, and its click scale tween.
extends GdUnitTestSuite

const SIGNALS: Array[String] = ["gui_input"]


func test_apply_does_nothing_for_a_null_button() -> void:
	ButtonEffects.apply(null)


func test_apply_is_idempotent() -> void:
	var button: Button = auto_free(Button.new())
	var connections_before: Array[int] = _connection_counts(button)

	ButtonEffects.apply(button)
	var connections_after_first: Array[int] = _connection_counts(button)
	ButtonEffects.apply(button)

	assert_array(connections_after_first).is_not_equal(connections_before)
	assert_array(_connection_counts(button)).is_equal(connections_after_first)


func test_apply_keeps_the_button_processing_while_the_tree_is_paused() -> void:
	var button: Button = auto_free(Button.new())

	ButtonEffects.apply(button)

	assert_int(button.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_bool(button.has_meta(ButtonEffects.APPLIED_META_KEY)).is_true()


func test_apply_without_process_when_paused_leaves_the_process_mode() -> void:
	var button: Button = auto_free(Button.new())

	ButtonEffects.apply(button, false)

	assert_int(button.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_bool(button.has_meta(ButtonEffects.APPLIED_META_KEY)).is_true()
	assert_vector(button.pivot_offset_ratio).is_equal(ButtonEffects.PIVOT_RATIO)


func test_apply_pivots_on_the_center_and_follows_the_size() -> void:
	var button: Button = auto_free(Button.new())
	button.size = Vector2(80.0, 40.0)

	ButtonEffects.apply(button)

	assert_vector(button.get_combined_pivot_offset()).is_equal(button.size / 2.0)

	button.size = Vector2(120.0, 60.0)

	assert_vector(button.get_combined_pivot_offset()).is_equal(button.size / 2.0)


func test_a_click_shrinks_the_button_and_the_next_one_replaces_its_tween() -> void:
	var button: Button = auto_free(Button.new())
	add_child(button)
	ButtonEffects.apply(button)
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true

	button.gui_input.emit(press)
	var first: Tween = button.get_meta(ButtonEffects.TWEEN_META_KEY) as Tween
	button.gui_input.emit(press)

	assert_bool(first.is_valid()).is_false()
	await await_millis(int(ButtonEffects.TWEEN_DURATION * 1000.0) + 100)
	assert_vector(button.scale).is_equal_approx(ButtonEffects.CLICK_SCALE, Vector2(0.001, 0.001))


func _connection_counts(button: Button) -> Array[int]:
	var counts: Array[int] = []
	counts.assign(SIGNALS.map(func(signal_name: String) -> int: return button.get_signal_connection_list(signal_name).size()))
	return counts
