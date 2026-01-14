## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the display of tower upgrade statistics with dynamic gauge bars.
class_name TowerUpgradeDescription
extends Control

# Constants
const NUM_GAUGE_SQUARES: int = 4
const SQUARE_SPACING: float = 5.0
const GAUGE_TEXTURES := {
	1: preload("res://assets/ui/iconsMenu/stat_colored.svg"),
	2: preload("res://assets/ui/iconsMenu/stat.svg"),
}

## Reference to the tower being upgraded
var tower: ITower

@onready var upgrade_title_label: Label = $UpgradeDescriptionTextureRect/MarginContainer/UpgradeDescriptionVBoxContainer/UpgradeTitleLabel
@onready var attack_gauge_container: HBoxContainer = $UpgradeDescriptionTextureRect/MarginContainer/UpgradeDescriptionVBoxContainer/Node/VBoxContainer/AspectRatioContainer2/AttackSpeedHBoxContainer
@onready var attack_speed_gauge_container: HBoxContainer = $UpgradeDescriptionTextureRect/MarginContainer/UpgradeDescriptionVBoxContainer/Node/VBoxContainer/AspectRatioContainer/AttackSpeedHBoxContainer
@onready var _panel: Control = $UpgradeDescriptionTextureRect

# Private variables
var _max_damage: float = 0.0
var _max_shoot_range: float = 0.0

# Core methods
func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos: Vector2 = get_global_mouse_position()
		if _panel == null or not _panel.get_global_rect().has_point(mouse_pos):
			queue_free()

## Initializes the upgrade description with tower and upgrade data
func setup(p_tower: ITower, upgrade_scene: PackedScene) -> void:
	tower = p_tower
	var upgrade: IUpgrade = upgrade_scene.instantiate()
	
	# Get tower name based on scene name
	var tower_name = _get_tower_name()
	
	# Set title and description
	#upgrade_title_label.text = tower_name
	
	# Calculate maximum stats for the current tower branch
	_calculate_max_stats(upgrade_scene)
	
	# Debug: Print stats
	# Get base bullet damage
	var bullet_base_damage = 0.0
	if tower.bullet_scene != null:
		var bullet_instance: IBullet = tower.bullet_scene.instantiate()
		bullet_base_damage = float(bullet_instance.damage)
		bullet_instance.queue_free()
	
	var current_damage = bullet_base_damage + tower.bullet_stats.get("damage", 0.0) + upgrade.bullet_stats.get("damage", 0.0)
	var current_range = tower.shoot_range + upgrade.tower_stats.get("shoot_range", 0.0)
	Log.trace(Log.Level.DEBUG, "Current Damage: %.1f / Max: %.1f" % [current_damage, _max_damage])
	Log.trace(Log.Level.DEBUG, "Current Range: %.1f / Max: %.1f" % [current_range, _max_shoot_range])
	
	# Update gauge bars based on current and future stats
	_update_damage_gauge(upgrade)
	_update_range_gauge(upgrade)
	
	upgrade.queue_free()

## Gets the tower name based on the tower's scene name and level
func _get_tower_name() -> String:
	# Get the scene path from the instance's owner scene
	var tower_scene_path: String = tower.scene_file_path
	
	# Extract the tower type from the path (e.g., "bat_01" from "res://scenes/.../bat_01.tscn")
	var scene_name: String = tower_scene_path.get_file().trim_suffix(".tscn").to_lower()
	
	# Map tower types to translation keys
	var tower_translation_keys = {
		"bat_01": "TOWER.BAT_01.NAME",
		"bat_02": "TOWER.BAT_02.NAME",
	}
	
	# Get the base name from translation or fallback
	var base_name: String = scene_name
	if tower_translation_keys.has(scene_name):
		var translation_key = tower_translation_keys[scene_name]
		base_name = tr(translation_key)
	
	# Add level info
	var level_display = tr("TOWER.LEVEL.DISPLAY")
	var full_name = level_display % [base_name, tower.level]
	
	return full_name

