class_name ProgressionData
extends RefCounted
## Root data class for the entire game progression and settings.

## Dictionary mapping level IDs (String) to LevelData objects.
var levels: Dictionary = {}

## Game settings.
var parameters: SettingsData = SettingsData.new()

## Dictionary mapping tower IDs (String) to TowerData objects.
var towers: Dictionary = {}

## Converts the object to a dictionary for serialization.
func to_dictionary() -> Dictionary:
	var levels_dict: Dictionary = {}
	for id in levels:
		levels_dict[id] = levels[id].to_dictionary()

	var towers_dict: Dictionary = {}
	for id in towers:
		towers_dict[id] = towers[id].to_dictionary()

	return {
		"levels": levels_dict,
		"parameters": parameters.to_dictionary(),
		"towers": towers_dict
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	# Load Levels
	levels.clear()
	var levels_data = data.get("levels", {})
	for id in levels_data:
		var level_obj = LevelData.new()
		level_obj.from_dictionary(levels_data[id])
		levels[id] = level_obj

	# Load Parameters
	parameters.from_dictionary(data.get("parameters", {}))

	# Load Towers
	towers.clear()
	var towers_data = data.get("towers", {})
	for id in towers_data:
		var tower_obj = TowerData.new()
		tower_obj.from_dictionary(towers_data[id])
		towers[id] = tower_obj
