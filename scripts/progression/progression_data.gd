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

## Dictionary mapping trap IDs (String) to TrapData objects.
var traps: Dictionary = {}

## Armurerie: IDs of purchased meta nodes (see [code]resources/armory/armory.json[/code]).
var armory_purchased: Array[String] = []

## When true (migrated old saves), all buildings stay buildable regardless of armory unlocks.
var armory_legacy_mode: bool = false


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

	res["traps"] = {}
	for trap_id in traps:
		res["traps"][trap_id] = traps[trap_id].save()

	res["armory_purchased"] = armory_purchased.duplicate()
	res["armory_legacy_mode"] = armory_legacy_mode

	return res
