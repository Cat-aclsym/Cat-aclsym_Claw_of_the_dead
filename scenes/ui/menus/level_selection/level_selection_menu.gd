## © [2026] A7 Studio. All rights reserved. Trademark.
class_name LevelSelectionMenu extends Control

signal level_selected

var level_statuses: Dictionary[String, LevelIndicator.Status] = {}
var level_frames: Array[LevelFrame] = []
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


func _ready() -> void:
	configure()


func configure() -> void:
	_load_levels()
	_update()
	SignalUtil.connects(signals)

	ButtonEffects.apply(previous_button)
	ButtonEffects.apply(next_button)
	ButtonEffects.apply(main_menu_button)


func _update() -> void:
	for level_frame in level_frames:
		level_frame.visible = false
	locked_frame.visible = false

	if level_frames.is_empty():
		return

	var has_locked_frame: bool = is_instance_valid(locked_frame)
	var is_locked_selection: bool = has_locked_frame and level_index == level_frames.size()
	if is_locked_selection:
		locked_frame.visible = true
		return

	if level_index < 0 or level_index >= level_frames.size():
		return

	var current_frame: LevelFrame = level_frames[level_index]
	current_frame.visible = true

	if background_texture_rect.texture != current_frame.arc_texture:
		animation_player.play("dim_bg")
		arc_title_label.text = current_frame.arc_title

func _load_levels() -> void:
	var i := 1

	for child: Node in body_container.get_children():
		if not child is LevelFrame:
			continue

		var level_frame: LevelFrame = child as LevelFrame
		var status := LevelIndicator.Status.LOCKED
		if ProgressionManager.is_level_unlocked(level_frame.level_id):
			var level_data: LevelData = ProgressionManager.data.levels[level_frame.level_id]
			if not level_data.challenges_completed.is_empty():
				status = LevelIndicator.Status.COMPLETED
			else:
				status = LevelIndicator.Status.CURRENT

		level_statuses[level_frame.level_id] = status

		level_frames.append(level_frame)
		signals.append({SignalUtil.WHO: level_frame, SignalUtil.WHAT: "start_level", SignalUtil.TO: _on_frame_start_level})

		var indicator := indicator_scene.instantiate() as LevelIndicator
		indicators_container.add_child(indicator)
		indicator.configure(i, status)
		signals.append({SignalUtil.WHO: indicator, SignalUtil.WHAT: "selected", SignalUtil.TO: _on_level_indicator_selected})

		var separator := separator_scene.instantiate() as Control
		indicators_container.add_child(separator)

		if status == LevelIndicator.Status.CURRENT:
			level_index = i - 1

		i += 1

	if not indicators_container.get_children().is_empty():
		indicators_container.get_children().back().queue_free()


func _on_frame_start_level(level: ILevel) -> void:
	visible = false

	add_child(level)
	level.reparent(get_tree().get_root())
	level.start_level()

	Global.ui.start_level()
	level_selected.emit()

	## Frees inactive level previews once gameplay starts.
	for frame in level_frames:
		if frame != level_frames[level_index]:
			if frame is LevelFrame:
				frame.unload_level()
		frame.queue_free()

	if is_instance_valid(locked_frame):
		locked_frame.queue_free()


func _on_previous_button_pressed() -> void:
	if level_index > 0:
		level_index -= 1
	_update()


func _on_next_button_pressed() -> void:
	var max_index: int = level_frames.size()
	if not is_instance_valid(locked_frame):
		max_index = max(0, level_frames.size() - 1)

	var next_index: int = min(level_index + 1, max_index)
	if next_index == level_index:
		return

	if next_index < level_frames.size():
		var next_id: String = level_frames[next_index].level_id
		if level_statuses.get(next_id, LevelIndicator.Status.LOCKED) == LevelIndicator.Status.LOCKED:
			return

	level_index = next_index

	_update()


func _on_main_menu_button_button_pressed() -> void:
	get_parent().gui_margin_container.visible = true
	queue_free()


func _on_level_indicator_selected(indicator: LevelIndicator) -> void:
	level_index = indicator.level - 1
	_update()


func _on_dim_bg() -> void:
	if level_index < 0 or level_index >= level_frames.size():
		return
	background_texture_rect.texture = level_frames[level_index].arc_texture
