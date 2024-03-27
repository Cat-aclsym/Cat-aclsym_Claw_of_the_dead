extends Camera2D

@export var zoom_speed: float = 0.1
@export var pan_speed: float = 1.0

var touch_points: Dictionary = {}
var start_distance: int
var start_zoom: Vector2


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("scroll_up"):
		zoom /= 0.9
		limit_zoom(zoom)
		
	if Input.is_action_just_pressed("scroll_down"):
		zoom *= 0.9
		limit_zoom(zoom)
		

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag:
		handle_drag(event)

func handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_points[event.index] = event.position
	else:
		touch_points.erase(event.index)
		
		if touch_points.size() == 2:
			var touch_point_positions: Array[Vector2] = touch_points.values()
			start_distance = touch_point_positions[0].distance_to(touch_point_positions[1])
			
			start_zoom = zoom
		elif touch_points.size() < 2:
			start_distance	 = 0
			

func handle_drag(event: InputEventScreenDrag) -> void:
	touch_points[event.index] = event.position
	
	if touch_points.size() == 1:
		position = position - event.relative * pan_speed / zoom.x

	elif touch_points.size() == 2:
		var touch_point_positions: Array[Vector2] = touch_points.values()
		var current_distance: int = touch_point_positions[0].distance_to(touch_point_positions[1])
		
		var zoom_factor = start_distance / current_distance
		zoom = start_zoom / zoom_factor
		limit_zoom(zoom)
			
func limit_zoom(new_zoom: Vector2) -> void:
	if new_zoom.x < 0.1:
		zoom.x = 0.1
	if new_zoom.y < 0.1:
		zoom.y = 0.1
	if new_zoom.x > 10.0:
		zoom.x = 10
	if new_zoom.y > 10.0:
		zoom.y = 10
