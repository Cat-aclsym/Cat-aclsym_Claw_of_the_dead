## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the pause menu functionality and UI interactions.
## Handles game pause, restart, and navigation controls.
class_name Pause
extends Control

signal resumed

const ENCYCLOPEDIA_MENU: PackedScene = preload("res://scenes/ui/menus/hud/encyclopedia.tscn")

# Onready Variables
@onready var encyclopedia_button: TextureButton = %EncyclopediaButton
@onready var encyclopedia_exclamation: TextureRect = %EncyclopediaExclamation
@onready var home_button: TextureButton = $Panel/MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/HomeButton
@onready var margin_container: MarginContainer = $Panel/MarginContainer
@onready var music_button: TextureButton = $Panel/MarginContainer/PanelContainer/CenterContainer/VBoxContainer/TopLeftIcon/MusicButton
@onready var play_button: TextureButton = $Panel/MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/PlayButton
@onready var restart_button: TextureButton = $Panel/MarginContainer/PanelContainer/CenterContainer/VBoxContainer/ButtonLayer/RestartButton
@onready var sound_button: TextureButton = $Panel/MarginContainer/PanelContainer/CenterContainer/VBoxContainer/TopLeftIcon/SoundButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: encyclopedia_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_encyclopedia_button_pressed},
	{SignalUtil.WHO: home_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_home_button_pressed},
	{SignalUtil.WHO: music_button, SignalUtil.WHAT: "toggled", SignalUtil.TO: _on_music_button_toggled},
	{SignalUtil.WHO: restart_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_restart_button_pressed},
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed},
	{SignalUtil.WHO: sound_button, SignalUtil.WHAT: "toggled", SignalUtil.TO: _on_sound_button_toggled},
]

# core
func _ready() -> void:
	assert(encyclopedia_button != null, "encyclopedia_button node not found")
	assert(encyclopedia_exclamation != null, "encyclopedia_exclamation node not found")
	assert(home_button != null, "home_button node not found")
	assert(music_button != null, "music_button node not found")
	assert(restart_button != null, "restart_button node not found")
	assert(play_button != null, "play_button node not found")
	assert(sound_button != null, "sound_button node not found")

	# The pressed texture of both buttons is the "off" icon, the same settings as the options menu
	music_button.set_pressed_no_signal(not ProgressionManager.data.parameters.music_enabled)
	sound_button.set_pressed_no_signal(not ProgressionManager.data.parameters.sound_enabled)
	SignalUtil.connects(signals)

	# Force process mode to Always so tweens run even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Fix for button animations in pause menu
	for btn: TextureButton in [music_button, sound_button, encyclopedia_button, home_button, play_button, restart_button]:
		if btn:
			btn.process_mode = Node.PROCESS_MODE_ALWAYS
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			ButtonEffects.apply(btn)

	# Wait for a frame to ensure sizes are calculated for pivot centering
	await get_tree().process_frame

	# Re-apply pivot after frame wait to be sure
	for btn: TextureButton in [music_button, sound_button, encyclopedia_button, home_button, play_button, restart_button]:
		if btn: btn.pivot_offset = btn.size / 2

	# Update notification after everything is set up
	_update_encyclopedia_notification()

# private
## Handles the encyclopedia button press event.
## [br]Shows the encyclopedia menu and hides the current menu content.
func _on_encyclopedia_button_pressed() -> void:
	margin_container.visible = false
	var encyclopedia_instance: Encyclopedia = ENCYCLOPEDIA_MENU.instantiate() as Encyclopedia
	add_child(encyclopedia_instance)
	SignalUtil.connects([{SignalUtil.WHO: encyclopedia_instance, SignalUtil.WHAT: "menu_close", SignalUtil.TO: _on_encyclopedia_closed.bind(encyclopedia_instance)}])

## Closes the encyclopedia and shows the pause menu content again.
func _on_encyclopedia_closed(encyclopedia_instance: Encyclopedia) -> void:
	encyclopedia_instance.queue_free()
	margin_container.visible = true
	_update_encyclopedia_notification()

## Returns to the main menu and cleans up the current level.
func _on_home_button_pressed() -> void:
	ScenesLoader.go_home()

## Saves the music setting and applies it, like the music button of the options menu.
func _on_music_button_toggled(is_off: bool) -> void:
	ProgressionManager.data.parameters.music_enabled = not is_off
	ProgressionManager.save_game()
	ProgressionManager.apply_settings()

## Resumes the game by unpausing and closing the menu.
func _on_play_button_pressed() -> void:
	Global.release_pause(&"pause_menu")
	resumed.emit()
	queue_free()

## Restarts the current level with fresh state.
## [br]Creates a new instance of the current level and initializes it.
func _on_restart_button_pressed() -> void:
	await ScenesLoader.start_level(ILevel.current_level.level_id)
	queue_free()

## Saves the sound setting and applies it, like the sound button of the options menu.
func _on_sound_button_toggled(is_off: bool) -> void:
	ProgressionManager.data.parameters.sound_enabled = not is_off
	ProgressionManager.save_game()
	ProgressionManager.apply_settings()

## Updates the encyclopedia notification icon visibility.
func _update_encyclopedia_notification() -> void:
	encyclopedia_exclamation.visible = ProgressionManager.has_unseen_encyclopedia_enemies() or ProgressionManager.has_unseen_encyclopedia_towers()
