## © [2026] A7 Studio. All rights reserved. Trademark.

class_name TowerData
extends RefCounted
## Data class representing the progression state of a single tower.

## Whether the tower has been seen in the encyclopedia.
var encyclopedia_seen: bool = false
## Whether the tower is unlocked and available for use.
var unlocked: bool = false

## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"encyclopedia_seen": encyclopedia_seen,
		"unlocked": unlocked
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	unlocked = data.get("unlocked", false)
	encyclopedia_seen = data.get("encyclopedia_seen", false)
