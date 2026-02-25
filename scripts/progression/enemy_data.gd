## © [2026] A7 Studio. All rights reserved. Trademark.

class_name EnemyData
extends RefCounted
## Data class representing the progression state of a single enemy.

## Whether the enemy has been seen in the encyclopedia.
var encyclopedia_seen: bool = false
## Whether the enemy has been seen by the player.
var seen: bool = false

## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"encyclopedia_seen": encyclopedia_seen,
		"seen": seen
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	seen = data.get("seen", false)
	encyclopedia_seen = data.get("encyclopedia_seen", false)
