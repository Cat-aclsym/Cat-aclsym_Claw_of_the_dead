## © [2024] A7 Studio. All rights reserved. Trademark.
##
## A trap that slows down enemies.
class_name SlowTrap
extends ITrap

## The slow effect percentage (0.5 = 50% slower)
@export var slow_amount: float = 0.9

func apply_effect(enemy: IEnemy) -> void:
    enemy.speed *= (1.0 - slow_amount)

func remove_effect(enemy: IEnemy) -> void:
    enemy.speed /= (1.0 - slow_amount) 