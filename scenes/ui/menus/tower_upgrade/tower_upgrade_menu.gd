## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the display of tower upgrade statistics with dynamic gauge bars.
class_name TowerUpgradeMenu
extends Control

## Reference to the tower being upgraded
var tower: ITower
var upgrade_scene: PackedScene
var _upgrades: Array[PackedScene] = []
var _current_upgrade_index: int = 0

@onready var _cancel_button: TextureButton = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/ButtonsHBoxContainer/CancelButton
@onready var _cancel_label: Label = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/ButtonsHBoxContainer/CancelButton/Label
@onready var _confirm_button: TextureButton = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/ButtonsHBoxContainer/ConfirmButton
@onready var _confirm_label: Label = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/ButtonsHBoxContainer/ConfirmButton/Label
@onready var _panel: Control = $UpgradeDescriptionTextureRect
@onready var _stats_container: VBoxContainer = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/StatsScrollContainer/VBoxContainer
@onready var _stats_scroll: ScrollContainer = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/StatsScrollContainer
@onready var _upgrade_title_label: Label = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/UpgradeTitleLabel
@onready var _tabs_container: HBoxContainer = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/TabsHBoxContainer
@onready var _option1_button: Button = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/TabsHBoxContainer/UpgradeOption1Button
@onready var _option2_button: Button = $UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/TabsHBoxContainer/UpgradeOption2Button

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: _cancel_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_cancel_button_pressed},
	{SignalUtil.WHO: _confirm_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_confirm_button_pressed},
	{SignalUtil.WHO: _option1_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_option1_button_pressed},
	{SignalUtil.WHO: _option2_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_option2_button_pressed}
]

# Preloaded resources
const ICON_TEXTURE: Texture2D = preload("res://assets/ui/icons/Icon Attack.svg")
const STAT_BAR_SCENE: PackedScene = preload("res://scenes/ui/menus/tower_upgrade/stat_bar.tscn")

# Constants
const MAX_STAT_VALUE: float = 200.0

# Core methods
func _ready() -> void:
	SignalUtil.connects(signals)
	Global.paused = true
	if ILevel.current_level != null:
		ILevel.current_level.request_pause()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos: Vector2 = get_global_mouse_position()
		if _panel == null or not _panel.get_global_rect().has_point(mouse_pos):
			queue_free()


func _unhandled_input(event: InputEvent) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var inside_panel: bool = _panel != null and _panel.get_global_rect().has_point(mouse_pos)
	if inside_panel and (event is InputEventMouseButton or (event is InputEventMouseMotion and event.button_mask != 0)):
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	Global.paused = false
	if ILevel.current_level != null:
		ILevel.current_level.request_resume()

## Initializes the upgrade description with tower and one or more upgrade options
func setup(p_tower: ITower, p_upgrades: Array[PackedScene]) -> void:
	tower = p_tower
	_upgrades = p_upgrades.duplicate()
	_current_upgrade_index = 0
	_update_tabs_visibility()
	_refresh_upgrade_view()


