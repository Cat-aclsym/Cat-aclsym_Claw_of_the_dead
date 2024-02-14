class_name EnemyFactory 
extends Node2D
	
static func spawn_enemy(path: Path2D, enemy: IEnemy):
	var pathfollow := PathFollow2D.new()
	pathfollow.loop = false
	pathfollow.rotates = false
	path.add_child(pathfollow)
	
	enemy.path = pathfollow
	
	pathfollow.add_child(enemy)
