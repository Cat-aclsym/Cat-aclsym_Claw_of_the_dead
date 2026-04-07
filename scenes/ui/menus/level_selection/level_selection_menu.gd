## © [2024] A7 Studio. All rights reserved. Trademark.
## @experimental
class_name LevelSelectionMenu extends Control

signal level_selected

var level_statuses: Dictionary = {}
var level_frames: Array = []
var level_index: int = 0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var separator_scene: PackedScene = preload("res://scenes/ui/menus/level_selection/components/separator.tscn")
@onready var indicator_scene: PackedScene = preload("res://scenes/ui/menus/level_selection/components/level_indicator.tscn")

@onready var background_texture_rect: TextureRect = $BackgroundTextureRect

@onready var main_menu_button: TextureButton = $MarginContainer/MainMenuButton
@onready var arc_title_label: Label = $MarginContainer/VBoxContainer/CenterContainer/ArcTitleLabel

@onready var body_container: HBoxContainer = $MarginContainer/VBoxContainer/BodyContainer
@onready var previous_button: TextureButton = $MarginContainer/VBoxContainer/BodyContainer/PreviousButton
@onready var next_button: TextureButton = $MarginContainer/VBoxContainer/BodyContainer/NextButton
@onready var locked_frame: CenterContainer = $MarginContainer/VBoxContainer/BodyContainer/LockedFrame

@onready var indicators_container: HBoxContainer = $MarginContainer/VBoxContainer/VBoxContainer/IndicatorsContainer

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
	_update()
	SignalUtil.connects(signals)


# private
func _update() -> void:
	for level_frame in level_frames:
		level_frame.visible = false
	level_frames[level_index].visible = true

	if not level_frames[level_index] is LevelFrame:
		return

	if background_texture_rect.texture != level_frames[level_index].arc_texture:
		animation_player.play("dim_bg")
		arc_title_label.text = 	level_frames[level_index].arc_title

func _load_levels() -> void:
	var i := 1

	for child in body_container.get_children():
		if not child is LevelFrame:
			continue

		var status := LevelIndicator.Status.LOCKED
		if ProgressionManager.is_level_unlocked(child.level_id):
			var level_data: LevelData = ProgressionManager.data.levels[child.level_id]
			if not level_data.challenges_completed.is_empty():
				status = LevelIndicator.Status.COMPLETED
			else:
				status = LevelIndicator.Status.CURRENT

		level_statuses[child.level_id] = status

		level_frames.append(child)
		signals.append({SignalUtil.WHO: child, SignalUtil.WHAT: "start_level", SignalUtil.TO: _on_frame_start_level})

		var indicator: LevelIndicator = indicator_scene.instantiate()
		indicators_container.add_child(indicator)
		indicator.configure(i, status)
		signals.append({SignalUtil.WHO: indicator, SignalUtil.WHAT: "selected", SignalUtil.TO: _on_level_indicator_selected})

		var separator := separator_scene.instantiate()
		indicators_container.add_child(separator)

		if status == LevelIndicator.Status.CURRENT:
			level_index = i-1

		i += 1

	level_frames.append(locked_frame)
	indicators_container.get_children().back().queue_free()


# signal
func _on_frame_start_level(level: ILevel) -> void:
	visible = false

	add_child(level)
	level.reparent(get_tree().get_root())
	level.start_level()

	Global.ui.start_level()
	level_selected.emit()

	# free all other frames to save memory
	for frame in level_frames:
		if frame != locked_frame and frame != level_frames[level_index]:
			if frame is LevelFrame:
				frame.unload_level()
			frame.queue_free()


func _on_previous_button_pressed() -> void:
	if level_index > 0:
		level_index -= 1
	_update()


func _on_next_button_pressed() -> void:
	var i: int = (level_index + 1) if level_index + 1 < level_frames.size() else level_index

	if not level_frames[i] is LevelFrame:
		level_index = i
		_update()
		return

	var id = level_frames[i].level.level_id
	if level_statuses[id] == LevelIndicator.Status.LOCKED:
		return

	if level_index < level_frames.size() - 1:
		level_index += 1

	_update()


func _on_main_menu_button_button_pressed() -> void:
	get_parent().gui_margin_container.visible = true
	queue_free()


func _on_level_indicator_selected(indicator: LevelIndicator) -> void:
	level_index = indicator.level - 1
	_update()


func _on_dim_bg() -> void: # pas vraiment un signal mais un peu quand meme
	background_texture_rect.texture = level_frames[level_index].arc_texture
