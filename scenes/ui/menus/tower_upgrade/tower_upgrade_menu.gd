class_name TowerUpgradeMenu
extends Control

var sell_price: int
var tower: ITower
var upgrade_price: int

@onready var close_button: TextureButton = $VBoxContainer/CloseAspectRatioContainer/CloseTextureButton
@onready var sell_button: TextureButton = $VBoxContainer/HBoxContainer/SellAspectRatioContainer/SellTextureButton
@onready var sell_label: Label = $VBoxContainer/HBoxContainer/SellAspectRatioContainer/SellLabel
@onready var upgrade_button: TextureButton = $VBoxContainer/HBoxContainer/UpgradeAspectRatioContainer/UpgradeTextureButton
@onready var upgrade_label: Label = $VBoxContainer/HBoxContainer/UpgradeAspectRatioContainer/UpgradeLabel

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_button_pressed},
	{SignalUtil.WHO: upgrade_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_upgrade_button_pressed},
	{SignalUtil.WHO: sell_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_sell_button_pressed}
]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tower = get_parent() as ITower
	sell_price = tower.sell_price
	sell_label.text = str(sell_price)+"$"
	if !tower.available_upgrade.is_empty():
		var upg: IUpgrade = tower.available_upgrade[0].instantiate()
		upgrade_price = upg.price
		upgrade_label.text = str(upgrade_price)+"$"
	else:
		upgrade_button.disabled = true
		# Change upgrade button to gray rbg #525252
		upgrade_button.modulate = Color(0.325, 0.325, 0.325)  # Gray color
		upgrade_label.text = "MAX"
	
	# Connect to level stats updates to refresh button state when coins change
	if ILevel.current_level:
		ILevel.current_level.stats_updated.connect(_on_level_stats_updated)
	
	# Update button state initially
	_update_upgrade_button_state()
	
	SignalUtil.connects(signals)


## Updates the visual state of the upgrade button based on available coins
func _update_upgrade_button_state() -> void:
	# Only check money if there's an upgrade available
	if tower.available_upgrade.is_empty():
		return
	
	var can_afford: bool = ILevel.current_level.coins >= upgrade_price
	
	if can_afford:
		upgrade_button.modulate = Color(1.0, 1.0, 1.0)  # White (enabled)
		upgrade_button.disabled = false
	else:
		upgrade_button.modulate = Color(0.325, 0.325, 0.325)  # Gray (disabled)
		upgrade_button.disabled = true


func _on_close_button_pressed():
	# Disconnect from level stats when closing
	if ILevel.current_level and ILevel.current_level.stats_updated.is_connected(_on_level_stats_updated):
		ILevel.current_level.stats_updated.disconnect(_on_level_stats_updated)
	queue_free()


func _on_level_stats_updated() -> void:
	_update_upgrade_button_state()


func _on_sell_button_pressed():
	tower.sell_tower()
	queue_free()


func _on_upgrade_button_pressed():
	tower.start_upgrade(tower.available_upgrade[0])
	_on_close_button_pressed()
