## © [2026] A7 Studio. All rights reserved. Trademark.

class_name TrapData
extends RefCounted
## Data class representing the progression state of a single trap (build menu unlock).

## Whether the trap is unlocked and available in the construction menu.
var unlocked: bool = false

## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"unlocked": unlocked
	}

## Populates the object from a dictionary.
## [param d] Serialized trap progression fields.
func from_dictionary(d: Dictionary) -> void:
	unlocked = d.get("unlocked", false)
