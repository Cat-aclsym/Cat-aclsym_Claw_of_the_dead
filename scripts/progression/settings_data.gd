class_name SettingsData
extends RefCounted
## Data class representing the game settings/parameters.

## Whether sound effects are enabled.
var sound_enabled: bool = true

## Whether music is enabled.
var music_enabled: bool = true

## The selected language code (e.g., "en", "fr").
var language: String = "fr"

## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"sound_enabled": sound_enabled,
		"music_enabled": music_enabled,
		"language": language
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	sound_enabled = data.get("sound_enabled", true)
	music_enabled = data.get("music_enabled", true)
	language = data.get("language", "fr")
