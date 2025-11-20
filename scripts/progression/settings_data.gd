class_name SettingsData
extends RefCounted
## Data class representing the game settings/parameters.

## Whether sound effects are enabled.
var sound_volume: bool = true

## Whether music is enabled.
var music_volume: bool = true

## The selected language code (e.g., "en", "fr").
var language: String = "fr"

## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"sound_volume": sound_volume,
		"music_volume": music_volume,
		"language": language
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	sound_volume = data.get("sound_volume", true)
	music_volume = data.get("music_volume", true)
	language = data.get("language", "fr")
