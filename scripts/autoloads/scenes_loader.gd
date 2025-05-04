## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages loading of game scenes and resources.
extends Node

const END_GAME_MENU: PackedScene = preload("res://scenes/ui/menus/end_game/end_game.tscn")

const ENEMIES: Dictionary = {
	IEnemy.EnemyType.DEFAULT: preload("res://scenes/gameplay/entities/enemy/enemies/ene.01.tscn"),
	IEnemy.EnemyType.BIG_DADDY: preload("res://scenes/gameplay/entities/enemy/enemies/big_daddy.tscn"),
	IEnemy.EnemyType.FAT: preload("res://scenes/gameplay/entities/enemy/enemies/ene.02.tscn"),
  	IEnemy.EnemyType.RAT: preload("res://scenes/gameplay/entities/enemy/enemies/ene.03.tscn"),
}

var enemies_scene: Dictionary = {}

const TOWERS: Dictionary = {
	ITower.TowerType.TOWER_1: preload("res://scenes/gameplay/entities/tower/towers/bat_01.tscn"),
}

## Returns the enemy scene associated with the given ID
## Returns null if the enemy ID is not found
func get_enemy_scene(id: IEnemy.EnemyType) -> PackedScene:
	if not ENEMIES.has(id):
		Log.trace(Log.Level.ERROR, "{0} try to access unknown enemy with id = {1}".format([name, id]))
		return null
	return ENEMIES[id]
