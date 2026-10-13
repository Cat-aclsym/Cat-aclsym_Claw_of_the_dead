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


func test_the_price_label_uses_a_variation_per_state() -> void:
	ProgressionManager.unlock_tower_no_save("bat_02")
	var unaffordable: BuildCard = _card("bat_02")
	var locked: BuildCard = _card("bat_08")

	assert_str(unaffordable.price_label.theme_type_variation).is_equal(&"PriceLabelUnaffordable")
	assert_that(unaffordable.price_label.modulate).is_equal(BuildCard.PRICE_LABEL_MODULATE_VS_DIM)
	assert_str(locked.price_label.theme_type_variation).is_equal(&"PriceLabelLocked")
	assert_that(locked.price_label.modulate).is_equal(Color.WHITE)
	assert_bool(unaffordable.price_label.has_theme_color_override(&"font_color")).is_false()

	var level: ILevel = auto_free(ILevel.new())
	level.coins = 100000
	ILevel.current_level = level
	unaffordable.update()
	ILevel.current_level = null

	assert_str(unaffordable.price_label.theme_type_variation).is_equal(&"PriceLabel")
	assert_that(unaffordable.price_label.modulate).is_equal(Color.WHITE)


func test_the_price_row_is_centered_inside_the_green_band_of_the_frame() -> void:
	ProgressionManager.unlock_tower_no_save("bat_02")
	for id: String in BuildSelection.CARD_IDS:
		var card: BuildCard = _card(id, Vector2(70.0, 200.0))
		await await_idle_frame()
		await await_idle_frame()
		var band: Rect2 = _band(card.button_texture)
		var row: Control = card.price_label.get_parent()
		var content: Rect2 = card.price_label.get_global_rect()
		if card.price_coin_icon.visible:
			content = content.merge(card.price_coin_icon.get_global_rect())

		assert_bool(band.grow(0.01).encloses(row.get_global_rect())).override_failure_message("%s: row %s outside band %s" % [id, row.get_global_rect(), band]).is_true()
		assert_bool(band.grow(0.01).encloses(content)).override_failure_message("%s: content %s outside band %s" % [id, content, band]).is_true()
		assert_float(content.get_center().x).override_failure_message("%s: content not centered horizontally" % id).is_equal_approx(band.get_center().x, 1.0)
		assert_float(content.get_center().y).override_failure_message("%s: content not centered vertically" % id).is_equal_approx(band.get_center().y, 1.0)


## Returns the rect, in global coordinates, of the filled bottom band of the frame texture drawn in [param button] (inside the border).
## [br]The band is measured on the texture: it starts at the first opaque row above the bottom at the middle column, and the border is as thick as the left edge.
func _band(button: TextureButton) -> Rect2:
	var image: Image = button.texture_normal.get_image()
	var width: int = image.get_width()
	var height: int = image.get_height()
	var border: int = 0
	while image.get_pixel(border, height / 2).a > 0.8:
		border += 1
	var top: int = height - 1
	while image.get_pixel(width / 2, top - 1).a > 0.8:
		top -= 1
	var scale: float = minf(button.size.x / width, button.size.y / height)
	return Rect2(button.global_position + Vector2(border, top) * scale, Vector2(width - 2 * border, height - border - top) * scale)


func _card(id: String, size: Vector2 = Vector2.ZERO) -> BuildCard:
	var card: BuildCard = auto_free(CARD_SCENE.instantiate())
	card.entity = _scene(id)
	if size == Vector2.ZERO:
		add_child(card)
		return card
	var host: Control = auto_free(Control.new())
	host.size = size
	host.add_child(card)
	add_child(host)
	return card


func _name_key(id: String) -> String:
	return StatsDB.name_key("TOWER" if StatsDB.has_tower(id) else "TRAP", id)


func _scene(id: String) -> PackedScene:
	var stats: Dictionary = StatsDB.get_tower(id) if StatsDB.has_tower(id) else StatsDB.get_trap(id)
	return StatsDB.load_packed_scene(str(stats.get("scene", "")))
