## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [BuildSelection]: the tab buttons latch the current tab.
extends GdUnitTestSuite

const SELECTION_SCENE: PackedScene = preload("res://ui/menus/build_selection/build_selection.tscn")


func test_the_tower_tab_is_latched_when_the_menu_opens() -> void:
	var selection: BuildSelection = await _open()

	assert_bool(selection.tower_tab_button.button_pressed).is_true()
	assert_bool(selection.trap_tab_button.button_pressed).is_false()
	assert_int(selection.tower_tab_button.get_effective_palette()).is_equal(GameButton.Palette.BLUE)
	assert_int(selection.trap_tab_button.get_effective_palette()).is_equal(GameButton.Palette.GREY)


func test_pressing_the_trap_tab_latches_it_and_releases_the_tower_tab() -> void:
	var selection: BuildSelection = await _open()

	selection.trap_tab_button.button_pressed = true
	selection.trap_tab_button.pressed.emit()

	assert_bool(selection.trap_tab_button.button_pressed).is_true()
	assert_bool(selection.tower_tab_button.button_pressed).is_false()
	assert_int(selection.trap_tab_button.get_effective_palette()).is_equal(GameButton.Palette.BLUE)
	assert_int(selection.tower_tab_button.get_effective_palette()).is_equal(GameButton.Palette.GREY)


func test_pressing_the_active_tab_keeps_it_latched() -> void:
	var selection: BuildSelection = await _open()

	selection.tower_tab_button.button_pressed = false
	selection.tower_tab_button.pressed.emit()

	assert_bool(selection.tower_tab_button.button_pressed).is_true()


func _open() -> BuildSelection:
	var selection: BuildSelection = auto_free(SELECTION_SCENE.instantiate())
	add_child(selection)
	await get_tree().process_frame
	return selection
