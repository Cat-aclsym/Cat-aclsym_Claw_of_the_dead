class_name LevelData
extends RefCounted
## Data class representing the progression state of a single level.

## Whether the level is unlocked and playable.
var unlocked: bool = false

## List of challenge IDs that have been completed for this level.
var challenges_completed: Array[String] = []

## Converts the object to a dictionary for serialization.
func to_dictionary() -> Dictionary:
	return {
		"unlocked": unlocked,
		"challenges_completed": challenges_completed
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	unlocked = data.get("unlocked", false)
	challenges_completed.assign(data.get("challenges_completed", []))
