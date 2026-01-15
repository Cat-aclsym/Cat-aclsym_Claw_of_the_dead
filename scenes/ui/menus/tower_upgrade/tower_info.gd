## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the display of tower info statistics with dynamic gauge bars.
class_name TowerInfo
extends Control

## Reference to the tower being upgraded
var tower: ITower

@onready var _panel: Control = $UpgradeDescriptionTextureRect
@onready var _stats_container: VBoxContainer = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/VBoxContainer
@onready var _stats_db: Node = get_node("/root/StatsDB")
@onready var _upgrade_title_label: Label = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/UpgradeTitleLabel

# Preloaded resources
const ICON_TEXTURE: Texture2D = preload("res://assets/ui/icons/Icon Attack.svg")
const STAT_BAR_SCENE: PackedScene = preload("res://scenes/ui/menus/tower_upgrade/stat_bar.tscn")

# Constants
const MAX_STAT_VALUE: float = 200.0

# Core methods
func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos: Vector2 = get_global_mouse_position()
		if _panel == null or not _panel.get_global_rect().has_point(mouse_pos):
			queue_free()

## Initializes the info display with tower data
func setup(p_tower: ITower, _upgrade_scene: PackedScene = null) -> void:
	tower = p_tower
	
	# Get tower name based on scene name
	var tower_name = _get_tower_name()
	
	# Set title and description
	_upgrade_title_label.text = tower_name
	
	# Clear existing stat displays
	for child in _stats_container.get_children():
		child.queue_free()
	
	# Display all current tower stats (excluding level)
	_display_tower_stat("fire_rate")
	_display_tower_stat("shoot_range")
	_display_tower_stat("projectile_count")
	_display_tower_stat("spread_angle")
	
	# Display all current bullet stats
	_display_bullet_stat("damage")
	_display_bullet_stat("speed")
	_display_bullet_stat("pierce_count")
	_display_bullet_stat("pierce_reduction")
	_display_bullet_stat("aoe_range")
	_display_bullet_stat("aoe_duration")
	_display_bullet_stat("aoe_tick")
	_display_bullet_stat("damage_multiplier")
	_display_bullet_stat("dot_damage")

## Gets the tower name based on the tower's scene name and level
func _get_tower_name() -> String:
	var tower_id: String = tower.tower_id if tower != null else ""
	var base_name: String = ""
	if _stats_db != null and not tower_id.is_empty():
		base_name = _stats_db.get_tower_name(tower_id)
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

## Displays a tower stat if it's not zero
func _display_tower_stat(stat_name: String) -> void:
	if stat_name in tower:
		var value = tower.get(stat_name)
		var float_value: float = float(value) if value != null else 0.0
		
		# Exception: don't show projectile_count if it's 1 (single arrow)
		if stat_name == "projectile_count" and float_value <= 1.0:
			return
		
		if float_value != 0.0:
			_create_stat_display(stat_name, float_value)

## Displays a bullet stat if it's not zero
func _display_bullet_stat(stat_name: String) -> void:
	var value: float = 0.0
	
	if stat_name == "damage":
		var base_damage: float = 0.0
		if tower.bullet_scene != null:
			var bullet_instance: IBullet = tower.bullet_scene.instantiate()
			base_damage = float(bullet_instance.damage)
			bullet_instance.queue_free()
		value = base_damage + tower.bullet_stats.get("damage", 0.0)
	else:
		value = tower.bullet_stats.get(stat_name, 0.0)
	
	if value != 0.0:
		_create_stat_display(stat_name, value)

## Creates a stat display for a given stat
func _create_stat_display(stat_name: String, current_value: float) -> void:
	# Instantiate the stat bar scene
	var stat_bar: StatBar = STAT_BAR_SCENE.instantiate()
	_stats_container.add_child(stat_bar)
	
	# Setup the stat bar with data (current value displayed, no "new" value for info display)
	stat_bar.setup(stat_name, 0.0, current_value, ICON_TEXTURE, MAX_STAT_VALUE)
