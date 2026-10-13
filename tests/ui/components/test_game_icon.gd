## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [GameIcon] atlas: one distinct glyph per id, the single-color and multicolor lists match the pixels.
extends GdUnitTestSuite

const WHITE: Color = Color(1.0, 1.0, 1.0, 1.0)
const LIGHT_GREY: Color = Color(191.0 / 255.0, 191.0 / 255.0, 191.0 / 255.0, 1.0)
## Single-color glyphs drawn with the light grey second tone besides the white.
const SHADED: Array[GameIcon.Id] = [GameIcon.Id.PLAY, GameIcon.Id.PAUSE, GameIcon.Id.FAST_FORWARD, GameIcon.Id.CLOSE, GameIcon.Id.BACK]

var _atlas_image: Image


func before() -> void:
	_atlas_image = GameIcon.ATLAS.get_image()


func test_every_icon_has_a_region_inside_the_atlas() -> void:
	var atlas_rect: Rect2 = Rect2(Vector2.ZERO, GameIcon.ATLAS.get_size())

	for id: GameIcon.Id in _icons():
		assert_bool(atlas_rect.encloses(GameIcon.region(id))).override_failure_message("%s is outside the atlas" % GameIcon.key(id)).is_true()
		assert_vector(GameIcon.region(id).size).is_equal(Vector2.ONE * GameIcon.CELL_SIZE)


func test_every_icon_is_drawn_and_distinct() -> void:
	var seen: Dictionary[int, String] = {}

	for id: GameIcon.Id in _icons():
		var cell: Image = _cell(id)
		assert_bool(_pixels(cell).any(func(pixel: Color) -> bool: return pixel.a > 0.0)).override_failure_message("%s is empty" % GameIcon.key(id)).is_true()
		var cell_hash: int = hash(cell.get_data())
		assert_bool(seen.has(cell_hash)).override_failure_message("%s equals %s" % [GameIcon.key(id), seen.get(cell_hash)]).is_false()
		seen[cell_hash] = GameIcon.key(id)


func test_icons_fill_the_atlas_cells_in_order() -> void:
	assert_int(_icons().size()).is_equal((GameIcon.Id.size() - 1))
	assert_vector(GameIcon.region(GameIcon.Id.HOME).position).is_equal(Vector2.ZERO)
	assert_vector(GameIcon.region(GameIcon.Id.SOUND).position).is_equal(Vector2(7.0 * GameIcon.CELL_SIZE, 0.0))
	assert_vector(GameIcon.region(GameIcon.Id.SOUND_OFF).position).is_equal(Vector2(0.0, GameIcon.CELL_SIZE))
	assert_vector(GameIcon.region(GameIcon.Id.ARROW_RIGHT).position).is_equal(Vector2(2.0 * GameIcon.CELL_SIZE, 3.0 * GameIcon.CELL_SIZE))


func test_none_has_no_texture() -> void:
	assert_object(GameIcon.texture(GameIcon.Id.NONE)).is_null()


func test_texture_is_cached_and_cut_from_the_atlas() -> void:
	var first: AtlasTexture = GameIcon.texture(GameIcon.Id.PLAY)

	assert_object(GameIcon.texture(GameIcon.Id.PLAY)).is_same(first)
	assert_object(GameIcon.texture(GameIcon.Id.PAUSE)).is_not_same(first)
	assert_object(first.atlas).is_same(GameIcon.ATLAS)
	assert_object(first.region).is_equal(GameIcon.region(GameIcon.Id.PLAY))


func test_multicolor_icons_are_the_flags_and_the_arrows() -> void:
	assert_array(GameIcon.MULTICOLOR).contains_exactly_in_any_order([GameIcon.Id.FLAG_EN, GameIcon.Id.FLAG_FR, GameIcon.Id.ARROW_LEFT, GameIcon.Id.ARROW_RIGHT])
	assert_bool(GameIcon.is_multicolor(GameIcon.Id.FLAG_FR)).is_true()
	assert_bool(GameIcon.is_multicolor(GameIcon.Id.HOME)).is_false()
	assert_bool(GameIcon.is_multicolor(GameIcon.Id.INSTAGRAM)).is_false()


func test_only_the_multicolor_icons_have_colored_pixels() -> void:
	for id: GameIcon.Id in _icons():
		var has_color: bool = _pixels(_cell(id)).any(func(pixel: Color) -> bool: return pixel.a > 0.0 and not (is_equal_approx(pixel.r, pixel.g) and is_equal_approx(pixel.g, pixel.b)))
		assert_bool(has_color).override_failure_message("%s: colored pixels must match MULTICOLOR" % GameIcon.key(id)).is_equal(GameIcon.is_multicolor(id))


func test_the_single_color_icons_are_white_and_the_shaded_ones_add_a_light_grey() -> void:
	for id: GameIcon.Id in _icons().filter(func(icon: GameIcon.Id) -> bool: return not GameIcon.is_multicolor(icon)):
		var opaque: Array[Color] = _pixels(_cell(id)).filter(func(pixel: Color) -> bool: return pixel.a > 0.0)
		assert_bool(opaque.all(func(pixel: Color) -> bool: return pixel.is_equal_approx(WHITE) or pixel.is_equal_approx(LIGHT_GREY))).override_failure_message("%s: only white and light grey expected" % GameIcon.key(id)).is_true()
		var has_grey: bool = opaque.any(func(pixel: Color) -> bool: return pixel.is_equal_approx(LIGHT_GREY))
		assert_bool(has_grey).override_failure_message("%s: SHADED must match the light grey pixels" % GameIcon.key(id)).is_equal(id in SHADED)


func test_key_is_the_name_of_the_id() -> void:
	assert_str(GameIcon.key(GameIcon.Id.FAST_FORWARD)).is_equal("FAST_FORWARD")
	assert_str(GameIcon.key(GameIcon.Id.X_SOCIAL)).is_equal("X_SOCIAL")


func _cell(id: GameIcon.Id) -> Image:
	return _atlas_image.get_region(Rect2i(GameIcon.region(id)))


## Returns every id but [constant GameIcon.Id.NONE].
func _icons() -> Array[GameIcon.Id]:
	var icons: Array[GameIcon.Id] = []
	icons.assign(GameIcon.Id.values().slice(1))
	return icons


func _pixels(image: Image) -> Array[Color]:
	var pixels: Array[Color] = []
	for y: int in image.get_height():
		for x: int in image.get_width():
			pixels.append(image.get_pixel(x, y))
	return pixels
