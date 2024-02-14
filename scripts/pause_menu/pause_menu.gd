## File:	pause_menu.gd.
##
## Author:	Laurie Jeham-Masselot
## Created: 24/01/2024
##
## Methods for pausing screen when the player is on Game
## Pause/Restart/Home and sounds options conf

class_name PauseMenu
extends Control

#Button

var state: String = "mute"

@onready var restartButton: TextureButton = $CenterContainer/MainLayout/ButtonLayer/RestartButton
@onready var playButton: TextureButton = $CenterContainer/MainLayout/ButtonLayer/PlayButton
@onready var homeButton: TextureButton = $CenterContainer/MainLayout/ButtonLayer/HomeButton
@onready var musicButton : TextureButton = $TopLeftIcon/MusicButton
@onready var soundButton : TextureButton = $TopLeftIcon/SoundButton
@onready var bugReport : TextureButton = $TopLeftIcon/BugReport

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called when the node is added to the scene tree for the first time.
func _on_pressed(button):
	print(button.name, " was pressed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_homeButton_pressed():
	#Go back to the main menu
	get_tree().change_scene("res://scenes/main.tscn")


func _on_restart_button_pressed():
	#Restart the game
	get_tree().reload_current_scene()


func _on_play_button_pressed():
	# Resume the game
	get_tree().current_scene.set_process(true)
	# Delete the pause menu
	queue_free() 
