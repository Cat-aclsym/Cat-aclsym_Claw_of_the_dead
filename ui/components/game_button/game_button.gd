## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Pixel-art button of the game: a grey 9-slice base ([enum Shape]) recolored by [code]palette_swap.gdshader[/code] with a row of
## [code]palette.png[/code] ([enum Palette]), plus an optional glyph ([GameIcon]) centered on the button.
## [br]Hover brightens the button, press darkens it and disabled removes its saturation. A toggle button swaps [member game_icon_pressed] and
## [member palette_pressed] in while [member BaseButton.button_pressed] is on, also after [method BaseButton.set_pressed_no_signal].
## A latched toggle with such a swap keeps full brightness (hover still brightens it): the swap is its pressed look.
## [br]An icon-only button of a fixed-proportion shape ([constant SCALED_SHAPES]) larger than its base draws the base and the glyph scaled up
## ([member art_scale]), centered and with the base proportions, instead of stretching its 9-slice. The scale is the largest factor that fits the button
## (at least 1, not always a whole number), so the pixels of the art are not all the same size on screen.
## [br]The text is dark ink, white on the [constant Palette.RED] palette: the button switches to the [code]<Shape>Inverse[/code] theme variation. The text size
## comes from [member text_style] ([code]ButtonText*[/code] types of [code]generic.tres[/code], a [code]TypeScale[/code] value), never from an override on the instance.
## [br]The tooltip is the [code]BUTTON.<ID>[/code] translation of the glyph unless [member Control.tooltip_text] is set. Instance [code]game_button.tscn[/code]:
## [codeblock]
## var button: GameButton = preload("res://ui/components/game_button/game_button.tscn").instantiate()
## button.shape = GameButton.Shape.RECT
## button.palette = GameButton.Palette.GREEN
## button.game_icon = GameIcon.Id.BUILD
## button.palette_pressed = GameButton.Palette.RED
## button.game_icon_pressed = GameIcon.Id.CLOSE
## button.toggle_mode = true
## button.text_style = GameButton.TextStyle.LARGE
## [/codeblock]
@tool
class_name GameButton
extends Button

## One row of [code]palette.png[/code] each, in that order.
enum Palette { BLUE, GREEN, ORANGE, RED, SAND, GREY }
## Base of the button, in the order of [constant BASES]. [code]NONE[/code] draws no base (glyph and text only).
enum Shape { RECT, RECT_SHORT, HEXA, PANEL, BANNER, NONE }
## Text size of the button, in the order of [constant TEXT_STYLES]. [code]DEFAULT[/code] keeps the size of the theme variation of the [enum Shape].
enum TextStyle { DEFAULT, SMALL, MEDIUM, LARGE, HERO, WAVE }

## Grey base of each [enum Shape], [code]null[/code] for [code]NONE[/code].
const BASES: Array[Texture2D] = [
	preload("res://assets/ui/buttons/bases/rect.png"),
	preload("res://assets/ui/buttons/bases/rect_short.png"),
	preload("res://assets/ui/buttons/bases/hexa.png"),
	preload("res://assets/ui/buttons/bases/panel.png"),
	preload("res://assets/ui/buttons/bases/banner.png"),
	null,
]
const BRIGHTNESS_HOVER: float = 1.15
const BRIGHTNESS_PRESSED: float = 0.8
const GLYPH_BRIGHTNESS_DISABLED: float = 0.6
## Tint of the single-color glyphs, on every palette but [constant Palette.RED] (white). The text uses the same color from the theme variations.
const INK: Color = Color(6.0 / 255.0, 40.0 / 255.0, 43.0 / 255.0)
## Theme variation (white text) of each [enum Shape] while the palette is [constant Palette.RED], same order as [constant VARIATIONS].
const INVERSE_VARIATIONS: Array[StringName] = [
	&"GameButtonRectInverse", &"GameButtonRectShortInverse", &"GameButtonHexaInverse", &"GameButtonPanelInverse", &"GameButtonBannerInverse", &"GameButtonNoneInverse",
]
## Left, top, right and bottom 9-slice margins of each [enum Shape] base, in pixels.
const MARGINS: Array[Vector4i] = [
	Vector4i(8, 8, 9, 9),
	Vector4i(8, 8, 9, 9),
	Vector4i(2, 10, 30, 13),
	Vector4i(11, 11, 13, 13),
	Vector4i(11, 11, 13, 13),
	Vector4i.ZERO,
]
## Value of [member palette_pressed] that keeps [member palette] while pressed.
const NO_PALETTE: int = -1
## Shapes that keep their proportions when an icon-only button is larger than the base.
const SCALED_SHAPES: Array[Shape] = [Shape.RECT, Shape.RECT_SHORT, Shape.HEXA]
## Data-only theme type (in [code]generic.tres[/code]) of each [enum TextStyle]: its [code]font_size[/code], and its [code]font[/code] when it has one.
const TEXT_STYLES: Array[StringName] = [
	&"", &"ButtonTextSmall", &"ButtonTextMedium", &"ButtonTextLarge", &"ButtonTextHero", &"ButtonTextWave",
]
## Theme variation (in [code]generic.tres[/code]) of each [enum Shape].
const VARIATIONS: Array[StringName] = [
	&"GameButtonRect", &"GameButtonRectShort", &"GameButtonHexa", &"GameButtonPanel", &"GameButtonBanner", &"GameButtonNone",
]

