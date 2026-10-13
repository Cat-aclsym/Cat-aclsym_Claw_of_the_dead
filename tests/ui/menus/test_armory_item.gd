## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [ArmoryItem]: the look of the buy banner for each state of the card (buyable, missing stars, missing prerequisite, owned, legacy).
extends GdUnitTestSuite

const ITEM_SCENE: PackedScene = preload("res://ui/menus/armory/armory_item.tscn")


func test_a_buyable_card_has_a_blue_enabled_banner_with_the_price() -> void:
	var item: ArmoryItem = await _item(true, true, false, false)

	assert_int(item.buy_button.palette).is_equal(GameButton.Palette.BLUE)
	assert_bool(item.buy_button.disabled).is_false()
	assert_str(item.buy_button.text).is_equal("%s  3" % tr("ARMORY.BUY").to_upper())
	assert_object(item.buy_button.icon).is_not_null()
	assert_int(item.buy_button.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)


func test_a_card_missing_stars_has_a_red_banner_that_ignores_clicks() -> void:
	var item: ArmoryItem = await _item(false, true, false, false)

	assert_int(item.buy_button.palette).is_equal(GameButton.Palette.RED)
	assert_bool(item.buy_button.disabled).is_false()
	assert_int(item.buy_button.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_that(item.buy_button.get_theme_color(&"font_color")).is_equal(Color.WHITE)


func test_a_card_missing_a_prerequisite_has_a_disabled_banner() -> void:
	var item: ArmoryItem = await _item(true, false, false, false)

	assert_bool(item.buy_button.disabled).is_true()
	assert_str(item.buy_button.text).starts_with(tr("ARMORY.BUY_BLOCKED").to_upper())
	assert_int(item.buy_button.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


func test_an_owned_card_has_a_green_banner_without_price() -> void:
	var item: ArmoryItem = await _item(true, true, true, false)

	assert_int(item.buy_button.palette).is_equal(GameButton.Palette.GREEN)
	assert_bool(item.buy_button.disabled).is_false()
	assert_str(item.buy_button.text).is_equal(tr("ARMORY.OWNED").to_upper())
	assert_object(item.buy_button.icon).is_null()
	assert_int(item.buy_button.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


func test_a_legacy_card_keeps_a_blue_banner_that_ignores_clicks() -> void:
	var item: ArmoryItem = await _item(true, true, false, true)

	assert_int(item.buy_button.palette).is_equal(GameButton.Palette.BLUE)
	assert_bool(item.buy_button.disabled).is_false()
	assert_int(item.buy_button.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


func test_the_banner_only_shows_while_the_card_is_selected() -> void:
	var item: ArmoryItem = await _item(true, true, false, false)
	assert_float(item.buy_button.modulate.a).is_equal(1.0)

	item.set_selected(false)

	assert_float(item.buy_button.modulate.a).is_equal(0.0)
	assert_int(item.buy_button.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


func test_pressing_the_banner_requests_the_purchase_only_when_it_can_be_bought() -> void:
	var item: ArmoryItem = await _item(true, true, false, false)
	item.node_id = "some_node"
	var requested: Array[String] = []
	SignalUtil.connects([{SignalUtil.WHO: item, SignalUtil.WHAT: "buy_requested", SignalUtil.TO: requested.append}])

	item.buy_button.pressed.emit()
	item.refresh_state(false, true, false, false)
	item.buy_button.pressed.emit()

	assert_array(requested).contains_exactly(["some_node"])


## Returns a selected card in the given state, drawn once.
func _item(affordable: bool, prerequisites_met: bool, purchased: bool, legacy_mode: bool) -> ArmoryItem:
	var item: ArmoryItem = auto_free(ITEM_SCENE.instantiate())
	item.cost_stars = 3
	add_child(item)
	item.refresh_state(affordable, prerequisites_met, purchased, legacy_mode)
	item.set_selected(true)
	await get_tree().process_frame
	return item
