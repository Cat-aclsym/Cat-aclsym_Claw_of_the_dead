extends Node2D


@onready var cursor = $cursor


func _process(delta: float) -> void:
	cursor.position = get_global_mouse_position()
	var p: Vector2 = cursor.position
	var s := Vector2(128, 128)
	p = floor(p / s) * s + (s / 2)
	cursor.position = p
