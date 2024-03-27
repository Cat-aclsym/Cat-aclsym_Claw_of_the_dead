extends Node

enum EnemyID {
	DEFAULT,
	ENEMY_1,
	BIG_DADDY,
}

var enemies: Dictionary = {
	EnemyID.ENEMY_1: preload("res://scenes/enemy/ienemy_scene.tscn"),
	EnemyID.BIG_DADDY: preload("res://scenes/enemy/big_daddy.tscn"),
}


func get_enemy_scene(id: EnemyID) -> PackedScene:
	if (!enemies.has(id)):
		Log.error("{0} try to access unknown enemy with id = {1}".format([name, id]))
		return null
		
	return enemies[id]
