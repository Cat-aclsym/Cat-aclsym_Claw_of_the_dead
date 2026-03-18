## © [2024] A7 Studio. All rights reserved. Trademark.

class_name Challenge004
extends Challenge
## Challenge: Pyromaniac
## Kill 10 enemies with fire.


# Constants
const TARGET_KILLS: int = 10


# Private variables
var _fire_kills: int = 0


# Public functions
## Called when the level starts to reset state.
func start_monitoring() -> void:
	super.start_monitoring()
	_fire_kills = 0


## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	return _fire_kills >= TARGET_KILLS


## Notifies the challenge about an enemy death.
func on_enemy_died(_enemy: IEnemy, damage_type: IEnemy.DamageType, _source: Variant = null) -> void:
	if damage_type == IEnemy.DamageType.FIRE:
		_fire_kills += 1
		if _fire_kills >= TARGET_KILLS:
			complete()
