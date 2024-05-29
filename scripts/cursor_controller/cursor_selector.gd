extends Node2D

# TODO :
# state machine : idle / build / upgrade
# fix offset
# placement tour
	# apparition tour
	# modification argent
	# trigger que si placement ok
	# griser tour si placement pas ok
# BONUS :
# menu amelioration
# amelioration
# destruction (vente)

@onready var cursor = $cursor


func _process(delta: float) -> void:
	cursor.position = get_global_mouse_position()
	var p: Vector2 = cursor.position
	var s := Vector2(32, 32)
	p = floor(p / s) * s + (s / 2)
	cursor.position = p
