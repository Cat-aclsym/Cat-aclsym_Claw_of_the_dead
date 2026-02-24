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
	var level = ILevel.current_level
	enemy.connect("die", level._on_enemy_die)
	EnemySpawner.spawn_enemy(level.map.paths[spawner_index], enemy)
	level._on_enemy_spawn() # ! ILevel owns and contains WaveStep class, see it as a friend class
	_data[WaveStep.COUNT] -= 1


func is_over() -> bool:
	return _data[WaveStep.COUNT] == 0


# private


# signal


# event


# setget
