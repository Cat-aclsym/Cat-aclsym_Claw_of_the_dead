class_name EnemyGroup extends Node


## List of enemies to spawn
@export var enemies: Array[ScenesLoader.EnemyID] = []

## Delay in second between enemies spawn
@export_range(0.1, 10.0) var in_delay: float = 0.1

## Delay in second before next group
@export_range(0.1, 10.0) var out_delay: float = 0.1

## Modifiers applies to all enemies in group [br]
## e.g : [code]{"damage": +15}[/code]
## @experimental
@export var modifiers: Dictionary = {} # TODO

func serialize() -> Dictionary:
	var enemies_data = [] # Crée un tableau vide pour stocker les données des ennemis

	for child in get_children(): # Suppose une fonction qui retourne tous les ennemis
		var enemy_data = { # Sérialise les propriétés de chaque ennemi
			"type": child.get_class(),
			"speed": child.speed,
			"max_health": child.max_health,
			"health": child.health,
			"path": child.path,
			"state": child.state,
			"current_animation": child.AnimPlayer.current_animation,
			"position": {"x": child.global_position.x, "y": child.global_position.y},
			# Ajoutez d'autres propriétés si nécessaire
		}
		enemies_data.append(enemy_data)
	return {
		"enemies" : enemies_data,
		
		
		
		
	}
