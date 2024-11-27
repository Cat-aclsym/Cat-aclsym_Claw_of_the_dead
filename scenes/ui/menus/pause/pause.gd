## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the pause menu functionality and UI interactions.
## Handles game pause, restart, and navigation controls.
class_name PauseMenu
extends Control

# Onready Variables
@onready var home_button: TextureButton = $MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/HomeButton
@onready var music_button: TextureButton = $MarginContainer/PanelContainer/CenterContainer/VBoxContainer/TopLeftIcon/MusicButton
@onready var play_button: TextureButton = $MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/PlayButton
@onready var quit_button: TextureButton = $MarginContainer/PanelContainer/MarginContainer/AspectRatioContainer/CloseTextureButton
@onready var restart_button: TextureButton = $MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/RestartButton
@onready var sound_button: TextureButton = $MarginContainer/PanelContainer/CenterContainer/VBoxContainer/TopLeftIcon/SoundButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: home_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_home_button_pressed},
	{SignalUtil.WHO: restart_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_restart_button_pressed},
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed},
	{SignalUtil.WHO: quit_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_texture_button_pressed},
]

# core
func _ready() -> void:
	assert(home_button != null, "home_button node not found")
	assert(restart_button != null, "restart_button node not found")
	assert(play_button != null, "play_button node not found")
	assert(quit_button != null, "quit_button node not found")
	SignalUtil.connects(signals)

# private
## Returns to the main menu and cleans up the current level.
func _on_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	ILevel.current_level.queue_free()
	Global.paused = false

## Restarts the current level with fresh state.
## [br]Creates a new instance of the current level and initializes it.
func _on_restart_button_pressed() -> void:
	var current_level := ILevel.current_level
	var level_metadata: LevelMetadata = current_level.metadata.duplicate()
	var level_scene: PackedScene = load(current_level.get_scene_file_path())

	current_level.queue_free()
	await current_level.tree_exited

	var new_level: ILevel = level_scene.instantiate()
	get_tree().get_root().add_child(new_level)
	new_level.initialize(level_metadata)
	ILevel.current_level = new_level
	Global.ui.start_level()

	Global.paused = false
	queue_free()

# signals
## Resumes the game by unpausing and closing the menu.
func _on_play_button_pressed() -> void:
	Global.paused = false
	queue_free()

## Closes the pause menu and resumes the game.
func _on_close_texture_button_pressed() -> void:
	Global.paused = false
	queue_free()