## Glyph drawn centered on the button.
@export var game_icon: GameIcon.Id = GameIcon.Id.NONE:
	set(value):
		game_icon = value
		queue_redraw()
## Glyph shown instead of [member game_icon] while the button is pressed, [code]NONE[/code] keeps [member game_icon].
@export var game_icon_pressed: GameIcon.Id = GameIcon.Id.NONE:
	set(value):
		game_icon_pressed = value
		queue_redraw()
@export var palette: Palette = Palette.BLUE:
	set(value):
		palette = value
		_sync_white_text()
		queue_redraw()
## Palette shown instead of [member palette] while the button is pressed, [constant NO_PALETTE] (the default) keeps [member palette].
@export var palette_pressed: Palette = NO_PALETTE as Palette:
	set(value):
		palette_pressed = value
		_sync_white_text()
		queue_redraw()
## Keeps the button clickable while the tree is paused ([constant Node.PROCESS_MODE_ALWAYS]): leave it on for buttons used while the tree is paused,
## such as the pause menu and the HUD during the tutorial, turn it off for the others so they stop with the game.
@export var process_when_paused: bool = true
## Sets the base and the matching theme variation.
@export var shape: Shape = Shape.RECT:
	set(value):
		shape = value
		theme_type_variation = _variation()
		if is_node_ready():
			_apply_shape()
## Text size ([code]ButtonText*[/code] theme type), applied in game as font overrides: the editor never applies them, so that a scene save does not store them.
## A type with a font (WAVE) swaps the font, the others keep the font of the theme variation.
@export var text_style: TextStyle = TextStyle.DEFAULT:
	set(value):
		text_style = value
		_apply_text_style()

## Factor the base and the glyph are drawn at: the largest one that fits the button (at least [code]1.0[/code], fractional) for an icon-only
## [constant SCALED_SHAPES] button larger than its base, else [code]1.0[/code].
var art_scale: float = 1.0

var _glyph_color: Color = INK
var _white_text: bool = false

@onready var _background: NinePatchRect = %Background
@onready var _material: ShaderMaterial = _background.material as ShaderMaterial


func _ready() -> void:
	assert(_background != null, "GameButton needs a %Background NinePatchRect.")
	assert(_material != null, "The %Background of a GameButton needs the palette ShaderMaterial.")
	_apply_shape()
	if not Engine.is_editor_hint():
		ButtonEffects.apply(self, process_when_paused)


func _draw() -> void:
	_fit_art()
	_refresh_look()
	var glyph: AtlasTexture = GameIcon.texture(get_effective_icon())
	if glyph != null:
		var cell: Vector2 = Vector2.ONE * GameIcon.CELL_SIZE
		# The cell is centered on whole pixels, the same way the bases were cut
		var origin: Vector2 = ((size - cell) / 2.0).ceil()
		if art_scale > 1.0:
			var base_size: Vector2 = BASES[shape].get_size()
			origin = (size - base_size * art_scale) / 2.0 + ((base_size - cell) / 2.0).ceil() * art_scale
		draw_texture_rect(glyph, Rect2(origin, cell * art_scale), false, _glyph_color)


func _get_tooltip(_at_position: Vector2) -> String:
	return tr(tooltip_text) if not tooltip_text.is_empty() else _icon_label()


func _toggled(_toggled_on: bool) -> void:
	_sync_white_text()


## Returns the glyph drawn now: [member game_icon_pressed] while pressed (if set), else [member game_icon].
func get_effective_icon() -> GameIcon.Id:
	return game_icon_pressed if button_pressed and game_icon_pressed != GameIcon.Id.NONE else game_icon


## Returns the palette drawn now: [member palette_pressed] while pressed (if set), else [member palette].
func get_effective_palette() -> Palette:
	return palette_pressed if button_pressed and palette_pressed != NO_PALETTE else palette


func _apply_shape() -> void:
	var base: Texture2D = BASES[shape]
	_background.visible = base != null
	queue_redraw()
	if base == null:
		return
	var margins: Vector4i = MARGINS[shape]
	_background.texture = base
	_background.patch_margin_left = margins.x
	_background.patch_margin_top = margins.y
	_background.patch_margin_right = margins.z
	_background.patch_margin_bottom = margins.w


