## © [2026] A7 Studio. All rights reserved. Trademark.

class_name LevelData
extends RefCounted
## Data class representing the progression state of a single level.

# Public variables
## List of challenge IDs that have been completed for this level.
var challenges_completed: Array[String] = []
## Whether the level is unlocked and playable.
var unlocked: bool = false

# Public functions
## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"challenges_completed": challenges_completed,
		"unlocked": unlocked
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	challenges_completed.assign(data.get("challenges_completed", []))
	unlocked = data.get("unlocked", false)
