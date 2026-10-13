## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [BuildCard]: one scene configured by its entity, title, icon and price come from the entity and [StatsDB].
extends GdUnitTestSuite

const CARD_SCENE: PackedScene = preload("res://ui/menus/build_selection/cards/build_card.tscn")
## Tint of the bat_04 trap sprite in game.
const TRAP_TEAL: Color = Color(3.85046e-07, 0.670751, 0.662421, 1.0)

var _data_before: ProgressionData
var _persistence_before: bool


func before_test() -> void:
	_data_before = ProgressionManager.data
	_persistence_before = ProgressionManager.persistence_enabled
	ProgressionManager.data = ProgressionData.new()
	ProgressionManager.persistence_enabled = false


func after_test() -> void:
	ProgressionManager.data = _data_before
	ProgressionManager.persistence_enabled = _persistence_before


func test_the_title_is_the_translated_name_of_the_entity() -> void:
	for id: String in BuildSelection.CARD_IDS:
		var card: BuildCard = _card(id)

		assert_str(card.title_label.text).is_equal(tr(_name_key(id)))


func test_the_icon_is_the_sprite_of_the_entity() -> void:
	for id: String in BuildSelection.CARD_IDS:
		var card: BuildCard = _card(id)
		var preview: SpritePreview = SpritePreview.from_scene(_scene(id))

		assert_object(card.preview_texture_rect.texture).override_failure_message("%s: no icon" % id).is_not_null()
		assert_object(card.preview_texture_rect.texture).override_failure_message("%s: wrong icon" % id).is_same(preview.texture)
		assert_that(card.preview_texture_rect.modulate).override_failure_message("%s: wrong tint" % id).is_equal(preview.modulate)


func test_the_slow_trap_icon_is_teal_like_the_trap_in_game() -> void:
	var card: BuildCard = _card("bat_04")

	assert_bool(card.preview_texture_rect.modulate.is_equal_approx(TRAP_TEAL)).is_true()


func test_an_unlocked_entity_shows_its_price_and_the_coin() -> void:
	ProgressionManager.unlock_tower_no_save("bat_02")
	var card: BuildCard = _card("bat_02")

	assert_bool(card.price_coin_icon.visible).is_true()
	assert_str(card.price_label.text).is_equal(str(int(StatsDB.get_tower("bat_02")["base"]["cost"])))


func test_a_locked_entity_shows_locked_instead_of_the_price() -> void:
	var card: BuildCard = _card("bat_02")

	assert_bool(card.price_coin_icon.visible).is_false()
	assert_str(card.price_label.text).is_equal(tr("BUILD.CARD.LOCKED"))
	assert_bool(card.button_texture.disabled).is_true()


func _card(id: String) -> BuildCard:
	var card: BuildCard = auto_free(CARD_SCENE.instantiate())
	card.entity = _scene(id)
	add_child(card)
	return card


func _name_key(id: String) -> String:
	return StatsDB.name_key("TOWER" if StatsDB.has_tower(id) else "TRAP", id)


func _scene(id: String) -> PackedScene:
	var stats: Dictionary = StatsDB.get_tower(id) if StatsDB.has_tower(id) else StatsDB.get_trap(id)
	return StatsDB.load_packed_scene(str(stats.get("scene", "")))
