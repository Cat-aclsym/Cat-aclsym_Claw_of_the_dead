## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [PopupSpawner]: the wave popup shows its text in uppercase on the banner.
extends GdUnitTestSuite

const WAVE_POPUP_SCENE: PackedScene = preload("res://ui/popups/popup_wave.tscn")

var _ui_before: UI = null


func before_test() -> void:
	_ui_before = Global.ui if is_instance_valid(Global.ui) else null


func after_test() -> void:
	Global.ui = _ui_before


func test_wave_puts_the_uppercased_text_on_the_banner_of_a_popup_added_to_the_ui() -> void:
	var ui: UI = auto_free(UI.new())
	Global.ui = ui
	var spawner: PopupSpawner = auto_free(PopupSpawner.new())
	spawner.popup_node = WAVE_POPUP_SCENE

	spawner.wave("Wave 3")

	assert_int(ui.get_child_count()).is_equal(1)
	var banner: GameButton = ui.get_child(0).get_node("CenterContainer/Banner")
	assert_str(banner.text).is_equal("WAVE 3")
