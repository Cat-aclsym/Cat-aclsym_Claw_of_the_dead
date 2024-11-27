## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages a trap card UI element in the HUD.
## Handles trap selection, cost display, and building functionality.
class_name TrapCard
extends MarginContainer

signal pressed

## The trap scene to instantiate when building.
@export var trap: PackedScene = null
@export var trap_name: String = ""
@export var trap_cost: int = 0

var _trap: ITrap = null
var _cost: int

## The container node for the card elements.
@onready var container: VBoxContainer = $VBoxContainer
@onready var title_label: Label = $VBoxContainer/Label
@onready var texture: TextureRect = $VBoxContainer/TextureRect
@onready var build_button: TextureButton = $VBoxContainer/Button
@onready var text_price: Label = $VBoxContainer/Button/Label

# core
func _ready() -> void:
	assert(trap != null, "trap scene not assigned")
	assert(container != null, "container node not found")
	assert(title_label != null, "title_label node not found")
	assert(texture != null, "texture node not found")
	assert(build_button != null, "build_button node not found")
	assert(text_price != null, "text_price node not found")

	_cost = trap_cost

	if trap:
		var instance = trap.instantiate()
		_trap = instance
		$VBoxContainer/Label.text = trap_name
		$VBoxContainer/Button/Label.text = str(instance.cost) + "$"
		instance.queue_free()

# public
## Updates the trap card display with current cost and availability.
## [br]Disables the build button if player doesn't have enough coins.
func update() -> void:
	text_price.text = "BUY {0}$".format([_cost])
	build_button.disabled = ILevel.current_level.coins < _cost

# private
## Handles the build button press event.
## [br]Changes cursor state to build mode and toggles the build menu.
func _on_button_pressed() -> void:
	pressed.emit()
	if Global.hud:
		if Global.cursor:
			var instance = trap.instantiate()
			Global.cursor.change_state(TowerPlacement.CursorState.BUILD, [instance])
		Global.hud.toggle_build_menu() 