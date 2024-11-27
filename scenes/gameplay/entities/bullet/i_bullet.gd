## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Interface for bullet entities.
class_name IBullet
extends Area2D

## Defines the different types of bullets and their behaviors
enum BulletType {
	DEFAULT, ## Standard projectile with basic damage
	PIERCING, ## Penetrates through multiple enemies
	EXPLOSIVE, ## Creates an area of effect on impact
}

## Movement speed of the bullet in pixels per second
@export var speed: int

## Base damage value dealt to enemies
@export var damage: int

## Normalized vector indicating bullet's movement direction
@export var direction: Vector2

## Final destination point for the bullet
@export var target: Vector2

## Signal connections to be established in _ready
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

func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy:
		return

	var enemy := body as IEnemy
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	queue_free()
