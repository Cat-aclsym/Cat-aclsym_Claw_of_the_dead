## © [2025] A7 Studio. All rights reserved. Trademark.
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
const MAX_WIDTH: float = 128.0
const SCALE_FACTOR: float = 0.25

var _fade_timer: Timer
var _has_taken_damage: bool = false

@onready var background: Panel = $Background
@onready var fill: Panel = $Fill
@onready var border: Panel = $Border

func _ready() -> void:
	modulate.a = 0.0
	scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
	_setup_corner_radius()
	_setup_fade_timer()

## Update the health bar based on current health percentage
## [param current_health] The current health value
## [param max_health] The maximum health value
func update_health(current_health: float, max_health: float) -> void:
	if max_health <= 0:
		return

	var health_percentage: float = clamp(current_health / max_health, 0.0, 1.0)

	fill.size.x = MAX_WIDTH * health_percentage
	var new_color := _get_health_color(health_percentage)

	var style: StyleBoxFlat = fill.get_theme_stylebox("panel")
	if style:
		style.bg_color = new_color

	if not _has_taken_damage:
		_has_taken_damage = true
		_show_bar()
	else:
		_reset_fade_timer()

func _get_health_color(percentage: float) -> Color:
	if percentage > 0.5:
		return COLOR_FULL.lerp(COLOR_MID, (1.0 - percentage) * 2.0)
	elif percentage > 0.25:
		return COLOR_MID.lerp(COLOR_LOW, (0.5 - percentage) * 4.0)
	else:
		return COLOR_LOW.lerp(COLOR_CRITICAL, (0.25 - percentage) * 4.0)

func _setup_corner_radius() -> void:
	var style_bg := StyleBoxFlat.new()
	style_bg.bg_color = COLOR_BACKGROUND
	style_bg.set_corner_radius_all(CORNER_RADIUS)
	background.add_theme_stylebox_override("panel", style_bg)
	background.size = Vector2(MAX_WIDTH, BAR_HEIGHT)

	var style_fill := StyleBoxFlat.new()
	style_fill.bg_color = COLOR_FULL
	style_fill.set_corner_radius_all(CORNER_RADIUS)
	fill.add_theme_stylebox_override("panel", style_fill)
	fill.size = Vector2(MAX_WIDTH, BAR_HEIGHT)

	var style_border := StyleBoxFlat.new()
	style_border.bg_color = Color(0, 0, 0, 0)  # Transparent background
	style_border.set_corner_radius_all(CORNER_RADIUS)
	style_border.border_width_left = BORDER_WIDTH
	style_border.border_width_right = BORDER_WIDTH
	style_border.border_width_top = BORDER_WIDTH
	style_border.border_width_bottom = BORDER_WIDTH
	style_border.border_color = BORDER_COLOR
	border.add_theme_stylebox_override("panel", style_border)
	border.size = Vector2(MAX_WIDTH, BAR_HEIGHT)

func _setup_fade_timer() -> void:
	_fade_timer = Timer.new()
	_fade_timer.wait_time = FADE_DELAY
	_fade_timer.one_shot = true
	_fade_timer.timeout.connect(_on_fade_timer_timeout)
	add_child(_fade_timer)

func _show_bar() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	_reset_fade_timer()

func _reset_fade_timer() -> void:
	if _fade_timer:
		_fade_timer.stop()
		_fade_timer.start()
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.1)

func _on_fade_timer_timeout() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", FADE_ALPHA, FADE_DURATION)
