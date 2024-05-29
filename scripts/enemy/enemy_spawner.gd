class_name IEnemySpawner
extends Node2D

## Static variable used for naming enemies uniquely.
## @property static int i - Counter for unique enemy naming.
static var i: int = 0:
	get:
		i += 1
		return i - 1

## Spawns an enemy at the given path.
## @param Path2D path - The path on which the enemy will be spawned.
## @param IEnemy enemy - The enemy instance to be spawned.
static func spawn_enemy(path: Path2D, enemy: IEnemy):
	## Create a new PathFollow2D node.
	var pathfollow := PathFollow2D.new()
	pathfollow.loop = false
	pathfollow.rotates = false

	## Add the PathFollow2D node to the path.
	path.add_child(pathfollow)

	## Set a unique name for the enemy.
	enemy.name = "ENEMY_{0}".format([i])

	## Assign the path and path_follow properties to the enemy.
	enemy.path = path
	enemy.path_follow = pathfollow

	## Add the enemy as a child to the PathFollow2D node.
	pathfollow.add_child(enemy)

	## Fix for the same animation on multiple instances.
	enemy.Sprite.texture = enemy.Sprite.texture.duplicate()
