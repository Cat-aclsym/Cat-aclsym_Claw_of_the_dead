class_name IEnemySpawner
extends Node2D
	
static func spawn_enemy(path: Path2D, enemy: IEnemy):
	var pathfollow := PathFollow2D.new()
	pathfollow.loop = false
	pathfollow.rotates = false
	path.add_child(pathfollow)

	enemy.path = pathfollow

	pathfollow.add_child(enemy)

func serialize() -> Dictionary:
	return {
		"type": "IEnemySpawner",
		"position": {"x": global_position.x, "y": global_position.y}, # sauvegarder la position si nécessaire
		# Ajoutez d'autres propriétés si nécessaire
	}
