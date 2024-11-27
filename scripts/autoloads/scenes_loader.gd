## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages loading of game scenes and resources.
extends Node

const ENEMIES: Dictionary = {
	IEnemy.EnemyType.DEFAULT: preload("res://scenes/gameplay/entities/enemy/enemies/default_zombie.tscn"),
	IEnemy.EnemyType.BIG_DADDY: preload("res://scenes/gameplay/entities/enemy/enemies/big_daddy.tscn"),
	IEnemy.EnemyType.FAT: preload("res://scenes/gameplay/entities/enemy/enemies/fat.tscn"),
}

const TOWERS: Dictionary = {
	ITower.TowerType.TOWER_1: preload("res://scenes/gameplay/entities/tower/towers/first_tower.tscn"),
}

## Returns the enemy scene associated with the given ID
## Returns null if the enemy ID is not found
func get_enemy_scene(id: IEnemy.EnemyType) -> PackedScene:
	if not ENEMIES.has(id):
		Log.trace(Log.Level.ERROR, "{0} try to access unknown enemy with id = {1}".format([name, id]))
		return null
	return ENEMIES[id]
