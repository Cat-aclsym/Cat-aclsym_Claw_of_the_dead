class_name TowerCard
extends MarginContainer

@export var tower: PackedScene = null

var _tower: ITower = null
var _cost: int

@onready var container: VBoxContainer = $VBoxContainer
@onready var title_label: Label = $VBoxContainer/Label
@onready var texture: TextureRect = $VBoxContainer/TextureRect
@onready var build_button: TextureButton = $VBoxContainer/Button
@onready var text_price: Label = $VBoxContainer/Button/Label


func _ready() -> void:
	_tower = tower.instantiate()
	_cost = _tower.cost


func update() -> void:
	text_price.text = "BUY {0}$".format([_cost])
	build_button.disabled = ILevel.current_level.coins < _cost


func _on_button_pressed() -> void:
	Global.cursor.change_state(Global.cursor.CURSOR_STATE.BUILD, [_tower])
	Global.ig_menu.toggle_build_menu()
