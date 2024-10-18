## © [2024] A7 Studio. All rights reserved. Trademark.
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
	EnemyID.DEFAULT: preload("res://scenes/gameplay/entities/enemy/enemies/default_zombie.tscn"),
	EnemyID.BIG_DADDY: preload("res://scenes/gameplay/entities/enemy/enemies/big_daddy.tscn"),
	EnemyID.FAT: preload("res://scenes/gameplay/entities/enemy/enemies/fat.tscn"),
}


const TOWERS: Dictionary = {
	TOWER_1 = preload("res://scenes/gameplay/entities/tower/towers/first_tower.tscn")
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
