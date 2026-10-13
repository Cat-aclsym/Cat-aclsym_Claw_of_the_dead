## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [HUD]: the build selection button is a toggle that shows BUILD on GREEN, then CLOSE on RED while the menu is open.
extends GdUnitTestSuite

const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")

var _hud_before: HUD = null
var _time_scale_before: float = 1.0


func before_test() -> void:
	_hud_before = Global.hud if is_instance_valid(Global.hud) else null
	_time_scale_before = Engine.time_scale


func after_test() -> void:
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


func _open() -> HUD:
	var hud: HUD = auto_free(HUD_SCENE.instantiate())
	add_child(hud)
	return hud
