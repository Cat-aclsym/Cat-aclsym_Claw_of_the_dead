## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A trap that applies a poison effect (damage over time) to enemies.
class_name Bat06
extends ITrap


## Damage per poison tick
@export var poison_damage: float = 5.0

## Interval between ticks in seconds
@export var poison_interval: float = 1.0

## Number of damage ticks
@export var poison_ticks: int = 5


# public
## Applies the poison effect when an enemy enters the trap.
## [br]
## Note: This trap applies the effect once upon entry.
## [param enemy] The enemy to poison.
func apply_effect(enemy: IEnemy) -> void:
	enemy.add_poison_effect(poison_damage, poison_ticks, poison_interval)