## Copies the font size (and the font, when the type has one) of the [member text_style] theme type into the font overrides, [code]DEFAULT[/code] removes them.
func _apply_text_style() -> void:
	if Engine.is_editor_hint():
		return
	begin_bulk_theme_override()
	if text_style == TextStyle.DEFAULT:
		remove_theme_font_size_override(&"font_size")
		remove_theme_font_override(&"font")
	else:
		var theme: Theme = ThemeDB.get_project_theme()
		var type: StringName = TEXT_STYLES[text_style]
		add_theme_font_size_override(&"font_size", theme.get_font_size(&"font_size", type))
		# Theme.has_font is true for any type when the theme has a default font
		if &"font" in theme.get_font_list(type):
			add_theme_font_override(&"font", theme.get_font(&"font", type))
		else:
			remove_theme_font_override(&"font")
	end_bulk_theme_override()


## Sets [member art_scale] and places the base: filling the button, or at native size scaled up and centered.
func _fit_art() -> void:
	var base: Texture2D = BASES[shape]
	art_scale = 1.0
	if base != null and text.is_empty() and shape in SCALED_SHAPES:
		art_scale = maxf(1.0, minf(size.x / base.get_width(), size.y / base.get_height()))
	if art_scale > 1.0:
		_background.scale = Vector2.ONE * art_scale
		_background.size = base.get_size()
		_background.position = (size - _background.size * art_scale) / 2.0
	else:
		_background.scale = Vector2.ONE
		_background.size = size
		_background.position = Vector2.ZERO


## Returns the [code]BUTTON.<ID>[/code] translation of the drawn glyph, empty without glyph.
func _icon_label() -> String:
	var icon: GameIcon.Id = get_effective_icon()
	return "" if icon == GameIcon.Id.NONE else tr("BUTTON." + GameIcon.key(icon))


## Pushes the palette row, brightness, saturation and glyph tint matching the state to the base material and to [method _draw].
func _refresh_look() -> void:
	var brightness: float = 1.0
	var glyph_brightness: float = 1.0
	var saturation: float = 1.0
	match get_draw_mode():
		DRAW_HOVER:
			brightness = BRIGHTNESS_HOVER
		DRAW_PRESSED:
			brightness = 1.0 if _shows_latched_swap() else BRIGHTNESS_PRESSED
		DRAW_HOVER_PRESSED:
			brightness = BRIGHTNESS_HOVER if _shows_latched_swap() else BRIGHTNESS_PRESSED
		DRAW_DISABLED:
			saturation = 0.0
			glyph_brightness = GLYPH_BRIGHTNESS_DISABLED
	var current_palette: Palette = get_effective_palette()
	_material.set_shader_parameter(&"palette_row", current_palette)
	_material.set_shader_parameter(&"brightness", brightness)
	_material.set_shader_parameter(&"saturation", saturation)

	var is_white: bool = current_palette == Palette.RED or GameIcon.is_multicolor(get_effective_icon())
	var tint: Color = Color.WHITE if is_white else INK
	var glyph_scale: float = brightness * glyph_brightness
	_glyph_color = Color(tint.r * glyph_scale, tint.g * glyph_scale, tint.b * glyph_scale)

	# accessibility_name is a stored property: assigned in the editor, the next scene save would write it into every instance
	var label: String = _icon_label()
	if not Engine.is_editor_hint() and text.is_empty() and accessibility_name != label:
		accessibility_name = label
	_set_white_text(current_palette == Palette.RED)


## Switches the text of the button to white (RED palette) or back to the dark ink through the theme variation, only in game: the editor never saves it.
func _set_white_text(white: bool) -> void:
	if white == _white_text or Engine.is_editor_hint():
		return
	_white_text = white
	theme_type_variation = _variation()
	# Button draws its text before _draw and a redraw queued while drawing is dropped, so the new color needs the next frame
	queue_redraw.call_deferred()


## Returns [code]true[/code] for a latched toggle whose pressed look is another glyph or palette: that look is its resting state, so it is not darkened.
func _shows_latched_swap() -> bool:
	return toggle_mode and (palette_pressed != NO_PALETTE or game_icon_pressed != GameIcon.Id.NONE)


## Applies the text color of the palette drawn now at once, so that the first frame with a RED palette already has white text.
## [br]A state change that no setter or [method _toggled] sees (such as [method BaseButton.set_pressed_no_signal]) is caught by [method _refresh_look] in [method _draw].
func _sync_white_text() -> void:
	_set_white_text(get_effective_palette() == Palette.RED)


## Returns the theme variation of the shape: the [code]Inverse[/code] one (white text) while the palette is RED.
func _variation() -> StringName:
	return (INVERSE_VARIATIONS if _white_text else VARIATIONS)[shape]
