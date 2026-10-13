## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [TowerUpgradeMenu]: the option tab of the selected upgrade is green, the other one blue.
extends GdUnitTestSuite

const MENU_SCENE: PackedScene = preload("res://ui/menus/tower_upgrade/tower_upgrade_menu.tscn")
const UPGRADE_IDS: Array[String] = ["bat_01_02", "bat_02_02"]


func after_test() -> void:
	Global.release_pause(&"upgrade_menu")


func test_the_first_option_tab_is_green_when_the_menu_opens() -> void:
	var menu: TowerUpgradeMenu = _open()

	assert_int(menu._option1_button.palette).is_equal(GameButton.Palette.GREEN)
	assert_int(menu._option2_button.palette).is_equal(GameButton.Palette.BLUE)


func test_pressing_the_second_option_tab_moves_the_green_tab() -> void:
	var menu: TowerUpgradeMenu = _open()

	menu._option2_button.pressed.emit()

	assert_str(menu.selected_upgrade_id).is_equal(UPGRADE_IDS[1])
	assert_int(menu._option1_button.palette).is_equal(GameButton.Palette.BLUE)
	assert_int(menu._option2_button.palette).is_equal(GameButton.Palette.GREEN)

	menu._option1_button.pressed.emit()

	assert_int(menu._option1_button.palette).is_equal(GameButton.Palette.GREEN)
	assert_int(menu._option2_button.palette).is_equal(GameButton.Palette.BLUE)


func test_the_confirm_button_is_enabled_without_a_running_level() -> void:
	var menu: TowerUpgradeMenu = _open()

	assert_bool(menu._confirm_button.disabled).is_false()
	assert_int(menu._confirm_button.palette).is_equal(GameButton.Palette.GREEN)


func _open() -> TowerUpgradeMenu:
	var menu: TowerUpgradeMenu = auto_free(MENU_SCENE.instantiate())
	add_child(menu)
	menu.setup(null, UPGRADE_IDS)
	return menu
