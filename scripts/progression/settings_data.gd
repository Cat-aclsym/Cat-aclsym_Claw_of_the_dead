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
## One-time events already played (dialogues...), e.g. [code]armory_intro_seen[/code].
var flags: Dictionary[String, bool] = {}
## Whether the first-play tutorial is completed.
var tutorial_completed: bool = false

## Converts the object to a dictionary for serialization.
func save() -> Dictionary:
	return {
		"flags": flags.duplicate(),
		"language": language,
		"music_enabled": music_enabled,
		"sound_enabled": sound_enabled,
		"tutorial_completed": tutorial_completed
	}

## Populates the object from a dictionary.
func from_dictionary(data: Dictionary) -> void:
	flags.assign(data.get("flags", {}))
	## Saves made before the flags only stored this one as its own key.
	if data.get("armory_intro_seen", false):
		flags["armory_intro_seen"] = true
	language = data.get("language", "fr")
	music_enabled = data.get("music_enabled", true)
	sound_enabled = data.get("sound_enabled", true)
	tutorial_completed = data.get("tutorial_completed", false)
