class_name Camera
extends Camera2D

@export var zoom_speed: float = 0.1
@export var pan_speed: float = 1.0
@export var random_strength: float = 30.0
@export var shake_fade: float = 5.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 10.0

var touch_points: Dictionary = {}
var start_distance: float
var start_zoom: Vector2
var rng := RandomNumberGenerator.new()
var shake_strength: float = 0.0


# core
func _ready():
	Global.camera = self


func _process(delta: float) -> void:
	if Global.paused: return

	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
		offset = Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))

	if Input.is_action_just_pressed("scroll_up"):
		zoom /= 0.9
		clamp_zoom()

	if Input.is_action_just_pressed("scroll_down"):
		zoom *= 0.9
		clamp_zoom()


func _input(event: InputEvent) -> void:
	if Global.paused: return

	if event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag:
		handle_drag(event)


# public

func handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_points[event.index] = event.position
	else:
		touch_points.erase(event.index)

	if touch_points.size() == 2:
		var touch_point_positions: Array = touch_points.values()
		start_distance = touch_point_positions[0].distance_to(touch_point_positions[1])
		start_zoom = zoom
	elif touch_points.size() < 2:
		start_distance = 0


func handle_drag(event: InputEventScreenDrag) -> void:
	touch_points[event.index] = event.position

	if touch_points.size() == 1:
		position = position - event.relative * pan_speed / zoom.x

	elif touch_points.size() == 2:
		var touch_point_positions: Array = touch_points.values()
		var current_distance: float = touch_point_positions[0].distance_to(touch_point_positions[1])

		var zoom_factor: float = start_distance / current_distance
		zoom = start_zoom / zoom_factor
		clamp_zoom()


## Clamp zoom to [0.1, 10.0]
func clamp_zoom() -> void:
	zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))


func handle_effect(effect: String) -> void:
	Log.trace(Log.Level.DEBUG, "Playing '%s' camera effect" % effect)
	match effect:
		"shake":
			shake_camera()
		_:
			pass


func shake_camera() -> void:
	shake_strength = random_strength


# private


# signal


# event


# setget
