## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Grey bases and [code]palette.png[/code]: the card frame and the level dot store a palette column in their red channel.
extends GdUnitTestSuite

const CARD_FRAME: Texture2D = preload("res://assets/ui/cards/card_frame.png")
const LEVEL_DOT: Texture2D = preload("res://assets/ui/level_selection/level_dot.png")
const PALETTE: Texture2D = preload("res://assets/ui/buttons/palette.png")
const FRAME_COLUMN: int = 7
const DOT_COLUMN: int = 8
const DOT_SHADES: int = 5
## The 7 columns of the button bases, one row per [enum GameButton.Palette] (BLUE, GREEN, ORANGE, RED, SAND, GREY).
const BUTTON_COLUMNS: Array[Array] = [
	[Color8(2, 47, 51), Color8(43, 127, 129), Color8(65, 167, 169), Color8(85, 205, 207), Color8(210, 238, 239), Color8(6, 40, 43), Color8(85, 205, 207)],
	[Color8(2, 47, 51), Color8(57, 136, 57), Color8(93, 216, 93), Color8(209, 255, 209), Color8(210, 238, 239), Color8(6, 40, 43), Color8(188, 250, 188)],
	[Color8(2, 47, 51), Color8(157, 87, 35), Color8(236, 136, 61), Color8(254, 213, 183), Color8(210, 238, 239), Color8(6, 40, 43), Color8(254, 213, 183)],
	[Color8(2, 47, 51), Color8(190, 52, 52), Color8(255, 67, 67), Color8(255, 152, 152), Color8(210, 238, 239), Color8(6, 40, 43), Color8(255, 152, 152)],
	[Color8(2, 47, 51), Color8(174, 167, 134), Color8(230, 220, 177), Color8(255, 245, 201), Color8(210, 238, 239), Color8(6, 40, 43), Color8(255, 245, 201)],
	[Color8(2, 47, 51), Color8(102, 102, 102), Color8(137, 137, 137), Color8(169, 169, 169), Color8(210, 238, 239), Color8(6, 40, 43), Color8(169, 169, 169)],
]

var _palette: Image


func before() -> void:
	_palette = PALETTE.get_image()


func test_the_button_columns_are_unchanged() -> void:
	for row: int in BUTTON_COLUMNS.size():
		for column: int in BUTTON_COLUMNS[row].size():
			assert_that(_palette.get_pixel(column, row)).override_failure_message("column %d row %d" % [column, row]).is_equal(BUTTON_COLUMNS[row][column])


func test_the_palette_has_the_button_frame_and_dot_columns() -> void:
	assert_int(_palette.get_width()).is_equal(DOT_COLUMN + DOT_SHADES)
	assert_int(_palette.get_height()).is_equal(GameButton.Palette.size())


func test_the_frame_column_holds_the_frame_colors() -> void:
	assert_that(_palette.get_pixel(FRAME_COLUMN, GameButton.Palette.BLUE)).is_equal(Color8(65, 167, 169))
	assert_that(_palette.get_pixel(FRAME_COLUMN, GameButton.Palette.GREEN)).is_equal(Color8(93, 216, 93))
	assert_that(_palette.get_pixel(FRAME_COLUMN, GameButton.Palette.GREY)).is_equal(Color8(192, 192, 192))
	for row: GameButton.Palette in [GameButton.Palette.ORANGE, GameButton.Palette.RED, GameButton.Palette.SAND]:
		assert_that(_palette.get_pixel(FRAME_COLUMN, row)).is_equal(_palette.get_pixel(2, row))


func test_the_dot_columns_hold_the_green_orange_and_teal_dots() -> void:
	assert_that(_palette.get_pixel(DOT_COLUMN + 2, GameButton.Palette.GREEN)).is_equal(Color8(93, 216, 93))
	assert_that(_palette.get_pixel(DOT_COLUMN + 2, GameButton.Palette.ORANGE)).is_equal(Color8(236, 136, 61))
	assert_that(_palette.get_pixel(DOT_COLUMN + 2, GameButton.Palette.BLUE)).is_equal(Color8(65, 167, 169))
	for column: int in range(DOT_COLUMN, DOT_COLUMN + DOT_SHADES):
		var grey: Color = _palette.get_pixel(column, GameButton.Palette.GREY)
		assert_bool(is_equal_approx(grey.r, grey.g) and is_equal_approx(grey.g, grey.b)).is_true()


func test_the_dot_shades_get_lighter_along_the_columns() -> void:
	for row: GameButton.Palette in GameButton.Palette.values():
		for column: int in range(DOT_COLUMN, DOT_COLUMN + DOT_SHADES - 1):
			assert_float(_palette.get_pixel(column, row).get_luminance()).is_less(_palette.get_pixel(column + 1, row).get_luminance())


func test_the_card_frame_stores_its_column_in_the_red_channel() -> void:
	var opaque: int = _assert_indices(CARD_FRAME.get_image(), FRAME_COLUMN, FRAME_COLUMN)

	assert_int(opaque).is_greater(0)


func test_the_level_dot_stores_its_shades_in_the_red_channel() -> void:
	var image: Image = LEVEL_DOT.get_image()
	var opaque: int = _assert_indices(image, DOT_COLUMN, DOT_COLUMN + DOT_SHADES - 1)
	var used: Dictionary[int, bool] = {}
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				used[roundi(image.get_pixel(x, y).r * 255.0)] = true

	assert_int(opaque).is_greater(0)
	assert_int(used.size()).is_equal(DOT_SHADES)


## Checks that every pixel has a red index between [param first] and [param last] and no green or blue, returns the opaque pixel count.
func _assert_indices(image: Image, first: int, last: int) -> int:
	var opaque: int = 0
	var invalid: int = 0
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			var index: int = roundi(pixel.r * 255.0)
			if index < first or index > last or pixel.g != 0.0 or pixel.b != 0.0:
				invalid += 1
			if pixel.a > 0.0:
				opaque += 1
	assert_int(invalid).override_failure_message("%d pixels are not an index in %d..%d" % [invalid, first, last]).is_equal(0)
	return opaque
