## © [2026] A7 Studio. All rights reserved. Trademark.

class_name WaveStepSpawn
extends WaveStep


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
	enemy.die.connect(level._on_enemy_die)

	# Use active paths for dynamic spawning.
	var map: IMap = level.map
	var spawn_path: Path2D = null

	if spawner_index == -1:
		# -1 means use a random active path.
		spawn_path = map.get_random_active_path()
	elif spawner_index >= 0 and spawner_index < map.active_paths.size():
		# Use a specific active path index.
		spawn_path = map.active_paths[spawner_index]
	else:
		# Fallback to a random active path if the index is out of bounds.
		spawn_path = map.get_random_active_path()

	if spawn_path == null:
		Log.trace(Log.Level.ERROR, "No valid path available for spawning!")
		return

	EnemySpawner.spawn_enemy(spawn_path, enemy)
	level._on_enemy_spawn() # ILevel owns the WaveStep lifecycle.
	_data[WaveStep.COUNT] -= 1


## Returns true when every enemy from this step has spawned.
func is_over() -> bool:
	return _data[WaveStep.COUNT] == 0
