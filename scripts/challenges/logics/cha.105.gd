## © [2024] A7 Studio. All rights reserved. Trademark.

class_name Challenge105
extends Challenge
## Challenge: Trap Master
## Boss must be hit by every trap type (Active, Passive, Limited).


# Constants
const REQUIRED_TYPES: Array[String] = ["active", "passive", "limited"]


# Private variables
var _hit_types: Array[String] = []


# Public functions
## Called when the level starts to reset state.
func start_monitoring() -> void:
	super.start_monitoring()
	_hit_types.clear()


## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	return _hit_types.size() >= REQUIRED_TYPES.size()


## Notifies the challenge about an enemy being hit.
func on_enemy_hit(enemy: IEnemy, source: Variant) -> void:
	if enemy.type != IEnemy.EnemyType.BIG_DADDY:
		return

	# Assuming traps have a 'trap_type' property or we can infer it
	var type: String = ""
	if source.has_method("get_trap_type"):
		type = source.get_trap_type().to_lower()
	elif "trap_type" in source:
		type = source.trap_type.to_lower()

	if type != "" and type in REQUIRED_TYPES:
		if not type in _hit_types:
			_hit_types.append(type)

			if _hit_types.size() >= REQUIRED_TYPES.size():
				complete()
