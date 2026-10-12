## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge201
extends Challenge
## Challenge: Sample
## Let exactly one enemy of each enemy type of the level pass. The types are the ones spawned by the level waves.


# Private variables
## Enemies that escaped, per enemy type of the level.
var _escaped_by_type: Dictionary[String, int] = {}


# Public functions
## Called when the level starts to reset state.
func start_monitoring() -> void:
	super.start_monitoring()
	_escaped_by_type.clear()
	if not is_instance_valid(ILevel.current_level):
		return

	var level_data: Dictionary = JsonUtil.load_dict("res://resources/levels/%s.json" % ILevel.current_level.level_id)
	for wave: Array in level_data.get("waves", []):
		for step: Dictionary in wave:
			if step.has(WaveStep.ENEMY_ID):
				_escaped_by_type[step[WaveStep.ENEMY_ID]] = 0


## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	if is_failed or _escaped_by_type.is_empty():
		return false

	return _escaped_by_type.values().all(func(count: int) -> bool: return count == 1)


## Notifies the challenge about an enemy reaching the end of its path, a second one of the same type fails it.
func on_enemy_escaped(enemy: IEnemy) -> void:
	if not _escaped_by_type.has(enemy.enemy_id):
		return

	_escaped_by_type[enemy.enemy_id] += 1
	if _escaped_by_type[enemy.enemy_id] > 1:
		fail()
