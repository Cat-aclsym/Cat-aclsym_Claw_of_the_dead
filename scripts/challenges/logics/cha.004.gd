## © [2024] A7 Studio. All rights reserved. Trademark.

extends Challenge
## Challenge: Kill 10 enemies with fire.

var _fire_kills: int = 0
const TARGET_KILLS: int = 10

func start_monitoring() -> void:
	super.start_monitoring()
	_fire_kills = 0

func on_enemy_died(_enemy: IEnemy, damage_type: IEnemy.DamageType) -> void:
	if damage_type == IEnemy.DamageType.FIRE:
		_fire_kills += 1
		if _fire_kills >= TARGET_KILLS:
			complete()

func check_completion() -> bool:
	return _fire_kills >= TARGET_KILLS
