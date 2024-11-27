## © [2024] A7 Studio. All rights reserved. Trademark.
##
## A utility class for spawning enemies in the game world.
## [br]
## This class handles the creation and setup of enemy instances along a specified path.
## @tutorial: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
class_name EnemySpawner
extends Node2D

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

	enemy.name = "ENEMY_{0}".format([_instance_count])
	enemy.path = path
	enemy.path_follow = pathfollow

	pathfollow.add_child(enemy)

	# Fix same animation on multiple instances:
	enemy.sprite.texture = enemy.sprite.texture.duplicate()
