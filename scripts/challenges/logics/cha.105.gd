## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge105
extends Challenge
## Challenge: Trap Master
## Boss must be hit by every trap type (passive and limited).


# Constants
const REQUIRED_TYPES: Array[String] = ["passive", "limited"]


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
	if not source is ITrap:
		return
	var type: String = (source as ITrap).get_trap_type()
	if type == "" or type not in REQUIRED_TYPES:
		return
	if type in _hit_types:
		return
	_hit_types.append(type)
	if _hit_types.size() >= REQUIRED_TYPES.size():
		complete()
