class_name IBullet
extends Area2D


@export var speed: int
@export var damage: int
@export var direction: Vector2
@export var target: Vector2


func _init():
	pass


func _physics_process(delta: float):
	position += direction * speed * delta

	if global_position.distance_to(target) < 100:
		print("Target: ", target)
		print("Global Position: ", global_position)
		queue_free()


func _on_area_entered(area):
	pass
