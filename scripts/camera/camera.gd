## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Handles camera movement, zoom and effects.
## [br]Drag and zoom are ignored while the game is paused, which includes the end screen of a level.
class_name Camera
extends Camera2D

## Shake strength under which the shake is over.
const SHAKE_END_THRESHOLD: float = 0.1

@export var zoom_speed: float = 0.1
@export var pan_speed: float = 1.0
@export var random_strength: float = 30.0
@export var shake_fade: float = 5.0
@export var min_zoom: float = 1.0
@export var max_zoom: float = 10.0
@export var bottom_padding: float = 650.0

var _touch_points: Dictionary[int, Vector2] = {}
var _start_distance: float
var _start_zoom: Vector2
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shake_strength: float = 0.0

# core
func _ready() -> void:
	Global.camera = self
	set_process(false)

## Only runs while a shake is active, see [method handle_effect].
func _process(delta: float) -> void:
	if Global.paused:
		return

	_process_shake(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag and not Global.paused:
		handle_drag(event)

func _unhandled_input(event: InputEvent) -> void:
	if Global.paused:
		return

	if event.is_action_pressed("scroll_up"):
		zoom /= 0.9
		clamp_zoom()
	elif event.is_action_pressed("scroll_down"):
		zoom *= 0.9
		clamp_zoom()

# public
## Clamps zoom between min and max values
func clamp_zoom() -> void:
	zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

## Initiates a camera shake effect
func shake_camera() -> void:
	shake_camera_with_strength(random_strength)

## Initiates a camera shake effect with a custom strength.
func shake_camera_with_strength(strength: float) -> void:
	_shake_strength = strength
	set_process(true)

## Handles touch input events
func handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_points[event.index] = event.position
	else:
		_touch_points.erase(event.index)

	if _touch_points.size() == 2:
		var touch_point_positions: Array = _touch_points.values()
		_start_distance = touch_point_positions[0].distance_to(touch_point_positions[1])
		_start_zoom = zoom
	elif _touch_points.size() < 2:
		_start_distance = 0

## Handles drag input events
func handle_drag(event: InputEventScreenDrag) -> void:
	_touch_points[event.index] = event.position

	if _touch_points.size() == 1:
		position = position - event.relative * pan_speed / zoom.x
		_clamp_position_to_limits()
	elif _touch_points.size() == 2:
		_handle_pinch_zoom()

## Handles camera effects
func handle_effect(effect: String, value: Variant = null) -> void:
	match effect:
		"shake":
			if value is float or value is int:
				shake_camera_with_strength(float(value))
			else:
				shake_camera()
		_:
			pass

# private
## Processes the camera shake effect
func _process_shake(delta: float) -> void:
	_shake_strength = lerpf(_shake_strength, 0.0, shake_fade * delta)
	if _shake_strength < SHAKE_END_THRESHOLD:
		_shake_strength = 0.0
		offset = Vector2.ZERO
		set_process(false)
		return

	offset = Vector2(
		_rng.randf_range(-_shake_strength, _shake_strength),
		_rng.randf_range(-_shake_strength, _shake_strength)
	)

## Handles pinch zoom input events
func _handle_pinch_zoom() -> void:
	var touch_point_positions: Array = _touch_points.values()
	var current_distance: float = touch_point_positions[0].distance_to(touch_point_positions[1])
	var zoom_factor: float = _start_distance / current_distance
	zoom = _start_zoom / zoom_factor
	clamp_zoom()

## Clamps position so the rendered view never drifts outside the Camera2D limits.
func _clamp_position_to_limits() -> void:
	var half: Vector2 = get_viewport_rect().size / zoom / 2.0
	position.x = clamp(position.x, limit_left + half.x, limit_right - half.x)
	position.y = clamp(position.y, limit_top + half.y, limit_bottom - half.y - bottom_padding)
