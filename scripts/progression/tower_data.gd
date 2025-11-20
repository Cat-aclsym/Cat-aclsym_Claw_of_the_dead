class_name TowerData
extends RefCounted
## Data class representing the progression state of a single tower.

## Whether the tower is unlocked and available for use.
var unlocked: bool = false

## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"unlocked": unlocked
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	unlocked = data.get("unlocked", false)
