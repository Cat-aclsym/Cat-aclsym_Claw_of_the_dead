## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A trap that slows down enemies while they are on it.
class_name Bat04
extends ITrap

## Speed modifier key, the [StatsDB] id of the trap: two slow traps never stack on one enemy.
const SPEED_KEY: StringName = &"bat_04"
## Group of every slow trap, set in the scene.
const TRAPS_GROUP: StringName = &"bat_04_traps"

## The slow effect percentage (0.5 = 50% slower)
@export var slow_amount: float = 0.75

func apply_effect(enemy: IEnemy) -> void:
	enemy.set_speed_modifier(SPEED_KEY, 1.0 - slow_amount)

func remove_effect(enemy: IEnemy) -> void:
	# The slow stays while another active slow trap still holds the enemy.
	for other: Bat04 in get_tree().get_nodes_in_group(TRAPS_GROUP):
		if other != self and not other.is_temporarily_disabled and enemy in other.enemies_in_area:
			return
	enemy.remove_speed_modifier(SPEED_KEY)
