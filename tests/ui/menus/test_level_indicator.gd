## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [LevelIndicator]: one grey dot recolored by the palette row of its status.
extends GdUnitTestSuite

const INDICATOR_SCENE: PackedScene = preload("res://ui/menus/level_selection/components/level_indicator.tscn")


func test_every_status_picks_its_palette_row() -> void:
	for status: LevelIndicator.Status in LevelIndicator.ROWS:
		var indicator: LevelIndicator = _indicator(1, status)

		assert_int(_row(indicator)).override_failure_message(str(status)).is_equal(LevelIndicator.ROWS[status])


func test_the_rows_are_orange_green_and_blue() -> void:
	assert_int(LevelIndicator.ROWS[LevelIndicator.Status.CURRENT]).is_equal(GameButton.Palette.ORANGE)
	assert_int(LevelIndicator.ROWS[LevelIndicator.Status.COMPLETED]).is_equal(GameButton.Palette.GREEN)
	assert_int(LevelIndicator.ROWS[LevelIndicator.Status.LOCKED]).is_equal(GameButton.Palette.BLUE)


func test_a_locked_indicator_is_disabled_and_the_others_are_not() -> void:
	assert_bool(_indicator(3, LevelIndicator.Status.LOCKED).disabled).is_true()
	assert_bool(_indicator(1, LevelIndicator.Status.CURRENT).disabled).is_false()
	assert_bool(_indicator(2, LevelIndicator.Status.COMPLETED).disabled).is_false()


func test_the_normal_and_disabled_looks_share_the_grey_dot() -> void:
	var indicator: LevelIndicator = _indicator(1, LevelIndicator.Status.CURRENT)

	assert_object(indicator.texture_normal).is_not_null()
	assert_object(indicator.texture_disabled).is_same(indicator.texture_normal)


func test_the_label_shows_the_level() -> void:
	assert_str(_indicator(5, LevelIndicator.Status.CURRENT).label.text).is_equal("5")


func test_every_indicator_has_its_own_material() -> void:
	var current: LevelIndicator = _indicator(1, LevelIndicator.Status.CURRENT)
	var completed: LevelIndicator = _indicator(2, LevelIndicator.Status.COMPLETED)

	assert_object(current.material).is_not_same(completed.material)
	assert_int(_row(current)).is_equal(GameButton.Palette.ORANGE)


func test_pressing_the_indicator_emits_selected() -> void:
	var indicator: LevelIndicator = _indicator(4, LevelIndicator.Status.CURRENT)
	var selected: Array[LevelIndicator] = []
	SignalUtil.connects([{SignalUtil.WHO: indicator, SignalUtil.WHAT: "selected", SignalUtil.TO: selected.append}])

	indicator.pressed.emit()

	assert_array(selected).contains_exactly([indicator])


func _indicator(level: int, status: LevelIndicator.Status) -> LevelIndicator:
	var indicator: LevelIndicator = auto_free(INDICATOR_SCENE.instantiate())
	add_child(indicator)
	indicator.configure(level, status)
	return indicator


func _row(indicator: LevelIndicator) -> int:
	return (indicator.material as ShaderMaterial).get_shader_parameter(&"palette_row")
