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

## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"language": language,
		"music_enabled": music_enabled,
		"sound_enabled": sound_enabled
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	language = data.get("language", "fr")
	music_enabled = data.get("music_enabled", true)
	sound_enabled = data.get("sound_enabled", true)
