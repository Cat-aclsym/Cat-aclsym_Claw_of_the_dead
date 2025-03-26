## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Interface for bullet entities.
class_name IBullet
extends Area2D

# exports
@export var damage: int ## Base damage value dealt to enemies	
@export var speed: int ## Speed of the bullet

@export_subgroup("Damage over Time")
@export var has_dot: bool ## Whether the bullet can apply damage over time
@export var dot_damage: int ## Damage per tick
@export var dot_duration: int ## Duration of the damage over time
@export var dot_tick: int ## Number of ticks the damage over time lasts

# public
## Normalized vector indicating bullet's movement direction
var direction: Vector2
## Final destination point for the bullet
var target: Vector2

# private
## Initial damage value to calculate percentage reduction
var initial_damage: int

## Signal connections to be established in _ready
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: self, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_body_entered}
]

## Store the enemy that the bullet has touched to prevent multiple hits
var _touched_enemy: IEnemy


# core
func _ready() -> void:
	SignalUtil.connects(signals)
	initial_damage = damage


func _physics_process(delta: float) -> void:
	if Global.paused:
		return

	position += direction * speed * delta


# private
func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy or _touched_enemy != null:
		return

	_touched_enemy = body as IEnemy
	var enemy := body as IEnemy
	
	# Apply base damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
	# Handle DoT
	if has_dot:
		enemy.add_poison_effect(dot_damage, dot_duration, dot_tick)
	
	# Free the bullet 
	queue_free()