## Calculates the maximum stats available in the upgrade chain
func _calculate_max_stats(upgrade_scene: PackedScene) -> void:
	# Get base damage from tower's bullet_stats + bullet's base damage
	var bullet_base_damage = 0
	if tower.bullet_scene != null:
		var bullet_instance: IBullet = tower.bullet_scene.instantiate()
		bullet_base_damage = bullet_instance.damage
		bullet_instance.queue_free()
	
	_max_damage = tower.bullet_stats.get("damage", 0.0) + bullet_base_damage
	_max_shoot_range = tower.shoot_range
	
	# Recursively check all future upgrades to find max stats
	var upgrade: IUpgrade = upgrade_scene.instantiate()
	_find_max_stats_recursive(upgrade)
	upgrade.queue_free()

## Recursively finds maximum stats through the upgrade tree
func _find_max_stats_recursive(upgrade: IUpgrade) -> void:
	# Update max values based on current upgrade
	if upgrade.bullet_stats.has("damage"):
		var future_damage = tower.bullet_stats.get("damage", 0.0) + upgrade.bullet_stats["damage"]
		_max_damage = max(_max_damage, future_damage)
	
	if upgrade.tower_stats.has("shoot_range"):
		var future_range = tower.shoot_range + upgrade.tower_stats["shoot_range"]
		_max_shoot_range = max(_max_shoot_range, future_range)
	
	# Check all next upgrades
	for next_upgrade_scene in upgrade.next_upgrades:
		var next_upgrade: IUpgrade = next_upgrade_scene.instantiate()
		_find_max_stats_recursive(next_upgrade)
		next_upgrade.queue_free()

## Updates the damage gauge bar with colored squares
func _update_damage_gauge(upgrade: IUpgrade) -> void:
	# Get base bullet damage
	var bullet_base_damage = 0.0
	if tower.bullet_scene != null:
		var bullet_instance: IBullet = tower.bullet_scene.instantiate()
		bullet_base_damage = float(bullet_instance.damage)
		bullet_instance.queue_free()
	
	# Calculate total damage including tower upgrades and bullet damage
	var current_damage = bullet_base_damage + tower.bullet_stats.get("damage", 0.0) + upgrade.bullet_stats.get("damage", 0.0)
	_update_gauge_with_values(attack_gauge_container, current_damage, _max_damage, "%.0f / %.0f" % [current_damage, _max_damage])

## Updates the range gauge bar with colored squares
func _update_range_gauge(upgrade: IUpgrade) -> void:
	var current_range = tower.shoot_range + upgrade.tower_stats.get("shoot_range", 0.0)
	_update_gauge_with_values(attack_speed_gauge_container, current_range, _max_shoot_range, "%.0f / %.0f" % [current_range, _max_shoot_range])

## Calculates the percentage of stat progress (0.0 to 1.0)
func _calculate_percentage(current_value: float, max_value: float) -> float:
	if max_value <= 0:
		return 0.0
	return clamp(current_value / max_value, 0.0, 1.0)

## Updates gauge with current and max values displayed as text and dynamic gauge texture
func _update_gauge_with_values(container: HBoxContainer, current_value: float, max_value: float, label_text: String) -> void:
	var percentage := _calculate_percentage(current_value, max_value)

	# Determine gauge level (rounded to nearest quarter)
	var level := int(round(percentage * 4.0))
	level = clamp(level, 1, 4)

	# Find gauge bar (second TextureRect) and icon (first TextureRect)
	#var texture_rects: Array = []
	#for child in container.get_children():
		#if child is TextureRect:
			#texture_rects.append(child)
	
	#if texture_rects.size() >= 2:
		#var gauge_bar: TextureRect = texture_rects[1]
		#if GAUGE_TEXTURES.has(level):
			#gauge_bar.texture = GAUGE_TEXTURES[level]
	
	# Ensure a right-side label exists (and not stacked repeatedly)
	#for child in container.get_children():
		#if child is Label:
			#child.queue_free()
	
	var value_label := Label.new()
	value_label.text = label_text
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.custom_minimum_size = Vector2(60, 20)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.size_flags_horizontal = Control.SIZE_FILL
	value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Add label to the end of the HBox (after icon and gauge)
	#container.add_child(value_label)
