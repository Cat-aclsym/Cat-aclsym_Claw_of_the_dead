## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages popup elements like score and wave notifications in the game.
class_name PopupSpawner
extends Marker2D

# Exported Variables
@export var damage_popup_node: PackedScene
@export var popup_node: PackedScene

# core
func _ready() -> void:
	assert(popup_node != null, "popup_node scene not assigned")

# public
var _active_popups: Dictionary = {} # target_node -> DamagePopup

## Spawns a damage popup at the current position.
## [br]
## [param amount] The amount of damage to display
## [param color] The color of the damage text
## [param is_critical] Whether the damage is a critical hit
func display_damage(amount: float, color: Color = Color.WHITE, is_critical: bool = false) -> void:
	if damage_popup_node == null:
		return
	
	# Check if this source is an Inferno Tower
	var is_inferno = false
	var source = null
	if get_parent() is IEnemy:
		source = get_parent().last_source
		if source is ITower and source.tower_id == "bat_09":
			is_inferno = true
	
	# Optimization for Inferno: check if an active popup already exists
	if is_inferno and _active_popups.has(self) and is_instance_valid(_active_popups[self]):
		var popup = _active_popups[self]
		if popup.has_method("update_value"):
			popup.update_value(amount)
			return

	var damage_popup: DamagePopup = damage_popup_node.instantiate()
	damage_popup.amount = amount
	damage_popup.color = color
	damage_popup.is_critical = is_critical
	
	if is_inferno:
		damage_popup.target_node = self
		damage_popup.is_accumulative = true
		_active_popups[self] = damage_popup
	
	# Use global_position of the spawner
	damage_popup.global_position = global_position
	
	# Add to the root scene to avoid being affected by enemy movement/rotation
	get_tree().current_scene.add_child(damage_popup)
	
	Log.trace(Log.Level.DEBUG, "Spawning damage popup: %s at %s" % [amount, global_position])

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
	var texture_rect: TextureRect = wave_popup.get_node("CenterContainer/TextureRect")

	# Add to UI instead of current scene
	Global.ui.add_child(wave_popup)
	texture_rect.pivot_offset = texture_rect.get_size() / 2
	label.text = text
