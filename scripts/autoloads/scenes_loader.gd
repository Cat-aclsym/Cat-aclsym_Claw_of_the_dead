## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages loading of game scenes and resources.
extends Node

## The enemy IDs and their associated scenes.
enum EnemyId {
	DEFAULT,
	BIG_DADDY,
	FAT,
}

## The tower IDs and their associated scenes.
enum TowerId {
	TOWER_1,
	TOWER_2,
	TOWER_3,
}

const ENEMIES: Dictionary = {
	EnemyId.DEFAULT: preload("res://scenes/gameplay/entities/enemy/enemies/default_zombie.tscn"),
	EnemyId.BIG_DADDY: preload("res://scenes/gameplay/entities/enemy/enemies/big_daddy.tscn"),
	EnemyId.FAT: preload("res://scenes/gameplay/entities/enemy/enemies/fat.tscn"),
}

const TOWERS: Dictionary = {
	TowerId.TOWER_1: preload("res://scenes/gameplay/entities/tower/towers/first_tower.tscn"),
}

## Returns the enemy scene associated with the given ID
## Returns null if the enemy ID is not found
func get_enemy_scene(id: EnemyId) -> PackedScene:
	if not ENEMIES.has(id):
		Log.trace(Log.Level.ERROR, "{0} try to access unknown enemy with id = {1}".format([name, id]))
		return null
	return ENEMIES[id]
