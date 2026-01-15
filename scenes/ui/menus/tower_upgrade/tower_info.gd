## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the display of tower upgrade statistics with dynamic gauge bars.
class_name TowerUpgradeDescription
extends Control

## Reference to the tower being upgraded
var tower: ITower

@onready var attack_progress_bar: TextureProgressBar = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/VBoxContainer/AspectRatioContainer2/AttackSpeedHBoxContainer/TextureProgressBar
@onready var attack_range_progress_bar: TextureProgressBar = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/VBoxContainer/AspectRatioContainer3/AttackRangeHBoxContainer/TextureProgressBar
@onready var attack_speed_progress_bar: TextureProgressBar = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/VBoxContainer/AspectRatioContainer/AttackSpeedHBoxContainer/TextureProgressBar
@onready var stats_db: Node = get_node("/root/StatsDB")
@onready var upgrade_title_label: Label = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/UpgradeTitleLabel
@onready var _panel: Control = $UpgradeDescriptionTextureRect

# Private variables
var _max_damage: float = 0.0
var _max_fire_rate: float = 0.0
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
	upgrade_title_label.text = tower_name
	
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
	var current_fire_rate = tower.fire_rate + upgrade.tower_stats.get("fire_rate", 0.0)
	var current_range = tower.shoot_range + upgrade.tower_stats.get("shoot_range", 0.0)
	Log.trace(Log.Level.DEBUG, "Current Damage: %.1f / Max: %.1f" % [current_damage, _max_damage])
	Log.trace(Log.Level.DEBUG, "Current Fire Rate: %.2f / Max: %.2f" % [current_fire_rate, _max_fire_rate])
	Log.trace(Log.Level.DEBUG, "Current Range: %.1f / Max: %.1f" % [current_range, _max_shoot_range])
	
	# Update gauge bars based on current and future stats
	_update_damage_gauge(upgrade)
	_update_fire_rate_gauge(upgrade)
	_update_range_gauge(upgrade)
	
	upgrade.queue_free()

## Gets the tower name based on the tower's scene name and level
func _get_tower_name() -> String:
	var tower_id: String = tower.tower_id if tower != null else ""
	var base_name: String = ""
	if stats_db != null and not tower_id.is_empty():
		base_name = stats_db.get_tower_name(tower_id)
	if base_name.is_empty():
		base_name = _get_fallback_tower_name()
	var level_display: String = tr("TOWER.LEVEL.DISPLAY")
	return level_display % [tr(base_name), tower.level]


func _get_fallback_tower_name() -> String:
	var tower_scene_path: String = tower.scene_file_path if tower != null else ""
	var scene_name: String = tower_scene_path.get_file().trim_suffix(".tscn").to_lower()
	var tower_translation_keys: Dictionary = {
		"bat_01": "TOWER.BAT_01.NAME",
		"bat_02": "TOWER.BAT_02.NAME",
	}
	return tower_translation_keys.get(scene_name, scene_name)

## Calculates the maximum stats available in the upgrade chain
func _calculate_max_stats(_upgrade_scene: PackedScene) -> void:
	_max_damage = attack_progress_bar.max_value
	_max_fire_rate = attack_speed_progress_bar.max_value
	_max_shoot_range = attack_range_progress_bar.max_value

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
	_update_gauge_with_values(attack_progress_bar, current_damage, _max_damage, "%.0f / %.0f" % [current_damage, _max_damage])

## Updates the fire rate gauge bar with colored squares
func _update_fire_rate_gauge(upgrade: IUpgrade) -> void:
	var current_fire_rate = tower.fire_rate + upgrade.tower_stats.get("fire_rate", 0.0)
	_update_gauge_with_values(attack_speed_progress_bar, current_fire_rate, _max_fire_rate, "%.2f / %.2f" % [current_fire_rate, _max_fire_rate])

## Updates the range gauge bar with colored squares
func _update_range_gauge(upgrade: IUpgrade) -> void:
	var current_range = tower.shoot_range + upgrade.tower_stats.get("shoot_range", 0.0)
	_update_gauge_with_values(attack_range_progress_bar, current_range, _max_shoot_range, "%.0f / %.0f" % [current_range, _max_shoot_range])

## Updates gauge with current and max values displayed as text and dynamic gauge texture
func _update_gauge_with_values(progress_bar: TextureProgressBar, current_value: float, max_value: float, label_text: String) -> void:
	var bar_range: float = max(progress_bar.max_value - progress_bar.min_value, 1.0)
	var normalized: float = 0.0
	if max_value > 0.0:
		normalized = clamp(current_value / max_value, 0.0, 1.0)
	progress_bar.value = progress_bar.min_value + (bar_range * normalized)
	progress_bar.tooltip_text = label_text
