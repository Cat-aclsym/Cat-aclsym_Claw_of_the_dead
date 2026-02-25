class_name WaveStepSpawn extends WaveStep


# core
func _init(in_data: Dictionary) -> void:
	super._init(WaveStep.Order.SPAWN, in_data)


# public
func exec() -> void:
	var enemy_id: String = _data[WaveStep.ENEMY_ID]
	var spawner_index: int = _data[WaveStep.SPAWNER]

	if not ScenesLoader.enemies_scene.has(enemy_id):
		ScenesLoader.enemies_scene[enemy_id] = load("res://scenes/gameplay/entities/enemy/enemies/%s.tscn" % enemy_id)

	var enemy: IEnemy = ScenesLoader.enemies_scene[enemy_id].instantiate()
	enemy.connect("die", ILevel.current_level._on_enemy_die)

	# Use active paths for dynamic spawning
	var map: IMap = ILevel.current_level.map
	var spawn_path: Path2D = null

	if spawner_index == -1:
		# -1 means use random active path
		spawn_path = map.get_random_active_path()
	elif spawner_index >= 0 and spawner_index < map.active_paths.size():
		# Use specific active path index
		spawn_path = map.active_paths[spawner_index]
	else:
		# Fallback: use random active path if index is out of bounds
		spawn_path = map.get_random_active_path()

	if spawn_path == null:
		Log.trace(Log.Level.ERROR, "No valid path available for spawning!")
		return

	EnemySpawner.spawn_enemy(spawn_path, enemy)
	ILevel.current_level._on_enemy_spawn() # ! ILevel owns and contains WaveStep class, see it as a friend class
	_data[WaveStep.COUNT] -= 1


func is_over() -> bool:
	return _data[WaveStep.COUNT] == 0


# private


# signal


# event


# setget
