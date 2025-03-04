## © [2024] A7 Studio. All rights reserved. Trademark.
##
## A trap that captures an enemy, deals damage, and then destroys itself.
class_name BearTrap
extends ITrap

## The amount of damage dealt when trap is triggered
@export var damage: int = 100

## Dictionary to store original speeds
var original_speeds: Dictionary = {}

func _ready() -> void:
	super()

func apply_effect(enemy: IEnemy) -> void:
	# Deal instant damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
	# Store original speed and immobilize if not dead
	if enemy.state != IEnemy.EnemyState.DEAD:
		original_speeds[enemy] = enemy.speed
		enemy.speed = 0

func remove_effect(enemy: IEnemy) -> void:
	# Restore original speed
	if enemy in original_speeds:
		enemy.speed = original_speeds[enemy]
		original_speeds.erase(enemy)
