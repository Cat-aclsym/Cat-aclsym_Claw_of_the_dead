## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Generic build-card used in the construction menu.
## Can represent any buildable entity (tower or trap) that exposes a `cost` property.
class_name BuildCard
extends Control

## The entity scene to instantiate when building (tower or trap).
@export var entity: PackedScene = null

var _cost: int = 0
var _entity: Node2D = null

## The container node for the card elements.
@onready var background_texture: TextureRect = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/BackgroundTextureRect
@onready var button_texture: TextureButton = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton
@onready var container: VBoxContainer = $CardVBoxContainer
@onready var price_label: Label = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/PriceLabel
@onready var title_label: Label = $CardVBoxContainer/TitleAspectRatioContainer/TitleTextureRect/TitleLabel
@onready var tower_texture: TextureRect = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/TowerTextureRect

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: button_texture, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_button_texture_pressed},
]

# core
func _ready() -> void:
	assert(entity != null, "entity scene not assigned")
	assert(background_texture != null, "background_texture node not found")
	assert(button_texture != null, "button_texture node not found")
	assert(container != null, "container node not found")
	assert(price_label != null, "price_label node not found")
	assert(title_label != null, "title_label node not found")
	assert(tower_texture != null, "tower_texture node not found")

	_entity = entity.instantiate() as Node2D
	assert(_entity != null, "entity could not be instantiated as Node2D")
	assert("cost" in _entity, "entity must expose a 'cost' property")
	_cost = int(_entity.cost)

	SignalUtil.connects(signals)

# public
## Updates the card display with current cost and availability.
## [br]Disables the build button if player doesn't have enough coins.
func update() -> void:
	price_label.text = "BUY {0}$".format([_cost])
	button_texture.disabled = ILevel.current_level.coins < _cost

# private
## Handles the build button press event.
## [br]Changes cursor state to build mode and closes the build menu.
func _on_button_texture_pressed() -> void:
	Global.cursor.change_state(Global.cursor.CursorState.BUILD, [_entity])
	var tower_selection := Global.ui.get_node_or_null("TowerSelection")
	if tower_selection:
		tower_selection.queue_free()

	var tower_selection_button: BaseButton = Global.hud.get_node_or_null("TowerSelectionMarginContainer/TowerSelectionButton")
	if tower_selection_button:
		tower_selection_button.set_pressed_no_signal(false)
