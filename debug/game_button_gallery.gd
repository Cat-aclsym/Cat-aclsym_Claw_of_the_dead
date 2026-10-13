## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Debug preview of every [enum GameButton.Shape] x [enum GameButton.Palette], with text, toggle, flag and disabled examples.
## Run it with [code]godot --path . res://debug/game_button_gallery.tscn[/code], or render it with [code]--write-movie[/code].
extends Control

const BUTTON_SCENE: PackedScene = preload("res://ui/components/game_button/game_button.tscn")
## Shape, glyph, native size of its base and display scale of each column of a palette row.
const COLUMNS: Array[Dictionary] = [
	{"shape": GameButton.Shape.RECT, "icon": GameIcon.Id.PLAY, "size": Vector2(46, 39), "scale": 3},
	{"shape": GameButton.Shape.RECT_SHORT, "icon": GameIcon.Id.PAUSE, "size": Vector2(46, 31), "scale": 3},
	{"shape": GameButton.Shape.HEXA, "icon": GameIcon.Id.INFO, "size": Vector2(34, 39), "scale": 3},
	{"shape": GameButton.Shape.PANEL, "icon": GameIcon.Id.HOME, "size": Vector2(44, 44), "scale": 3},
	{"shape": GameButton.Shape.BANNER, "icon": GameIcon.Id.TROPHY, "size": Vector2(187, 44), "scale": 2},
]

@onready var _extras: VBoxContainer = %Extras
@onready var _palettes: VBoxContainer = %Palettes


func _ready() -> void:
	# The gallery is meant to be seen pixel for pixel, whatever the window size
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for palette: GameButton.Palette in GameButton.Palette.values():
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 14)
		row.add_child(_label(GameButton.Palette.keys()[palette], 80))
		for column: Dictionary in COLUMNS:
			row.add_child(_cell(column.shape, palette, column.icon, column.size, column.scale))
		_palettes.add_child(row)
	_build_extras()
	# ButtonEffects centers the pivot when the buttons enter the tree: the scaled buttons must grow from their corner
	await get_tree().process_frame
	for button: Node in find_children("*", "GameButton", true, false):
		(button as GameButton).pivot_offset_ratio = Vector2.ZERO


func _build_extras() -> void:
	_add_section("Text (stretched bases, white text on RED)")
	var texts: HBoxContainer = _add_row()
	texts.add_child(_cell(GameButton.Shape.PANEL, GameButton.Palette.BLUE, GameIcon.Id.NONE, Vector2(170, 56), 1, "PLAY"))
	texts.add_child(_cell(GameButton.Shape.RECT, GameButton.Palette.ORANGE, GameIcon.Id.NONE, Vector2(110, 48), 1, "OK"))
	texts.add_child(_cell(GameButton.Shape.RECT, GameButton.Palette.RED, GameIcon.Id.NONE, Vector2(110, 48), 1, "NO"))
	var banners: HBoxContainer = _add_row()
	banners.add_child(_cell(GameButton.Shape.BANNER, GameButton.Palette.GREEN, GameIcon.Id.NONE, Vector2(260, 50), 1, "BUY  120"))
	banners.add_child(_cell(GameButton.Shape.BANNER, GameButton.Palette.SAND, GameIcon.Id.NONE, Vector2(200, 50), 1, "SOLD"))

	_add_section("Toggles (off, on): BUILD / CLOSE red, SOUND / SOUND_OFF, flags, arrows without base")
	var toggles: HBoxContainer = _add_row()
	for pressed: bool in [false, true]:
		var build: GameButton = _button(GameButton.Shape.RECT, GameButton.Palette.GREEN, GameIcon.Id.BUILD, Vector2(46, 39), 2)
		build.palette_pressed = GameButton.Palette.RED
		build.game_icon_pressed = GameIcon.Id.CLOSE
		toggles.add_child(_toggle(build, pressed, Vector2(46, 39), 2))
	for pressed: bool in [false, true]:
		var sound: GameButton = _button(GameButton.Shape.RECT, GameButton.Palette.BLUE, GameIcon.Id.SOUND, Vector2(46, 39), 2)
		sound.game_icon_pressed = GameIcon.Id.SOUND_OFF
		toggles.add_child(_toggle(sound, pressed, Vector2(46, 39), 2))
	toggles.add_child(_cell(GameButton.Shape.RECT, GameButton.Palette.BLUE, GameIcon.Id.FLAG_EN, Vector2(46, 39), 2))
	toggles.add_child(_cell(GameButton.Shape.RECT, GameButton.Palette.BLUE, GameIcon.Id.FLAG_FR, Vector2(46, 39), 2))
	toggles.add_child(_cell(GameButton.Shape.NONE, GameButton.Palette.BLUE, GameIcon.Id.ARROW_LEFT, Vector2(64, 64), 1))
	toggles.add_child(_cell(GameButton.Shape.NONE, GameButton.Palette.BLUE, GameIcon.Id.ARROW_RIGHT, Vector2(64, 64), 1))

	_add_section("Disabled (saturation 0)")
	var disabled: HBoxContainer = _add_row()
	for column: Dictionary in COLUMNS:
		var holder: Control = _cell(column.shape, GameButton.Palette.GREEN, column.icon, column.size, 2 if column.scale == 3 else 1)
		(holder.get_child(0) as GameButton).disabled = true
		disabled.add_child(holder)

	_add_section("Every glyph (BLUE RECT, RED RECT, 1x)")
	var glyphs: GridContainer = GridContainer.new()
	glyphs.columns = 9
	glyphs.add_theme_constant_override(&"h_separation", 6)
	glyphs.add_theme_constant_override(&"v_separation", 6)
	_extras.add_child(glyphs)
	for palette: GameButton.Palette in [GameButton.Palette.BLUE, GameButton.Palette.RED]:
		for icon: GameIcon.Id in GameIcon.Id.values().slice(1):
			glyphs.add_child(_cell(GameButton.Shape.RECT, palette, icon, Vector2(46, 39), 1))


func _add_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	_extras.add_child(row)
	return row


func _add_section(title: String) -> void:
	_extras.add_child(_label(title, 0))


## Returns a button of [param native_size] drawn at [param display_scale] from its top-left corner, [param text] makes it a text button.
func _button(shape: GameButton.Shape, palette: GameButton.Palette, icon: GameIcon.Id, native_size: Vector2, display_scale: int, text: String = "") -> GameButton:
	var button: GameButton = BUTTON_SCENE.instantiate()
	button.shape = shape
	button.palette = palette
	button.game_icon = icon
	button.text = text
	button.custom_minimum_size = native_size
	button.scale = Vector2.ONE * display_scale
	return button


## Returns a holder sized to the scaled button.
func _cell(shape: GameButton.Shape, palette: GameButton.Palette, icon: GameIcon.Id, native_size: Vector2, display_scale: int, text: String = "") -> Control:
	return _holder(_button(shape, palette, icon, native_size, display_scale, text), native_size, display_scale)


func _holder(button: GameButton, native_size: Vector2, display_scale: int) -> Control:
	var holder: Control = Control.new()
	holder.custom_minimum_size = native_size * display_scale
	holder.add_child(button)
	return holder


func _label(text: String, min_width: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.custom_minimum_size.x = min_width
	label.add_theme_font_size_override(&"font_size", 16)
	label.add_theme_color_override(&"font_color", Color(1.0, 0.92, 0.47))
	return label


func _toggle(button: GameButton, pressed: bool, native_size: Vector2, display_scale: int) -> Control:
	button.toggle_mode = true
	button.set_pressed_no_signal(pressed)
	return _holder(button, native_size, display_scale)
