## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A trap that slows down enemies while they are on it.
class_name Bat04
extends ITrap

const _SLOW_BASE_SPEED_KEY: StringName = &"bat_04_slow_base_speed"
const _SLOW_STACK_KEY: StringName = &"bat_04_slow_stack_count"

## The slow effect percentage (0.5 = 50% slower)
@export var slow_amount: float = 0.75

func _ready() -> void:
	super()

func apply_effect(enemy: IEnemy) -> void:
	var slow_stack_count: int = int(enemy.get_meta(_SLOW_STACK_KEY, 0))
	if slow_stack_count == 0:
		enemy.set_meta(_SLOW_BASE_SPEED_KEY, enemy.speed)
		enemy.speed *= (1.0 - slow_amount)
		enemy.push_slow_visual()
	enemy.set_meta(_SLOW_STACK_KEY, slow_stack_count + 1)

func remove_effect(enemy: IEnemy) -> void:
	var slow_stack_count: int = int(enemy.get_meta(_SLOW_STACK_KEY, 0))
	if slow_stack_count <= 0:
		return

	slow_stack_count -= 1
	if slow_stack_count == 0:
		var base_speed: float = float(enemy.get_meta(_SLOW_BASE_SPEED_KEY, enemy.speed))
		enemy.speed = base_speed
		enemy.remove_meta(_SLOW_BASE_SPEED_KEY)
		enemy.pop_slow_visual()
		enemy.remove_meta(_SLOW_STACK_KEY)
	else:
		enemy.set_meta(_SLOW_STACK_KEY, slow_stack_count)

func _apply_trap_stats_extension(_base: Dictionary) -> void:
	if _base.has("slow_amount"):
		slow_amount = float(_base["slow_amount"])
