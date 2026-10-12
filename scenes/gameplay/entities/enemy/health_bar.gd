## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Health bar component for enemies.
## Displays a color-coded health bar that changes color progressively based on health percentage.
class_name EnemyHealthBar
extends CanvasGroup

const BAR_HEIGHT: float = 12.0
const BORDER_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const BORDER_WIDTH: int = 1
const COLOR_BACKGROUND: Color = Color(0.2, 0.2, 0.2, 1.0)
const COLOR_CRITICAL: Color = Color(1.0, 0.0, 0.0, 1.0)
const COLOR_FULL: Color = Color(0.0, 1.0, 0.0, 1.0)
const COLOR_LOW: Color = Color(1.0, 0.5, 0.0, 1.0)
const COLOR_MID: Color = Color(0.8, 1.0, 0.0, 1.0)
const CORNER_RADIUS: int = 8
const FADE_ALPHA: float = 0.5
const FADE_DELAY: float = 4.0
const FADE_DURATION: float = 1.0
const FADE_IN_DURATION: float = 0.1
const MAX_WIDTH: float = 128.0
const SCALE_FACTOR: float = 0.25

var _fade_tween: Tween
## Style of the fill panel, cached by [method _setup_corner_radius].
var _fill_style: StyleBoxFlat

## Background and border styles never change, so every health bar shares them. The fill color changes per enemy, so its style is per bar.
static var _style_background: StyleBoxFlat = _make_style(COLOR_BACKGROUND)
static var _style_border: StyleBoxFlat = _make_border_style()

@onready var background: Panel = $Background
@onready var border: Panel = $Border
@onready var fill: Panel = $Fill

func _ready() -> void:
	modulate.a = 0.0
	scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
	_setup_corner_radius()

## Update the health bar based on current health percentage
## [param current_health] The current health value
## [param max_health] The maximum health value
func update_health(current_health: float, max_health: float) -> void:
	if max_health <= 0:
		return

	var health_percentage: float = clamp(current_health / max_health, 0.0, 1.0)

	fill.size.x = MAX_WIDTH * health_percentage
	_fill_style.bg_color = _get_health_color(health_percentage)

	# Fades the bar in, then out once it is left alone for FADE_DELAY, a hit restarts the whole sequence
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)
	_fade_tween.tween_interval(FADE_DELAY - FADE_IN_DURATION)
	_fade_tween.tween_property(self, "modulate:a", FADE_ALPHA, FADE_DURATION)

func _get_health_color(percentage: float) -> Color:
	if percentage > 0.5:
		return COLOR_FULL.lerp(COLOR_MID, (1.0 - percentage) * 2.0)
	elif percentage > 0.25:
		return COLOR_MID.lerp(COLOR_LOW, (0.5 - percentage) * 4.0)
	else:
		return COLOR_LOW.lerp(COLOR_CRITICAL, (0.25 - percentage) * 4.0)

static func _make_border_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _make_style(Color(0, 0, 0, 0))  # Transparent background
	style.set_border_width_all(BORDER_WIDTH)
	style.border_color = BORDER_COLOR
	return style

static func _make_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(CORNER_RADIUS)
	return style

func _setup_corner_radius() -> void:
	background.add_theme_stylebox_override("panel", _style_background)
	background.size = Vector2(MAX_WIDTH, BAR_HEIGHT)

	_fill_style = _make_style(COLOR_FULL)
	fill.add_theme_stylebox_override("panel", _fill_style)
	fill.size = Vector2(MAX_WIDTH, BAR_HEIGHT)

	border.add_theme_stylebox_override("panel", _style_border)
	border.size = Vector2(MAX_WIDTH, BAR_HEIGHT)
