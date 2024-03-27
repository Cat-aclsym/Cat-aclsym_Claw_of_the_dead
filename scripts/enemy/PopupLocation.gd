class_name PopupLocation
extends Marker2D


@export var damage_node: PackedScene

func popup(text: String):
	var damage: Node2D = damage_node.instantiate()
	var label: Label = damage.get_node("FloatingNumbers/Label")
	damage.position = global_position
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(damage, "position", global_position + Vector2(0, -16), 1)
	
	get_tree().current_scene.add_child(damage)
	
	label.text = text
	damage.z_index = 4096
