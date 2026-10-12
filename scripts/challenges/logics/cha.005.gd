## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge005
extends Challenge
## Challenge: One Tower One Kill
## Every tower placed must kill at least one enemy. A tower that was sold is not required to have killed.


# Private variables
## Kills of each placed tower, keyed by instance id.
var _kills_by_tower: Dictionary[int, int] = {}


# Public functions
## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	if is_failed:
		return false

	for tower_id: int in _kills_by_tower:
		if _kills_by_tower[tower_id] == 0 and is_instance_id_valid(tower_id):
			return false
	return true


## Notifies the challenge about an enemy death, the killing tower gets the kill.
func on_enemy_died(_enemy: IEnemy, _damage_type: IEnemy.DamageType, source: Variant) -> void:
	if not is_instance_valid(source) or not source is ITower:
		return

	var tower_id: int = (source as ITower).get_instance_id()
	if _kills_by_tower.has(tower_id):
		_kills_by_tower[tower_id] += 1


## Notifies the challenge about a tower placement.
func on_tower_placed(tower: ITower) -> void:
	_kills_by_tower[tower.get_instance_id()] = 0


## Called when the level starts to reset state.
func start_monitoring() -> void:
	super.start_monitoring()
	_kills_by_tower.clear()
