## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the display of tower upgrade statistics with dynamic gauge bars.
class_name TowerUpgradeMenu
extends Control

## Reference to the tower being upgraded
var tower: ITower
var upgrade_scene: PackedScene

@onready var _attack_damage_container: Control = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/VBoxContainer/AspectRatioContainer2
@onready var _attack_damage_progress_bar: TextureProgressBar = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/VBoxContainer/AspectRatioContainer2/AttackSpeedHBoxContainer/TextureProgressBar
@onready var _attack_range_container: Control = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/VBoxContainer/AspectRatioContainer3
@onready var _attack_range_progress_bar: TextureProgressBar = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/VBoxContainer/AspectRatioContainer3/AttackRangeHBoxContainer/TextureProgressBar
@onready var _attack_speed_container: Control = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/VBoxContainer/AspectRatioContainer
@onready var _attack_speed_progress_bar: TextureProgressBar = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/VBoxContainer/AspectRatioContainer/AttackSpeedHBoxContainer/TextureProgressBar
@onready var _cancel_button: Button = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/ButtonsHBoxContainer/CancelButton
@onready var _confirm_button: Button = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/ButtonsHBoxContainer/ConfirmButton
@onready var _panel: Control = $UpgradeDescriptionTextureRect
@onready var _upgrade_title_label: Label = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/UpgradeTitleLabel

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: _cancel_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_cancel_button_pressed},
	{SignalUtil.WHO: _confirm_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_confirm_button_pressed}
]

# Private variables
var _max_damage: float = 0.0
var _max_fire_rate: float = 0.0
var _max_shoot_range: float = 0.0

# Core methods
func _ready() -> void:
	SignalUtil.connects(signals)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos: Vector2 = get_global_mouse_position()
		if _panel == null or not _panel.get_global_rect().has_point(mouse_pos):
			queue_free()

## Initializes the upgrade description with tower and upgrade data
func setup(p_tower: ITower, p_upgrade_scene: PackedScene) -> void:
	tower = p_tower
	upgrade_scene = p_upgrade_scene
	var upgrade: IUpgrade = upgrade_scene.instantiate()
	
	# Set title and confirm price
	_confirm_button.text = "Confirmer - %d" % upgrade.price
	_upgrade_title_label.text = _get_upgrade_title()
	
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

## Gets the upgrade title based on the current tower level
func _get_upgrade_title() -> String:
	var next_level: int = 1
	if tower != null:
		next_level = tower.level + 1
	return "Améliorer au niveau %d" % next_level


## Calculates the maximum stats available in the upgrade chain
func _calculate_max_stats(_upgrade_scene: PackedScene) -> void:
	_max_damage = _attack_damage_progress_bar.max_value
	_max_fire_rate = _attack_speed_progress_bar.max_value
	_max_shoot_range = _attack_range_progress_bar.max_value

## Updates the damage gauge bar with colored squares
func _update_damage_gauge(upgrade: IUpgrade) -> void:
	_attack_damage_container.visible = upgrade.bullet_stats.get("damage", 0.0) != 0.0
	if not _attack_damage_container.visible:
		return

	# Get base bullet damage
	var bullet_base_damage = 0.0
	if tower.bullet_scene != null:
		var bullet_instance: IBullet = tower.bullet_scene.instantiate()
		bullet_base_damage = float(bullet_instance.damage)
		bullet_instance.queue_free()
	
	# Calculate total damage including tower upgrades and bullet damage
	var current_damage = bullet_base_damage + tower.bullet_stats.get("damage", 0.0) + upgrade.bullet_stats.get("damage", 0.0)
	_update_gauge_with_values(_attack_damage_progress_bar, current_damage, _max_damage, "%.0f / %.0f" % [current_damage, _max_damage])

## Updates the fire rate gauge bar with colored squares
func _update_fire_rate_gauge(upgrade: IUpgrade) -> void:
	_attack_speed_container.visible = upgrade.tower_stats.get("fire_rate", 0.0) != 0.0
	if not _attack_speed_container.visible:
		return

	var current_fire_rate = tower.fire_rate + upgrade.tower_stats.get("fire_rate", 0.0)
	_update_gauge_with_values(_attack_speed_progress_bar, current_fire_rate, _max_fire_rate, "%.2f / %.2f" % [current_fire_rate, _max_fire_rate])

## Updates the range gauge bar with colored squares
func _update_range_gauge(upgrade: IUpgrade) -> void:
	_attack_range_container.visible = upgrade.tower_stats.get("shoot_range", 0.0) != 0.0
	if not _attack_range_container.visible:
		return

	var current_range = tower.shoot_range + upgrade.tower_stats.get("shoot_range", 0.0)
	_update_gauge_with_values(_attack_range_progress_bar, current_range, _max_shoot_range, "%.0f / %.0f" % [current_range, _max_shoot_range])

## Updates gauge with current and max values displayed as text and dynamic gauge texture
func _update_gauge_with_values(progress_bar: TextureProgressBar, current_value: float, max_value: float, label_text: String) -> void:
	var bar_range: float = max(progress_bar.max_value - progress_bar.min_value, 1.0)
	var normalized: float = 0.0
	if max_value > 0.0:
		normalized = clamp(current_value / max_value, 0.0, 1.0)
	progress_bar.value = progress_bar.min_value + (bar_range * normalized)
	progress_bar.tooltip_text = label_text

# Signal handlers
func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_confirm_button_pressed() -> void:
	if tower != null and upgrade_scene != null:
		tower.start_upgrade(upgrade_scene)
	queue_free()
