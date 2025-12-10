## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the game's options menu interface and functionality.
## Handles settings for music, sound, language, and social media links.
class_name Options
extends Control

# signals
signal menu_close

# private variables
var _actual_texture: Texture2D

## Preloaded flag textures for language toggle button
@onready var _flag_en: Texture2D = preload("res://assets/ui/icons/Button Language English.svg")
@onready var _flag_fr: Texture2D = preload("res://assets/ui/icons/Button Language French.png")

## Options buttons
@onready var close_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/TopLineHBoxContainer/AspectRatioContainer/CloseTextureButton
@onready var contact_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/MiscHBoxContainer/ContactAspectRatioContainer/ContactTextureButton
@onready var discord_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SocialsHBoxContainer/DiscordAspectRatioContainer/DiscordTextureButton
@onready var instagram_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SocialsHBoxContainer/InstagramAspectRatioContainer/InstagramTextureButton
@onready var language_toggle_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/LanguageAspectRatioContainer/LanguageTextureButton
@onready var music_toggle_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/MusicAspectRatioContainer/MusicTextureButton
@onready var news_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/MiscHBoxContainer/NewsAspectRatioContainer/NewsTextureButton
@onready var rgpd_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/MiscHBoxContainer/InformationAspectRatioContainer/InformationTextureButton
@onready var sound_toggle_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SettingsHBoxContainer/SoundAspectRatioContainer/SoundTextureButton
@onready var x_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/SocialsHBoxContainer/XAspectRatioContainer/XTextureButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_texture_button_pressed},
	{SignalUtil.WHO: contact_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_contact_texture_button_pressed},
	{SignalUtil.WHO: discord_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_discord_texture_button_pressed},
	{SignalUtil.WHO: instagram_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_instagram_texture_button_pressed},
	{SignalUtil.WHO: language_toggle_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_language_texture_button_pressed},
	{SignalUtil.WHO: music_toggle_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_music_texture_button_pressed},
	{SignalUtil.WHO: news_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_update_texture_button_pressed},
	{SignalUtil.WHO: rgpd_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_rgpd_texture_button_pressed},
	{SignalUtil.WHO: sound_toggle_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_sound_texture_button_pressed},
	{SignalUtil.WHO: x_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_x_texture_button_pressed},
]

# core
func _ready() -> void:
	assert(music_toggle_button != null, "music_texture_button node not found")
	assert(sound_toggle_button != null, "sound_texture_button node not found")
	assert(language_toggle_button != null, "language_texture_button node not found")
	SignalUtil.connects(signals)

	# Set initial button states based on current settings
	_update_button_states()

# private
## Toggles the music state and updates the button texture.
func _on_music_texture_button_pressed() -> void:
	_actual_texture = music_toggle_button.get_texture_normal()
	music_toggle_button.set_texture_normal(music_toggle_button.get_texture_pressed())
	music_toggle_button.set_texture_pressed(_actual_texture)
	# Update progression parameter and persist it
	var current_music: bool = ProgressionManager.data.parameters.music_enabled
	ProgressionManager.data.parameters.music_enabled = not current_music
	ProgressionManager.save_game()
	ProgressionManager.apply_settings()

## Toggles the sound state and updates the button texture.
func _on_sound_texture_button_pressed() -> void:
	_actual_texture = sound_toggle_button.get_texture_normal()
	sound_toggle_button.set_texture_normal(sound_toggle_button.get_texture_pressed())
	sound_toggle_button.set_texture_pressed(_actual_texture)
	# Update progression parameter and persist it
	var current_sound: bool = ProgressionManager.data.parameters.sound_enabled
	ProgressionManager.data.parameters.sound_enabled = not current_sound
	ProgressionManager.save_game()
	ProgressionManager.apply_settings()

## Toggles between English and French languages.
## [br]Updates the button texture to reflect the current language.
func _on_language_texture_button_pressed() -> void:
	# Toggle to the other language and persist the choice.
	var current_locale := ProgressionManager.data.parameters.language if ProgressionManager.data.parameters.language != "" else TranslationServer.get_locale()
	var new_locale := "fr" if current_locale == "en" else "en"

	ProgressionManager.data.parameters.language = new_locale
	ProgressionManager.save_game()
	ProgressionManager.apply_settings()

	# Update the button to show the other available language (not the current one).
	_update_language_button_display()

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

## Updates the button textures to reflect the current settings.
func _update_button_states() -> void:
	# For music button: if music_enabled is true, normal should be "on" texture
	# Assuming normal is on, pressed is off
	if not ProgressionManager.data.parameters.music_enabled:
		# Swap to show off
		var temp: Texture2D = music_toggle_button.get_texture_normal()
		music_toggle_button.set_texture_normal(music_toggle_button.get_texture_pressed())
		music_toggle_button.set_texture_pressed(temp)

	# Same for sound
	if not ProgressionManager.data.parameters.sound_enabled:
		var temp: Texture2D = sound_toggle_button.get_texture_normal()
		sound_toggle_button.set_texture_normal(sound_toggle_button.get_texture_pressed())
		sound_toggle_button.set_texture_pressed(temp)

	# Show the other available language on the button (not the current one).
	_update_language_button_display()

## Sets the language toggle button texture so it shows the other available language.
func _update_language_button_display() -> void:
	var current_locale := ProgressionManager.data.parameters.language if ProgressionManager.data.parameters.language != "" else TranslationServer.get_locale()
	if current_locale == "fr":
		language_toggle_button.texture_normal = _flag_en
		language_toggle_button.texture_pressed = _flag_fr
	else:
		language_toggle_button.texture_normal = _flag_fr
		language_toggle_button.texture_pressed = _flag_en

## Emits the menu close signal.
func _on_close_texture_button_pressed() -> void:
	menu_close.emit()
