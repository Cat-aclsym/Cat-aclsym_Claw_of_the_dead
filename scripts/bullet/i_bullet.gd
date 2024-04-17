class_name IBullet
extends Area2D


@export var speed: int
@export var damage: int
@export var direction: Vector2
@export var target: Vector2


func _init():
	pass


func _exit_tree():
	#Log.debug("{0} _exit_tree()".format([name]))
	pass

func _physics_process(delta: float):
	position += direction * speed * delta

func _on_body_entered(body):
	if body is IEnemy:
		body.take_damage(damage, "default")
		queue_free()
	
