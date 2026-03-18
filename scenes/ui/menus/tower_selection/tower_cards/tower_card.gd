## © [2025] A7 Studio. All rights reserved. Trademark.
##
## Manages a tower card UI element in the HUD.
## Handles tower selection, cost display, and building functionality.
class_name TowerCard
extends Control

## The tower scene to instantiate when building.
@export var tower: PackedScene = null

var _tower: ITower = null
var _cost: int

## The container node for the card elements.
@onready var container: VBoxContainer = $CardVBoxContainer
@onready var title_label: Label = $CardVBoxContainer/TitleAspectRatioContainer/TitleTextureRect/TitleLabel
@onready var button_texture : TextureButton = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton
@onready var tower_texture: TextureRect = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/TowerTextureRect
@onready var background_texture: TextureRect = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/BackgroundTextureRect
@onready var price_label: Label = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/PriceLabel

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: button_texture, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_button_texture_pressed},
]

# core
func _ready() -> void:
	assert(tower != null, "tower scene not assigned")
	assert(container != null, "container node not found")
	assert(title_label != null, "title_label node not found")
	assert(button_texture != null, "button_texture node not found")
	assert(tower_texture != null, "tower_texture node not found")
	assert(background_texture != null, "border_texture node not found")
	assert(price_label != null, "price_label node not found")

	_tower = tower.instantiate()
	_cost = _tower.cost
	SignalUtil.connects(signals)

# public
## Updates the tower card display with current cost and availability.
## [br]Disables the build button if player doesn't have enough coins.
func update() -> void:
	price_label.text = "BUY {0}$".format([_cost])
	button_texture.disabled = ILevel.current_level.coins < _cost

# private
## Handles the build button press event.
## [br]Changes cursor state to build mode and toggles the build menu.
func _on_button_texture_pressed() -> void:
	Global.cursor.change_state(Global.cursor.CursorState.BUILD, [_tower])
	Global.ui.get_node("TowerSelection").queue_free()
	Global.hud.get_node("TowerSelectionMarginContainer/TowerSelectionButton").set_pressed_no_signal(false)
