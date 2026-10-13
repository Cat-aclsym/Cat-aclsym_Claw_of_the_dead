## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Pixel-art button of the game: a grey 9-slice base ([enum Shape]) recolored by [code]palette_swap.gdshader[/code] with a row of
## [code]palette.png[/code] ([enum Palette]), plus an optional glyph ([GameIcon]) centered on the button.
## [br]Hover brightens the button, press darkens it and disabled removes its saturation. A toggle button swaps [member game_icon_pressed] and
## [member palette_pressed] in while [member BaseButton.button_pressed] is on, also after [method BaseButton.set_pressed_no_signal].
## A latched toggle with such a swap keeps full brightness (hover still brightens it): the swap is its pressed look.
## [br]An icon-only button of a fixed-proportion shape ([constant SCALED_SHAPES]) larger than its base draws the base and the glyph scaled up
## ([member art_scale]), centered and with the base proportions, so a big button keeps the pixel grain of the art instead of stretching its 9-slice.
## [br]The tooltip is the [code]BUTTON.<ID>[/code] translation of the glyph unless [member Control.tooltip_text] is set. Instance [code]game_button.tscn[/code]:
## [codeblock]
## var button: GameButton = preload("res://ui/components/game_button/game_button.tscn").instantiate()
## button.shape = GameButton.Shape.RECT
## button.palette = GameButton.Palette.GREEN
## button.game_icon = GameIcon.Id.BUILD
## button.palette_pressed = GameButton.Palette.RED
## button.game_icon_pressed = GameIcon.Id.CLOSE
## button.toggle_mode = true
## [/codeblock]
@tool
class_name GameButton
extends Button

## One row of [code]palette.png[/code] each, in that order.
enum Palette { BLUE, GREEN, ORANGE, RED, SAND, GREY }
## Base of the button, in the order of [constant BASES]. [code]NONE[/code] draws no base (glyph and text only).
enum Shape { RECT, RECT_SHORT, HEXA, PANEL, BANNER, NONE }

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
const FONT_COLORS: Array[StringName] = [
	&"font_color", &"font_disabled_color", &"font_focus_color", &"font_hover_color", &"font_hover_pressed_color", &"font_pressed_color",
]
const GLYPH_BRIGHTNESS_DISABLED: float = 0.6
## Tint of the single-color glyphs and of the text, on every palette but [constant Palette.RED] (white).
const INK: Color = Color(6.0 / 255.0, 40.0 / 255.0, 43.0 / 255.0)
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
		queue_redraw()
## Palette shown instead of [member palette] while the button is pressed, [constant NO_PALETTE] (the default) keeps [member palette].
@export var palette_pressed: Palette = NO_PALETTE as Palette:
	set(value):
		palette_pressed = value
		queue_redraw()
## Sets the base and the matching theme variation.
@export var shape: Shape = Shape.RECT:
	set(value):
		shape = value
		theme_type_variation = VARIATIONS[value]
		if is_node_ready():
			_apply_shape()

## Factor the base and the glyph are drawn at, [code]1.0[/code] unless an icon-only [constant SCALED_SHAPES] button is larger than its base.
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
		ButtonEffects.apply(self)


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

	var label: String = _icon_label()
	if text.is_empty() and accessibility_name != label:
		accessibility_name = label
	_set_white_text(current_palette == Palette.RED)


## Returns [code]true[/code] for a latched toggle whose pressed look is another glyph or palette: that look is its resting state, so it is not darkened.
func _shows_latched_swap() -> bool:
	return toggle_mode and (palette_pressed != NO_PALETTE or game_icon_pressed != GameIcon.Id.NONE)


## Switches the text of the button to white (RED palette) or back to the theme color, only in game: the editor never saves the overrides.
func _set_white_text(white: bool) -> void:
	if white == _white_text or Engine.is_editor_hint():
		return
	_white_text = white
	for color_name: StringName in FONT_COLORS:
		if white:
			add_theme_color_override(color_name, Color.WHITE)
		else:
			remove_theme_color_override(color_name)
