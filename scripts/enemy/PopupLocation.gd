class_name PopupSpawner
extends Marker2D


@export var popup_node: PackedScene

func score(text: String):
	var damage_popup: Node2D = popup_node.instantiate()
	var label: Label = damage_popup.get_node("FloatingNumbers/Label")
	damage_popup.position = global_position
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(damage_popup, "position", global_position + Vector2(0, -16), 1)
	
	get_tree().current_scene.add_child(damage_popup)
	
	label.text = text
	damage_popup.z_index = 4096


func wave(text: String):
	print("caca boudin gros pipi")
	var wave_popup: Node2D = popup_node.instantiate()
	var label: Label = wave_popup.get_node("WaveMarker/TextureRect/Label")
	wave_popup.position = global_position

	get_tree().current_scene.add_child(wave_popup)

	label.text = text
	wave_popup.z_index = 4096
