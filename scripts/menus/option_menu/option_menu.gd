## File: option_menu.gd
##Option menu of the game
##From this menu we can access parameters, socials, and miscellaneous things
##
##Author: Matéo Perrot--Nasi
##Created: 28/02/2024
##
class_name OptionMenu
extends Control

signal menu_option_close

@onready var musicTextureButton: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/MusicAspectRatioContainer/MusicTextureButton
@onready var soundTextureButton: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/SoundAspectRatioContainer/SoundTextureButton
@onready var languageTextureButton: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/LanguageAspectRatioContainer/LanguageTextureButton

var actualTexture: Texture2D


func _on_music_texture_button_pressed():
	actualTexture = musicTextureButton.get_texture_normal()
	musicTextureButton.set_texture_normal(musicTextureButton.get_texture_pressed())
	musicTextureButton.set_texture_pressed(actualTexture)


func _on_sound_texture_button_pressed():
	actualTexture = soundTextureButton.get_texture_normal()
	soundTextureButton.set_texture_normal(soundTextureButton.get_texture_pressed())
	soundTextureButton.set_texture_pressed(actualTexture)


func _on_language_texture_button_pressed():
	if TranslationServer.get_locale() == "en":
		TranslationServer.set_locale("fr")
		actualTexture = languageTextureButton.get_texture_normal()
		languageTextureButton.set_texture_normal(languageTextureButton.get_texture_pressed())
		languageTextureButton.set_texture_pressed(actualTexture)
	else:
		TranslationServer.set_locale("en")
		actualTexture = languageTextureButton.get_texture_normal()
		languageTextureButton.set_texture_normal(languageTextureButton.get_texture_pressed())
		languageTextureButton.set_texture_pressed(actualTexture)


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
	menu_option_close.emit()
	queue_free()


