## © [2026] A7 Studio. All rights reserved. Trademark.

class_name WaveStepSpawn
extends WaveStep
## A wave step that spawns a number of enemies of a specific type.

const ENEMY_SCENE_PATH_FORMAT: String = "res://scenes/gameplay/entities/enemy/enemies/%s.tscn"


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

	var enemy_scene: PackedScene = _resolve_enemy_scene(enemy_id)
	if enemy_scene == null:
		return

	var enemy: IEnemy = enemy_scene.instantiate()
	if not enemy.enemy_id.is_empty():
		ProgressionManager.mark_enemy_seen(enemy.enemy_id)

	var spawn_path: Path2D = _resolve_spawn_path(level.map, spawner_index)
	if spawn_path == null:
		Log.trace(Log.Level.ERROR, "No valid active path available for spawning.")
		return

	EnemySpawner.spawn_enemy(spawn_path, enemy)
	_data[WaveStep.COUNT] -= 1


## Returns true when every enemy from this step has spawned.
func is_over() -> bool:
	return _data[WaveStep.COUNT] == 0


func _resolve_spawn_path(map: IMap, spawner_index: int) -> Path2D:
	var spawn_paths: Array[Path2D] = map.get_spawn_paths()
	if spawn_paths.is_empty():
		Log.trace(Log.Level.ERROR, "Cannot spawn enemy: map has no active paths.")
		return null

	if spawner_index == -1:
		return map.get_random_active_path()

	if spawner_index >= 0 and spawner_index < map.paths.size():
		if not map.is_path_active(spawner_index):
			Log.trace(Log.Level.ERROR, "Spawner index %d points to an inactive path." % spawner_index)
			return null
		return map.paths[spawner_index]

	Log.trace(Log.Level.WARN, "Invalid spawner index %d, using random active path." % spawner_index)
	return map.get_random_active_path()


func _resolve_enemy_scene(enemy_id: String) -> PackedScene:
	var enemy_scene_path: String = ENEMY_SCENE_PATH_FORMAT % enemy_id

	if ScenesLoader.enemies_scene.has(enemy_id):
		var cached_scene: PackedScene = ScenesLoader.enemies_scene[enemy_id]
		if cached_scene != null:
			return cached_scene

		ScenesLoader.enemies_scene.erase(enemy_id)

	var loaded_scene: PackedScene = load(enemy_scene_path) as PackedScene
	if loaded_scene == null:
		Log.trace(Log.Level.ERROR, "Failed to load enemy scene from path: %s" % enemy_scene_path)
		return null

	ScenesLoader.enemies_scene[enemy_id] = loaded_scene
	return loaded_scene
