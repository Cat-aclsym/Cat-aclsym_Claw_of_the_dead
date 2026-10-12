## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A utility class for spawning enemies in the game world.
## [br]
## This class handles the creation and setup of enemy instances along a specified path.
## @tutorial: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
class_name EnemySpawner
extends Node2D

## Maximum lateral spawn deviation expressed in tile fractions.
const SPAWN_OFFSET_MAX_TILES := 0.2

## Number of enemies spawned so far, used to name the next one.
static var _spawned: int = 0

## Spawns a new enemy instance and sets up its path following behavior.
## [br]
## [param path] The path that the enemy should follow
## [param enemy] The enemy instance to spawn
static func spawn_enemy(path: Path2D, enemy: IEnemy) -> void:
	var pathfollow := PathFollow2D.new()
	pathfollow.loop = false
	pathfollow.rotates = false

	path.add_child(pathfollow)
	var spawn_offset_distance := _get_spawn_offset_distance(path)
	pathfollow.v_offset = randf_range(-spawn_offset_distance, spawn_offset_distance)

	enemy.name = "ENEMY_%d" % _spawned
	_spawned += 1
	enemy.path = path
	enemy.path_follow = pathfollow

	if ILevel.current_level:
		SignalUtil.connects([{SignalUtil.WHO: enemy, SignalUtil.WHAT: "die", SignalUtil.TO: ILevel.current_level._on_enemy_die}])
		ILevel.current_level._on_enemy_spawn()

	pathfollow.add_child(enemy)


static func _get_spawn_offset_distance(path: Path2D) -> float:
	var map: IMap = _get_map(path)
	var tile_step_distance: float = map.get_tile_step_distance() if map else IMap.DEFAULT_TILE_STEP_DISTANCE
	return tile_step_distance * SPAWN_OFFSET_MAX_TILES


static func _get_map(path: Path2D) -> IMap:
	var current: Node = path.get_parent()
	while current:
		if current is IMap:
			return current as IMap
		current = current.get_parent()

	return null
