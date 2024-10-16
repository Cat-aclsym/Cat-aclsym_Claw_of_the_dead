extends Node

enum EnemyID {
	DEFAULT,
	BIG_DADDY,
	FAT,
}

# modify with correct tower name
enum TowerID {
	TOWER_1,
	TOWER_2,
	TOWER_3,
}


const ENEMIES: Dictionary = {
	EnemyID.DEFAULT: preload("res://scenes/enemy/default_zombie.tscn"),
	EnemyID.BIG_DADDY: preload("res://scenes/enemy/big_daddy.tscn"),
	EnemyID.FAT: preload("res://scenes/enemy/fat.tscn"),
}


const TOWERS: Dictionary = {
	TOWER_1 = preload("res://scenes/tower/first_tower.tscn")
}


# core


# public
func get_enemy_scene(id: EnemyID) -> PackedScene:
	if not ENEMIES.has(id):
		Log.trace(Log.Level.ERROR, "{0} try to access unknown enemy with id = {1}".format([name, id]))
		return null

	return ENEMIES[id]

# private


# signal


# event


# setget
