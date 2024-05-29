class_name PopupSpawner
extends Marker2D

## Packed scene used for instantiating popups.
@export var popup_node: PackedScene

## Spawns a score popup at the position of this spawner.
## @param text: String - The text to display in the popup.
func score(text: String):
	## Instantiate the popup node.
	var damage_popup: Node2D = popup_node.instantiate()
	## Get the label from the popup node.
	var label: Label = damage_popup.get_node("FloatingNumbers/Label")
	## Set the popup position.
	damage_popup.position = global_position

	## Create a tween for the popup animation.
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(damage_popup, "position", global_position + Vector2(0, -16), 1)

	## Add the popup to the current scene.
	get_tree().current_scene.add_child(damage_popup)

	## Set the label text and z-index.
	label.text = text
	damage_popup.z_index = 4096

## Spawns a wave popup at the position of this spawner.
## @param text: String - The text to display in the popup.
func wave(text: String):
	## Instantiate the popup node.
	var wave_popup: Node2D = popup_node.instantiate()
	## Get the label from the popup node.
	var label: Label = wave_popup.get_node("WaveMarker/TextureRect/Label")
	## Set the popup position.
	wave_popup.position = global_position

	## Add the popup to the current scene.
	get_tree().current_scene.add_child(wave_popup)

	## Set the label text and z-index.
	label.text = text
	wave_popup.z_index = 4096
