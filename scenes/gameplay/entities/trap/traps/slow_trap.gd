## © [2024] A7 Studio. All rights reserved. Trademark.
##
## A trap that slows down enemies while they are on it.
class_name SlowTrap
extends ITrap

## The slow effect percentage (0.5 = 50% slower)
@export var slow_amount: float = 0.9

## Dictionary to store original speeds
var original_speeds: Dictionary = {}

func _ready() -> void:
    super()

func apply_effect(enemy: IEnemy) -> void:
    if not enemy in original_speeds:
        original_speeds[enemy] = enemy.speed
        enemy.speed *= (1.0 - slow_amount)

func remove_effect(enemy: IEnemy) -> void:
    if enemy in original_speeds:
        enemy.speed = original_speeds[enemy]
        original_speeds.erase(enemy)