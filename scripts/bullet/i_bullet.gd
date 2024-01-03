class_name IBullet
extends Area2D

@export var speed: int
@export var damage: int

var direction: Vector2

func _init():
	pass

func _physics_process(delta):
	for __ in range(speed*delta):
		position += direction

func _on_area_entered(area):
	pass
