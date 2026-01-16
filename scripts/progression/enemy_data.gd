## © [2026] A7 Studio. All rights reserved. Trademark.

class_name EnemyData
extends RefCounted
## Data class representing the progression state of a single enemy.

## Whether the enemy has been seen by the player.
var seen: bool = false

## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"seen": seen
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	seen = data.get("seen", false)
