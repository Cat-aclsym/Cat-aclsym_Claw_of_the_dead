## © [2024] A7 Studio. All rights reserved. Trademark.
class_name EnemySpawner
extends Node2D

static var _instance_count: int = 0:
	get:
		_instance_count += 1
		return _instance_count - 1


# core


# public
static func spawn_enemy(path: Path2D, enemy: IEnemy):
	var pathfollow := PathFollow2D.new()
	pathfollow.loop = false
	pathfollow.rotates = false

	path.add_child(pathfollow)

	enemy.name = "ENEMY_{0}".format([_instance_count])
	enemy.path = path
	enemy.path_follow = pathfollow

	pathfollow.add_child(enemy)

	# fix same animation on multiple instance :
	enemy.sprite.texture = enemy.sprite.texture.duplicate()


# private


# signal


# event


# setget
