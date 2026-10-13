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


func test_the_cards_are_built_from_the_entities_of_stats_db() -> void:
	var expected_ids: Array[String] = []
	for id: String in StatsDB.get_tower_ids() + StatsDB.get_trap_ids():
		var stats: Dictionary = StatsDB.get_tower(id) if StatsDB.has_tower(id) else StatsDB.get_trap(id)
		if StatsDB.load_packed_scene(str(stats.get("scene", ""))) != null:
			expected_ids.append(id)

	assert_array(BuildSelection.CARD_IDS).contains_exactly_in_any_order(expected_ids)


func test_the_tower_tab_shows_the_tower_cards_in_menu_order() -> void:
	var selection: BuildSelection = await _open()

	assert_array(_visible_card_ids(selection)).is_equal(["bat_01", "bat_02", "bat_09", "bat_08"])


func test_the_trap_tab_shows_the_trap_cards_in_menu_order() -> void:
	var selection: BuildSelection = await _open()

	selection.trap_tab_button.button_pressed = true
	selection.trap_tab_button.pressed.emit()

	assert_array(_visible_card_ids(selection)).is_equal(["bat_03", "bat_04", "bat_05", "bat_06", "bat_07"])


func test_every_card_sits_in_a_named_aspect_ratio_container() -> void:
	var selection: BuildSelection = await _open()

	assert_int(selection.construction_menu.get_child_count()).is_equal(BuildSelection.CARD_IDS.size())
	for id: String in BuildSelection.CARD_IDS:
		var aspect: AspectRatioContainer = selection.construction_menu.get_node("%sAspectRatioContainer" % id.to_pascal_case())
		assert_int(aspect.stretch_mode).is_equal(AspectRatioContainer.STRETCH_HEIGHT_CONTROLS_WIDTH)
		assert_object(aspect.get_child(0)).is_instanceof(BuildCard)


## Ids (stats ids of the entities) of the cards shown by the current tab, in display order.
func _visible_card_ids(selection: BuildSelection) -> Array[String]:
	var ids: Array[String] = []
	for aspect: AspectRatioContainer in selection.construction_menu.get_children():
		if aspect.visible:
			var card: BuildCard = aspect.get_child(0)
			ids.append((card._entity as ITower).tower_id if card._entity is ITower else (card._entity as ITrap).trap_id)
	return ids


func _open() -> BuildSelection:
	var selection: BuildSelection = auto_free(SELECTION_SCENE.instantiate())
	add_child(selection)
	await get_tree().process_frame
	return selection
