## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages popup elements like score and wave notifications in the game.
class_name PopupSpawner
extends Marker2D

# Exported Variables
@export var popup_node: PackedScene

# core
func _ready() -> void:
	assert(popup_node != null, "popup_node scene not assigned")

# public
## Spawns a score popup at the current position.
## [br]The popup will move upward and display the given text.
## [param text] The score value to display
func score(text: String) -> void:
	var damage_popup: Node2D = popup_node.instantiate()
	var label: Label = damage_popup.get_node("FloatingNumbers/Label")
	damage_popup.position = global_position

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(damage_popup, "position", global_position + Vector2(0, -16), 1)

	get_tree().current_scene.add_child(damage_popup)

	label.text = text
	damage_popup.z_index = 4096

## Spawns a wave notification popup at the current position.
## [br]The popup will display the given wave text.
## [param text] The wave text to display
func wave(text: String) -> void:
	var wave_popup: Control = popup_node.instantiate()
	var label: Label = wave_popup.get_node("CenterContainer/TextureRect/Label")

	# Add to UI instead of current scene
	Global.ui.add_child(wave_popup)
	label.text = text
