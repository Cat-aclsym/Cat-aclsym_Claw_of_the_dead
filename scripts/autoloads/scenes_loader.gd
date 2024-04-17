extends Node

enum EnemyID {
	DEFAULT,
	ENEMY_1,
	BIG_DADDY,
}

# modify with correct tower name
enum TowerID {
	TOWER_1,
	TOWER_2,
	TOWER_3,
}


var enemies: Dictionary = {
	EnemyID.ENEMY_1: preload("res://scenes/enemy/ienemy_scene.tscn"),
	EnemyID.BIG_DADDY: preload("res://scenes/enemy/big_daddy.tscn"),
}


var towers: Dictionary = {
	TOWER_1 = preload("res://scenes/tower/first_tower.tscn")
}


func get_enemy_scene(id: EnemyID) -> PackedScene:
	if (!enemies.has(id)):
		Log.error("{0} try to access unknown enemy with id = {1}".format([name, id]))
		return null
		
	return enemies[id]
