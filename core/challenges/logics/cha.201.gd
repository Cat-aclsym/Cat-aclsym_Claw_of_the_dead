## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge201
extends Challenge
## Challenge: Sample
## Let exactly one enemy of each enemy type of the level pass. The types are the ones spawned by the level waves.


# Private variables
## Enemies that escaped, per enemy type of the level.
var _escaped_by_type: Dictionary[String, int] = {}


# Public functions
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


## Called when the level starts to reset state.
func start_monitoring() -> void:
	super.start_monitoring()
	_escaped_by_type.clear()
	if not is_instance_valid(ILevel.current_level):
		return

	for wave: Wave in ILevel.current_level.waves:
		for step: WaveStep in wave.steps:
			if step is WaveStepSpawn:
				_escaped_by_type[step.data()[WaveStep.ENEMY_ID]] = 0
