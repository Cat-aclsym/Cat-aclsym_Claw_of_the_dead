## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Handles camera movement, zoom and effects
class_name Camera
extends Camera2D

@export var zoom_speed: float = 0.1
@export var pan_speed: float = 1.0
@export var random_strength: float = 30.0
@export var shake_fade: float = 5.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 10.0

var _touch_points: Dictionary = {}
var _start_distance: float
var _start_zoom: Vector2
var _rng := RandomNumberGenerator.new()
var _shake_strength: float = 0.0

# core
func _ready() -> void:
    Global.camera = self

func _process(delta: float) -> void:
    if Global.paused:
        return

    _process_shake(delta)
    _process_zoom()

func _input(event: InputEvent) -> void:
    if Global.paused:
        return

    if event is InputEventScreenTouch:
        handle_touch(event)
    elif event is InputEventScreenDrag:
        handle_drag(event)

# public
## Clamps zoom between min and max values
func clamp_zoom() -> void:
    zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

## Initiates a camera shake effect
func shake_camera() -> void:
    _shake_strength = random_strength

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
    elif _touch_points.size() == 2:
        _handle_pinch_zoom()

## Handles camera effects
func handle_effect(effect: String) -> void:
    Log.trace(Log.Level.DEBUG, "Playing '%s' camera effect" % effect)
    match effect:
        "shake":
            shake_camera()
        _:
            pass

# private
## Processes the camera shake effect
func _process_shake(delta: float) -> void:
    if _shake_strength > 0:
        _shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)
        offset = Vector2(
            _rng.randf_range(-_shake_strength, _shake_strength),
            _rng.randf_range(-_shake_strength, _shake_strength)
        )

## Handles zoom input events
func _process_zoom() -> void:
    if Input.is_action_just_pressed("scroll_up"):
        zoom /= 0.9
        clamp_zoom()
    if Input.is_action_just_pressed("scroll_down"):
        zoom *= 0.9
        clamp_zoom()

## Handles pinch zoom input events
func _handle_pinch_zoom() -> void:
    var touch_point_positions: Array = _touch_points.values()
    var current_distance: float = touch_point_positions[0].distance_to(touch_point_positions[1])
    var zoom_factor: float = _start_distance / current_distance
    zoom = _start_zoom / zoom_factor
    clamp_zoom()
