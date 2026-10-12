## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages popup elements like score and wave notifications in the game.
class_name PopupSpawner
extends Marker2D

# Constants
const TOWER_COLORS: Dictionary = {
	"bat_01": Color.WHITE, # Arbre à chat'rché (White)
	"bat_02": Color("#744187"), # Tour Cataboom (Purple)
	"bat_08": Color("#00ffff"), # Tour Tesla (Cyan)
	"bat_09": Color("#ff8c00"), # Tour Inferno (Dark Orange)
}

# Exported Variables
@export var damage_popup_node: PackedScene
@export var popup_node: PackedScene

## Popup that accumulates the damage of this spawner while the damage source asks for it.
var _accumulating_popup: DamagePopup = null

# core
func _ready() -> void:
	assert(popup_node != null, "popup_node scene not assigned")

# public

## Spawns a damage popup at the current position.
## [br]
## [param amount] The amount of damage to display
## [param color] The color of the damage text, overridden by the color of [param tower]
## [param tower] The tower that dealt the damage, if any: it picks the color and tells whether the damage accumulates in one popup (e.g., continuous fire)
## [param is_critical] Whether the damage is a critical hit
func display_damage(amount: float, color: Color = Color.WHITE, tower: ITower = null, is_critical: bool = false) -> void:
	if damage_popup_node == null:
		return

	var final_color: Color = color
	var should_accumulate: bool = false
	if is_instance_valid(tower):
		should_accumulate = tower.use_accumulative_popups
		final_color = TOWER_COLORS.get(tower.tower_id, color)

	# Optimization: check if an active popup already exists for accumulation
	if should_accumulate and is_instance_valid(_accumulating_popup):
		_accumulating_popup.update_value(amount)
		return

	var damage_popup: DamagePopup = damage_popup_node.instantiate()
	damage_popup.amount = amount
	damage_popup.color = final_color
	damage_popup.is_critical = is_critical
	
	if should_accumulate:
		damage_popup.target_node = self
		damage_popup.is_accumulative = true
		_accumulating_popup = damage_popup
	
	# Use global_position of the spawner
	damage_popup.global_position = global_position
	
	# Add to the root scene to avoid being affected by enemy movement/rotation
	get_tree().current_scene.add_child(damage_popup)

## Spawns a score popup at the current position.
## [br]The popup will move upward and display the given text.
## [param text] The score value to display
func score(text: String) -> void:
	var damage_popup: Control = popup_node.instantiate()
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
