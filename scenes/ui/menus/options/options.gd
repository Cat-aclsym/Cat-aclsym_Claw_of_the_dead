## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the game's options menu interface and functionality.
## Handles settings for music, sound, language, and social media links.
class_name OptionMenu
extends Control

# signals
signal menu_close

# private variables
var _actual_texture: Texture2D

# Onready Variables
@onready var music_texture_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/MusicAspectRatioContainer/MusicTextureButton
@onready var sound_texture_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/SoundAspectRatioContainer/SoundTextureButton
@onready var language_texture_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/LanguageAspectRatioContainer/LanguageTextureButton

# core
func _ready() -> void:
	assert(music_texture_button != null, "music_texture_button node not found")
	assert(sound_texture_button != null, "sound_texture_button node not found")
	assert(language_texture_button != null, "language_texture_button node not found")

# private
## Toggles the music state and updates the button texture.
func _on_music_texture_button_pressed() -> void:
	_actual_texture = music_texture_button.get_texture_normal()
	music_texture_button.set_texture_normal(music_texture_button.get_texture_pressed())
	music_texture_button.set_texture_pressed(_actual_texture)

## Toggles the sound state and updates the button texture.
func _on_sound_texture_button_pressed() -> void:
	_actual_texture = sound_texture_button.get_texture_normal()
	sound_texture_button.set_texture_normal(sound_texture_button.get_texture_pressed())
	sound_texture_button.set_texture_pressed(_actual_texture)

## Toggles between English and French languages.
## [br]Updates the button texture to reflect the current language.
func _on_language_texture_button_pressed() -> void:
	if TranslationServer.get_locale() == "en":
		TranslationServer.set_locale("fr")
		_actual_texture = language_texture_button.get_texture_normal()
		language_texture_button.set_texture_normal(language_texture_button.get_texture_pressed())
		language_texture_button.set_texture_pressed(_actual_texture)
	else:
		TranslationServer.set_locale("en")
		_actual_texture = language_texture_button.get_texture_normal()
		language_texture_button.set_texture_normal(language_texture_button.get_texture_pressed())
		language_texture_button.set_texture_pressed(_actual_texture)

## Opens the Instagram social media link.
func _on_instagram_texture_button_pressed() -> void:
	OS.shell_open("https://www.instagram.com/a7studio.cataclysm/")

## Opens the X (Twitter) social media link.
func _on_x_texture_button_pressed() -> void:
	OS.shell_open("https://twitter.com/a7studio_off")

## Opens the Discord community link.
func _on_discord_texture_button_pressed() -> void:
	OS.shell_open("https://discord.gg/xf5zEn3NtJ")

## Placeholder for update functionality.
func _on_update_texture_button_pressed() -> void:
	pass

## Placeholder for RGPD functionality.
func _on_rgpd_texture_button_pressed() -> void:
	pass

## Opens the contact email link.
func _on_contact_texture_button_pressed() -> void:
	OS.shell_open("mailto:A7studio.contact@gmail.com")

## Emits the menu close signal.
func _on_close_texture_button_pressed() -> void:
	menu_close.emit()
