## © [2026] A7 Studio. All rights reserved. Trademark.

class_name SettingsData
extends RefCounted
## Data class representing the game settings/parameters.

## The selected language code (e.g., "en", "fr").
var language: String = "fr"
## Whether music is enabled.
var music_enabled: bool = true
## Whether sound effects are enabled.
var sound_enabled: bool = true
## Whether the armory intro dialogue has been seen.
var armory_intro_seen: bool = false
## Whether the first-play tutorial is completed.
var tutorial_completed: bool = false

## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"armory_intro_seen": armory_intro_seen,
		"language": language,
		"music_enabled": music_enabled,
		"sound_enabled": sound_enabled,
		"tutorial_completed": tutorial_completed
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	armory_intro_seen = data.get("armory_intro_seen", false)
	language = data.get("language", "fr")
	music_enabled = data.get("music_enabled", true)
	sound_enabled = data.get("sound_enabled", true)
	tutorial_completed = data.get("tutorial_completed", false)
