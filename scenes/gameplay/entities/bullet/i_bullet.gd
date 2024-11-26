## © [2024] A7 Studio. All rights reserved. Trademark.
class_name IBullet
extends Area2D


@export var speed: int
@export var damage: int
@export var direction: Vector2
@export var target: Vector2

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: self, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_body_entered}
]


# core
func _ready() -> void:
	SignalUtil.connects(signals)


func _physics_process(delta: float) -> void:
	if Global.paused:
		return

	position += direction * speed * delta


# public


# private


# signal
func _on_body_entered(body):
	if body is IEnemy:
		body.take_damage(damage, IEnemy.DamageType.DEFAULT)
		queue_free()


# event


# setget