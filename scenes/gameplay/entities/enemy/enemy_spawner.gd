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

## Counter to track the number of enemy instances created
static var _instance_count: int = 0:
	get:
		_instance_count += 1
		return _instance_count - 1

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

	enemy.name = "ENEMY_{0}".format([_instance_count])
	enemy.path = path
	enemy.path_follow = pathfollow

	if ILevel.current_level:
		enemy.connect("die", ILevel.current_level._on_enemy_die)
		ILevel.current_level._on_enemy_spawn()

	pathfollow.add_child(enemy)


static func _get_spawn_offset_distance(path: Path2D) -> float:
	var map := _get_map(path)
	if map and map.tilemap:
		var origin := map.tilemap.map_to_local(Vector2i.ZERO)
		var neighbor := map.tilemap.map_to_local(Vector2i(1, 0))
		var tile_step_distance := origin.distance_to(neighbor)
		if tile_step_distance > 0.0:
			return tile_step_distance * SPAWN_OFFSET_MAX_TILES

	return 32.0 * SPAWN_OFFSET_MAX_TILES


static func _get_map(path: Path2D) -> IMap:
	var current: Node = path.get_parent()
	while current:
		if current is IMap:
			return current as IMap
		current = current.get_parent()

	return null
