## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [HUD]: the build selection button is a toggle that shows BUILD on GREEN, then CLOSE on RED while the menu is open, and the fast forward button
## runs the rainbow while the game is at x3.
extends GdUnitTestSuite

## A pause source that freezes the time without pausing the tree, so that the HUD keeps processing.
const FREEZING_SOURCE: StringName = &"test_freeze"
const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")

var _hud_before: HUD = null
var _time_scale_before: float = 1.0


func before_test() -> void:
	_hud_before = Global.hud if is_instance_valid(Global.hud) else null
	_time_scale_before = Engine.time_scale


func after_test() -> void:
	Global.release_pause(FREEZING_SOURCE)
	Global.hud = _hud_before
	Engine.time_scale = _time_scale_before


func test_the_build_selection_button_shows_build_on_green_until_pressed() -> void:
	var button: GameButton = _open().build_selection_button

	assert_bool(button.toggle_mode).is_true()
	assert_int(button.get_effective_icon()).is_equal(GameIcon.Id.BUILD)
	assert_int(button.get_effective_palette()).is_equal(GameButton.Palette.GREEN)

	button.button_pressed = true

	assert_int(button.get_effective_icon()).is_equal(GameIcon.Id.CLOSE)
	assert_int(button.get_effective_palette()).is_equal(GameButton.Palette.RED)


func test_the_build_selection_button_resyncs_without_a_signal() -> void:
	var button: GameButton = _open().build_selection_button
	var toggled_count: Array[int] = [0]
	SignalUtil.connects([{SignalUtil.WHO: button, SignalUtil.WHAT: "toggled", SignalUtil.TO: func(_pressed: bool) -> void: toggled_count[0] += 1}])
	button.set_pressed_no_signal(true)

	button.set_pressed_no_signal(false)

	assert_int(button.get_effective_icon()).is_equal(GameIcon.Id.BUILD)
	assert_int(button.get_effective_palette()).is_equal(GameButton.Palette.GREEN)
	assert_int(toggled_count[0]).is_equal(0)


func test_the_fast_forward_button_triples_the_time_scale_and_runs_the_rainbow_while_on() -> void:
	var button: GameButton = _open().fast_forward_button

	assert_bool(button.rainbow).is_false()
	assert_float(Engine.time_scale).is_equal(HUD.DEFAULT_TIME_SCALE)

	button.button_pressed = true
	button.pressed.emit()

	assert_bool(button.rainbow).is_true()
	assert_float(Engine.time_scale).is_equal(HUD.FAST_FORWARD_TIME_SCALE)

	button.button_pressed = false
	button.pressed.emit()

	assert_bool(button.rainbow).is_false()
	assert_float(Engine.time_scale).is_equal(HUD.DEFAULT_TIME_SCALE)


func test_the_fast_forward_button_follows_a_time_scale_reset_by_the_level() -> void:
	var button: GameButton = _open().fast_forward_button
	button.button_pressed = true
	button.pressed.emit()

	Engine.time_scale = HUD.DEFAULT_TIME_SCALE
	await await_idle_frame()

	assert_bool(button.button_pressed).is_false()
	assert_bool(button.rainbow).is_false()


func test_the_fast_forward_button_is_ignored_while_the_time_is_frozen() -> void:
	var button: GameButton = _open().fast_forward_button
	Global.request_pause(FREEZING_SOURCE)

	button.button_pressed = true
	button.pressed.emit()
	await await_idle_frame()

	assert_bool(button.button_pressed).is_false()
	assert_bool(button.rainbow).is_false()
	assert_float(Engine.time_scale).is_equal(HUD.DEFAULT_TIME_SCALE)


func _open() -> HUD:
	var hud: HUD = auto_free(HUD_SCENE.instantiate())
	add_child(hud)
	return hud
