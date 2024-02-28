extends Control

var musicTextureButton: TextureButton
var soundTextureButton: TextureButton

var actualTexture: Texture2D


# Called when the node enters the scene tree for the first time.
func _ready():
	musicTextureButton = $ScreenBoxContainer/MenuCenterContainer/MenuRowVBoxContainer/ParametersHBoxContainer/MusicTextureButton
	soundTextureButton = $ScreenBoxContainer/MenuCenterContainer/MenuRowVBoxContainer/ParametersHBoxContainer/SoundTextureButton


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


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
	else:
		TranslationServer.set_locale("en")


func _on_instagram_texture_button_pressed():
	OS.shell_open("https://www.instagram.com/a7studio.cataclysm/")


func _on_x_texture_button_pressed():
	OS.shell_open("https://twitter.com/a7studio_off")


func _on_discord_texture_button_pressed():
	OS.shell_open("https://discord.gg/xf5zEn3NtJ")


func _on_update_texture_button_pressed():
	pass # Replace with function body.


func _on_rgpd_texture_button_pressed():
	pass # Replace with function body.


func _on_contact_texture_button_pressed():
	OS.shell_open("mailto:A7studio.contact@gmail.com")


func _on_close_texture_button_pressed():
	queue_free()