func _refresh_upgrade_view() -> void:
	if _upgrades.is_empty():
		queue_free()
		return

	_current_upgrade_index = clamp(_current_upgrade_index, 0, _upgrades.size() - 1)
	upgrade_scene = _upgrades[_current_upgrade_index]

	var upgrade: IUpgrade = upgrade_scene.instantiate()

	# Set title and confirm price
	_confirm_label.text = tr("TOWER.UPGRADE.PRICE") % upgrade.price
	_upgrade_title_label.text = _get_upgrade_title(upgrade)
	_set_active_tab_button(_current_upgrade_index)

	# Check if player has enough money
	if ILevel.current_level != null and ILevel.current_level.coins < upgrade.price:
		_confirm_button.disabled = true
		_confirm_button.modulate = Color(0.5, 0.5, 0.5)  # Gray out the button
	else:
		_confirm_button.disabled = false
		_confirm_button.modulate = Color(1.0, 1.0, 1.0)  # Normal color

	# Clear existing stat displays
	for child in _stats_container.get_children():
		child.queue_free()

	var displayed_stats: int = 0

	# Create dynamic stat displays for tower stats
	for stat_name in upgrade.tower_stats.keys():
		var stat_change: float = upgrade.tower_stats[stat_name]

		# Skip level stat
		if stat_name == "level":
			continue

		# Skip projectile_count if resulting value would be 1 or less
		if stat_name == "projectile_count":
			var current_value: float = _get_current_stat_value(stat_name, true)
			var new_value: float = current_value + stat_change
			if new_value <= 1.0:
				continue

		if stat_change != 0.0:
			_create_stat_display(stat_name, stat_change, true)
			displayed_stats += 1

	# Create dynamic stat displays for bullet stats
	for stat_name in upgrade.bullet_stats.keys():
		var stat_change: float = upgrade.bullet_stats[stat_name]
		if stat_change != 0.0:
			_create_stat_display(stat_name, stat_change, false)
			displayed_stats += 1

	_update_scroll_mode(displayed_stats)

	upgrade.queue_free()

## Gets the upgrade title based on the current tower level and upgrade data
func _get_upgrade_title(upgrade: IUpgrade) -> String:
	var delta_level: int = 1
	if upgrade != null and upgrade.tower_stats.has("level"):
		delta_level = int(upgrade.tower_stats["level"])

	var next_level: int = delta_level
	if tower != null:
		next_level = tower.level + delta_level

	return tr("TOWER.UPGRADE.TITLE") % next_level

## Creates a stat display for a given stat
func _create_stat_display(stat_name: String, stat_change: float, is_tower_stat: bool) -> void:
	# Get current and new values
	var current_value: float = _get_current_stat_value(stat_name, is_tower_stat)
	var new_value: float = current_value + stat_change

	# Instantiate the stat bar scene
	var stat_bar: StatBar = STAT_BAR_SCENE.instantiate()
	_stats_container.add_child(stat_bar)

	# Setup the stat bar with data
	stat_bar.setup(stat_name, current_value, new_value, ICON_TEXTURE, MAX_STAT_VALUE, true)

## Gets the current value of a stat
func _get_current_stat_value(stat_name: String, is_tower_stat: bool) -> float:
	if is_tower_stat:
		# Tower stats
		if stat_name in tower:
			var value = tower.get(stat_name)
			return float(value) if value != null else 0.0
	else:
		# Bullet stats
		if stat_name == "damage":
			var base_damage: float = 0.0
			if tower.bullet_scene != null:
				var bullet_instance: IBullet = tower.bullet_scene.instantiate()
				base_damage = float(bullet_instance.damage)
				bullet_instance.queue_free()
			return base_damage + tower.bullet_stats.get("damage", 0.0)
		else:
			return tower.bullet_stats.get(stat_name, 0.0)

	return 0.0

# Signal handlers
func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_confirm_button_pressed() -> void:
	if tower != null and upgrade_scene != null:
		tower.start_upgrade(upgrade_scene)
	queue_free()


func _update_tabs_visibility() -> void:
	var count: int = _upgrades.size()
	if _tabs_container == null:
		return
	_tabs_container.visible = count > 1
	_option1_button.visible = count >= 1
	_option2_button.visible = count >= 2


func _set_active_tab_button(index: int) -> void:
	if _tabs_container == null:
		return
	_option1_button.button_pressed = index == 0
	_option2_button.button_pressed = index == 1


func _on_option1_button_pressed() -> void:
	_current_upgrade_index = 0
	_refresh_upgrade_view()


func _on_option2_button_pressed() -> void:
	if _upgrades.size() < 2:
		return
	_current_upgrade_index = 1
	_refresh_upgrade_view()


func _update_scroll_mode(displayed_stats: int) -> void:
	if _stats_scroll == null:
		return
	if displayed_stats > 2:
		_stats_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	else:
		_stats_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
