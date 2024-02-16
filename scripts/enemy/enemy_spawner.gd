class_name IEnemySpawner
extends Node2D

static var i: int = 0:
	get:
		i += 1
		return i - 1
	
static func spawn_enemy(path: Path2D, enemy: IEnemy):
	var pathfollow := PathFollow2D.new()
	pathfollow.loop = false
	pathfollow.rotates = false
	
	path.add_child(pathfollow)

	enemy.name = "ENEMY_{0}".format([i])
	enemy.path = path
	enemy.path_follow = pathfollow

	pathfollow.add_child(enemy)
	
	# fix same animation on multiple instance :
	enemy.Sprite.texture = enemy.Sprite.texture.duplicate()
