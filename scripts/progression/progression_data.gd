## © [2026] A7 Studio. All rights reserved. Trademark.

class_name ProgressionData
extends RefCounted
## Root data class for the entire game progression and settings.

# Public variables
## Dictionary mapping enemy IDs (String) to EnemyData objects.
var enemies: Dictionary = {}

## Dictionary mapping level IDs (String) to LevelData objects.
var levels: Dictionary = {}

## Game settings.
var parameters: SettingsData = SettingsData.new()

## Dictionary mapping tower IDs (String) to TowerData objects.
var towers: Dictionary = {}


# Public functions
## Converts the entire progression to a dictionary for serialization or debugging.
func save() -> Dictionary:
	var res: Dictionary = {}

	res["enemies"] = {}
	for id in enemies:
		res["enemies"][id] = enemies[id].save()

	res["levels"] = {}
	for id in levels:
		res["levels"][id] = levels[id].save()

	res["parameters"] = parameters.save()

	res["towers"] = {}
	for id in towers:
		res["towers"][id] = towers[id].save()

	return res
