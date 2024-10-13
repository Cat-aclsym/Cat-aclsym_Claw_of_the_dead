class_name IBullet
extends Area2D


@export var speed: int
@export var damage: int
@export var direction: Vector2
@export var target: Vector2


# core
func _physics_process(delta: float):
	position += direction * speed * delta


# public


# private


# signal
func _on_body_entered(body):
	if body is IEnemy:
		body.take_damage(damage, "default")
		queue_free()


# event


# setget

