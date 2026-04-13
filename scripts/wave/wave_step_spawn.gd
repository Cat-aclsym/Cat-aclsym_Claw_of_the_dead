## © [2026] A7 Studio. All rights reserved. Trademark.

class_name WaveStepSpawn
extends WaveStep
## A wave step that spawns a number of enemies of a specific type.


# core
func _init(in_data: Dictionary) -> void:
	super._init(WaveStep.Order.SPAWN, in_data)


# public
## Executes the spawn logic, instantiating an enemy and placing it on a path.
func exec() -> void:
	var enemy_id: String = _data[WaveStep.ENEMY_ID]
	var spawner_index: int = _data[WaveStep.SPAWNER]
	var level: ILevel = ILevel.current_level

	if not is_instance_valid(level):
		Log.trace(Log.Level.ERROR, "Cannot spawn enemies without an active level.")
		return

	if not is_instance_valid(level.map):
		Log.trace(Log.Level.ERROR, "Cannot spawn enemies without a valid map.")
		return

	if not ScenesLoader.enemies_scene.has(enemy_id):
		var enemy_scene_path: String = "res://scenes/gameplay/entities/enemy/enemies/%s.tscn" % enemy_id
		ScenesLoader.enemies_scene[enemy_id] = load(enemy_scene_path)

	var enemy_scene: PackedScene = ScenesLoader.enemies_scene[enemy_id]
	if enemy_scene == null:
		Log.trace(Log.Level.ERROR, "Failed to load enemy scene: %s" % enemy_id)
		return

	var enemy: IEnemy = enemy_scene.instantiate()
	if not enemy.enemy_id.is_empty():
		ProgressionManager.mark_enemy_seen(enemy.enemy_id)

	var spawn_path: Path2D = _resolve_spawn_path(level.map, spawner_index)
	if spawn_path == null:
		Log.trace(Log.Level.ERROR, "No valid path available for spawning.")
		return

	EnemySpawner.spawn_enemy(spawn_path, enemy)
	_data[WaveStep.COUNT] -= 1


## Returns true when every enemy from this step has spawned.
func is_over() -> bool:
	return _data[WaveStep.COUNT] == 0


func _resolve_spawn_path(map: IMap, spawner_index: int) -> Path2D:
	if map.paths.is_empty():
		return null

	if spawner_index == -1:
		return map.paths[randi() % map.paths.size()]

	if spawner_index >= 0 and spawner_index < map.paths.size():
		return map.paths[spawner_index]

	Log.trace(Log.Level.WARN, "Invalid spawner index %d, using random path." % spawner_index)
	return map.paths[randi() % map.paths.size()]
