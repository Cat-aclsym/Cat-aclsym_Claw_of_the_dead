## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Health bar component for enemies.
## Displays a color-coded health bar that changes color progressively based on health percentage.
## [br]The three panels take their look from the [code]HealthBarBackground[/code], [code]HealthBarFill[/code] and [code]HealthBarBorder[/code] theme variations,
## the fill is white and tinted by its [member CanvasItem.self_modulate].
class_name EnemyHealthBar
extends CanvasGroup

const BAR_HEIGHT: float = 12.0
const COLOR_CRITICAL: Color = Color(1.0, 0.0, 0.0, 1.0)
const COLOR_FULL: Color = Color(0.0, 1.0, 0.0, 1.0)
const COLOR_LOW: Color = Color(1.0, 0.5, 0.0, 1.0)
const COLOR_MID: Color = Color(0.8, 1.0, 0.0, 1.0)
const FADE_ALPHA: float = 0.5
const FADE_DELAY: float = 4.0
const FADE_DURATION: float = 1.0
const FADE_IN_DURATION: float = 0.1
const MAX_WIDTH: float = 128.0
const SCALE_FACTOR: float = 0.25

var _fade_tween: Tween

@onready var background: Panel = $Background
@onready var border: Panel = $Border
@onready var fill: Panel = $Fill

func _ready() -> void:
	modulate.a = 0.0
	scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
	_setup_panels()

## Update the health bar based on current health percentage
## [param current_health] The current health value
## [param max_health] The maximum health value
func update_health(current_health: float, max_health: float) -> void:
	if max_health <= 0:
		return

	var health_percentage: float = clamp(current_health / max_health, 0.0, 1.0)

	fill.size.x = MAX_WIDTH * health_percentage
	fill.self_modulate = _get_health_color(health_percentage)

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

func _setup_panels() -> void:
	background.size = Vector2(MAX_WIDTH, BAR_HEIGHT)
	fill.size = Vector2(MAX_WIDTH, BAR_HEIGHT)
	fill.self_modulate = COLOR_FULL
	border.size = Vector2(MAX_WIDTH, BAR_HEIGHT)
