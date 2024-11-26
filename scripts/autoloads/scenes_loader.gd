## © [2024] A7 Studio. All rights reserved. Trademark.
## File: autoloads/scenes_loader.gd
## Manages loading of game scenes and resources.
extends Node

enum ENEMY_ID {
	DEFAULT,
	BIG_DADDY,
	FAT,
}

enum TOWER_ID {
	TOWER_1,
	TOWER_2,
	TOWER_3,
}

const ENEMIES: Dictionary = {
	ENEMY_ID.DEFAULT: preload("res://scenes/gameplay/entities/enemy/enemies/default_zombie.tscn"),
	ENEMY_ID.BIG_DADDY: preload("res://scenes/gameplay/entities/enemy/enemies/big_daddy.tscn"),
	ENEMY_ID.FAT: preload("res://scenes/gameplay/entities/enemy/enemies/fat.tscn"),
}

const TOWERS: Dictionary = {
	TOWER_ID.TOWER_1: preload("res://scenes/gameplay/entities/tower/towers/first_tower.tscn"),
}

# Public Functions
## Returns the enemy scene associated with the given ID
## Returns null if the enemy ID is not found
func get_enemy_scene(id: ENEMY_ID) -> PackedScene:
	if not ENEMIES.has(id):
		Log.trace(Log.Level.ERROR, "{0} try to access unknown enemy with id = {1}".format([name, id]))
		return null
	return ENEMIES[id]
