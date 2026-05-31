## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages popup elements like score and wave notifications in the game.
class_name PopupSpawner
extends Marker2D

# Exported Variables
@export var damage_popup_node: PackedScene
@export var popup_node: PackedScene

# Constants
const TOWER_COLORS: Dictionary = {
	"bat_01": Color.WHITE, # Arbre à chat'rché (White)
	"bat_02": Color("#744187"), # Tour Cataboom (Purple)
	"bat_08": Color("#00ffff"), # Tour Tesla (Cyan)
	"bat_09": Color("#ff8c00"), # Tour Inferno (Dark Orange)
}

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
	
	var final_color: Color = color
	
	# Check if the damage source requires popup accumulation (e.g., continuous fire)
	var should_accumulate: bool = false
	if get_parent() is IEnemy:
		var source: Variant = get_parent().last_source
		var tower: ITower = null
		
		if source is ITower:
			tower = source
		elif source is IBullet and is_instance_valid(source.tower_owner):
			tower = source.tower_owner
			
		if tower != null:
			if tower.use_accumulative_popups:
				should_accumulate = true
			
			# Apply tower-specific color if defined
			if TOWER_COLORS.has(tower.tower_id):
				final_color = TOWER_COLORS[tower.tower_id]
	
	# Optimization: check if an active popup already exists for accumulation
	if should_accumulate and _active_popups.has(self) and is_instance_valid(_active_popups[self]):
		var popup: DamagePopup = _active_popups[self]
		if popup.has_method("update_value"):
			popup.update_value(amount)
			return

	var damage_popup: DamagePopup = damage_popup_node.instantiate()
	damage_popup.amount = amount
	damage_popup.color = final_color
	damage_popup.is_critical = is_critical
	
	if should_accumulate:
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
	var texture_rect: TextureRect = wave_popup.get_node("CenterContainer/TextureRect")

	# Add to UI instead of current scene
	Global.ui.add_child(wave_popup)
	texture_rect.pivot_offset = texture_rect.get_size() / 2
	label.text = text
