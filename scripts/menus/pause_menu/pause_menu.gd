## File: pause_menu.gd.
##
## Author: Laurie Jeham-Masselot
## Created: 24/01/2024
##
## Methods for pausing screen when the player is on Game
## Pause/Restart/Home and sounds options conf

class_name PauseMenu
extends Control


@onready var restart_button: TextureButton = $MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/RestartButton
@onready var play_button: TextureButton = $MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/PlayButton
@onready var home_button: TextureButton = $MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/HomeButton
@onready var music_button: TextureButton = $MarginContainer/PanelContainer/CenterContainer/VBoxContainer/TopLeftIcon/MusicButton
@onready var sound_button: TextureButton = $MarginContainer/PanelContainer/CenterContainer/VBoxContainer/TopLeftIcon/SoundButton
@onready var quit_button: TextureButton = $MarginContainer/PanelContainer/MarginContainer/AspectRatioContainer/CloseTextureButton


# core


# public


# private


# signal
## Go back to the main menu
func _on_home_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
	ILevel.current_level.queue_free()
	Global.paused = false


## Restart the game
func _on_restart_button_pressed():
	# Copy current level
	var current_level: ILevel = ILevel.current_level
	var level_metadata: LevelMetadata = current_level.Metadata.duplicate()
	var level_scene: PackedScene = load(current_level.get_scene_file_path())

	# Clear the current level
	current_level.queue_free()
	await current_level.tree_exited

	# Create a new level from the copied one
	var new_level: ILevel = level_scene.instantiate()
	get_tree().get_root().add_child(new_level)
	new_level.initialize(level_metadata)
	ILevel.current_level = new_level
	Global.hud.start_level()

	# Close the menu
	Global.paused = false
	queue_free()


## Resume the game
func _on_play_button_pressed():
	Global.paused = false
	queue_free()


## Close the menu
func _on_close_texture_button_pressed():
	Global.paused = false
	queue_free()


# event


# setget

