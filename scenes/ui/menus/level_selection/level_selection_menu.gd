## © [2024] A7 Studio. All rights reserved. Trademark.
class_name LevelSelectionMenu extends Control

signal level_selected

var level_frames: Array[LevelFrame] = []
var level_index: int = 0

@onready var separator_scene: PackedScene = preload("res://scenes/ui/menus/level_selection/components/separator.tscn")
@onready var indicator_scene: PackedScene = preload("res://scenes/ui/menus/level_selection/components/level_frame.tscn")

@onready var background_texture_rect: TextureRect = $BackgroundTextureRect

@onready var main_menu_button: TextureButton = $MarginContainer/VBoxContainer/HeaderContainer/MainMenuButton

@onready var body_container: HBoxContainer = $MarginContainer/VBoxContainer/BodyContainer
@onready var previous_button: TextureButton = $MarginContainer/VBoxContainer/BodyContainer/LeftCenterContainer/PreviousButton
@onready var next_button: TextureButton = $MarginContainer/VBoxContainer/BodyContainer/RightCenterContainer/NextButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: previous_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_previous_button_pressed},
	{SignalUtil.WHO: next_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_next_button_pressed},
	{SignalUtil.WHO: main_menu_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_main_menu_button_button_pressed}
]

# core
func _ready() -> void:
	configure()


# public
func configure() -> void:
	_load_levels()
	SignalUtil.connects(signals)


# private
func _update() -> void:
	level_frames[level_index].visible = true
	background_texture_rect.texture = level_frames[level_index].arc_texture

func _load_levels() -> void:
	for child in body_container.get_children():
		if not child is LevelFrame:
			continue
		level_frames.append(child)
		signals.append({
			SignalUtil.WHO: child, 
			SignalUtil.WHAT: "start_level", 
			SignalUtil.TO: _on_frame_start_level
		})


# signal
func _on_frame_start_level(level: ILevel) -> void:
	visible = false

	add_child(level)
	level.reparent(get_tree().get_root())
	level.start_level()

	Global.ui.start_level()
	level_selected.emit()


func _on_previous_button_pressed() -> void:
	level_frames[level_index].visible = false
	if level_index > 0:
		level_index -= 1
	_update()


func _on_next_button_pressed() -> void:
	level_frames[level_index].visible = false
	if level_index < level_frames.size() - 1:
		level_index += 1
	_update()


func _on_main_menu_button_button_pressed() -> void:
	get_parent().gui_margin_container.visible = true
	queue_free()

# event


# setget
