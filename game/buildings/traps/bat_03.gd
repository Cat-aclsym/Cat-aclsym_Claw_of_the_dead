## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A trap that captures an enemy, deals damage, and then destroys itself.
class_name Bat03
extends ITrap

## Speed modifier key, the [StatsDB] id of the trap.
const SPEED_KEY: StringName = &"bat_03"

## The amount of damage dealt when trap is triggered
@export var damage: int = 100

func apply_effect(enemy: IEnemy) -> void:
	# Deal instant damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT, self)

	# Immobilize the enemy if it survived, [member ITrap.effect_duration] later [method remove_effect] releases it
	if enemy.state != IEnemy.EnemyState.DEAD:
		enemy.set_speed_modifier(SPEED_KEY, 0.0)

func remove_effect(enemy: IEnemy) -> void:
	enemy.remove_speed_modifier(SPEED_KEY)
