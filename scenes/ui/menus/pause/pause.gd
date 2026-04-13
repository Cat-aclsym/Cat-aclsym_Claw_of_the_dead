## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the pause menu functionality and UI interactions.
## Handles game pause, restart, and navigation controls.
class_name Pause
extends Control

# Onready Variables
@onready var encyclopedia_button: TextureButton = %EncyclopediaButton
@onready var encyclopedia_exclamation: TextureRect = %EncyclopediaExclamation
@onready var home_button: TextureButton = $Panel/MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/HomeButton
@onready var margin_container: MarginContainer = $Panel/MarginContainer
@onready var music_button: TextureButton = $Panel/MarginContainer/PanelContainer/CenterContainer/VBoxContainer/TopLeftIcon/MusicButton
@onready var play_button: TextureButton = $Panel/MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/PlayButton
@onready var restart_button: TextureButton = $Panel/MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/RestartButton
@onready var sound_button: TextureButton = $Panel/MarginContainer/PanelContainer/CenterContainer/VBoxContainer/TopLeftIcon/SoundButton

@onready var _encyclopedia_menu: PackedScene = preload("res://scenes/ui/menus/hud/encyclopedia.tscn")

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: encyclopedia_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_encyclopedia_button_pressed},
	{SignalUtil.WHO: home_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_home_button_pressed},
	{SignalUtil.WHO: restart_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_restart_button_pressed},
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed}
]

	# core
func _ready() -> void:
	assert(encyclopedia_button != null, "encyclopedia_button node not found")
	assert(encyclopedia_exclamation != null, "encyclopedia_exclamation node not found")
	assert(home_button != null, "home_button node not found")
	assert(restart_button != null, "restart_button node not found")
	assert(play_button != null, "play_button node not found")
	SignalUtil.connects(signals)
	
	# Force process mode to Always so tweens run even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Fix for button animations in pause menu
	for btn in [music_button, sound_button, encyclopedia_button, home_button, play_button, restart_button]:
		if btn:
			btn.process_mode = Node.PROCESS_MODE_ALWAYS
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			ButtonEffects.apply(btn)

	# Wait for a frame to ensure sizes are calculated for pivot centering
	await get_tree().process_frame
	
	# Re-apply pivot after frame wait to be sure
	for btn in [music_button, sound_button, encyclopedia_button, home_button, play_button, restart_button]:
		if btn: btn.pivot_offset = btn.size / 2
	
	# Update notification after everything is set up
	_update_encyclopedia_notification()

# private
## Handles the encyclopedia button press event.
## [br]Shows the encyclopedia menu and hides the current menu content.
func _on_encyclopedia_button_pressed() -> void:
	margin_container.visible = false
	var encyclopedia_instance: Encyclopedia = _encyclopedia_menu.instantiate() as Encyclopedia
	add_child(encyclopedia_instance)
	encyclopedia_instance.menu_close.connect(func():
		encyclopedia_instance.queue_free()
		margin_container.visible = true
		_update_encyclopedia_notification()
	)

## Returns to the main menu and cleans up the current level.
func _on_home_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	ILevel.current_level.queue_free()
	Global.paused = false

## Restarts the current level with fresh state.
## [br]Creates a new instance of the current level and initializes it.
func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	var current_level := ILevel.current_level
	var level_scene: PackedScene = load(current_level.get_scene_file_path())

	current_level.queue_free()
	await current_level.tree_exited

	var new_level: ILevel = level_scene.instantiate()
	get_tree().get_root().add_child(new_level)
	new_level.start_level()
	Global.ui.start_level()

	Global.paused = false
	queue_free()

## Updates the encyclopedia notification icon visibility.
func _update_encyclopedia_notification() -> void:
	encyclopedia_exclamation.visible = ProgressionManager.has_unseen_encyclopedia_enemies() or ProgressionManager.has_unseen_encyclopedia_towers()


# signals
## Resumes the game by unpausing and closing the menu.
func _on_play_button_pressed() -> void:
	get_tree().paused = false
	Global.paused = false
	if ILevel.current_level != null:
		ILevel.current_level.resume_from_pause()
	queue_free()
