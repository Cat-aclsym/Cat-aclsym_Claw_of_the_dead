## © [2024] A7 Studio. All rights reserved. Trademark.
## File: option_menu.gd
##Option menu of the game
##From this menu we can access parameters, socials, and miscellaneous things
##
##Author: Matéo Perrot--Nasi
##Created: 28/02/2024
##
class_name OptionMenu
extends Control

signal menu_close

@onready var music_texture_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/MusicAspectRatioContainer/MusicTextureButton
@onready var sound_texture_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/SoundAspectRatioContainer/SoundTextureButton
@onready var language_texture_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/LanguageAspectRatioContainer/LanguageTextureButton

var actualTexture: Texture2D


# core


# public


# private


# signal
func _on_music_texture_button_pressed():
	actualTexture = music_texture_button.get_texture_normal()
	music_texture_button.set_texture_normal(music_texture_button.get_texture_pressed())
	music_texture_button.set_texture_pressed(actualTexture)


func _on_sound_texture_button_pressed():
	actualTexture = sound_texture_button.get_texture_normal()
	sound_texture_button.set_texture_normal(sound_texture_button.get_texture_pressed())
	sound_texture_button.set_texture_pressed(actualTexture)


func _on_language_texture_button_pressed():
	if TranslationServer.get_locale() == "en":
		TranslationServer.set_locale("fr")
		actualTexture = language_texture_button.get_texture_normal()
		language_texture_button.set_texture_normal(language_texture_button.get_texture_pressed())
		language_texture_button.set_texture_pressed(actualTexture)
	else:
		TranslationServer.set_locale("en")
		actualTexture = language_texture_button.get_texture_normal()
		language_texture_button.set_texture_normal(language_texture_button.get_texture_pressed())
		language_texture_button.set_texture_pressed(actualTexture)


func _on_instagram_texture_button_pressed():
	OS.shell_open("https://www.instagram.com/a7studio.cataclysm/")


func _on_x_texture_button_pressed():
	OS.shell_open("https://twitter.com/a7studio_off")


func _on_discord_texture_button_pressed():
	OS.shell_open("https://discord.gg/xf5zEn3NtJ")


func _on_update_texture_button_pressed():
	pass


func _on_rgpd_texture_button_pressed():
	pass


func _on_contact_texture_button_pressed():
	OS.shell_open("mailto:A7studio.contact@gmail.com")


func _on_close_texture_button_pressed():
	menu_close.emit()


# event


# setget


