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

	level_statuses = _load_level_statuses()

	for child in body_container.get_children():
		if not child is LevelFrame:
			continue
		level_frames.append(child)
		signals.append({SignalUtil.WHO: child, SignalUtil.WHAT: "start_level", SignalUtil.TO: _on_frame_start_level})

		var indicator: LevelIndicator = indicator_scene.instantiate()
		indicators_container.add_child(indicator)
		indicator.configure(i, level_statuses[child.level_id])
		signals.append({SignalUtil.WHO: indicator, SignalUtil.WHAT: "selected", SignalUtil.TO: _on_level_indicator_selected})

		var separator := separator_scene.instantiate()
		indicators_container.add_child(separator)

		if level_statuses[child.level_id] == LevelIndicator.Status.CURRENT:
			level_index = i-1

		i += 1

	level_frames.append(locked_frame)
	indicators_container.get_children().back().queue_free()

func _load_level_statuses() -> Dictionary:
	var result := {}
	var dir := DirAccess.open("res://resources/levels")
	
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.begins_with("lev.") and file_name.ends_with(".json"):
				var name_no_ext := file_name.get_basename()  # removes .json
				var file := FileAccess.open("res://resources/levels/%s" % file_name, FileAccess.READ)
				if file:
					var json_text := file.get_as_text()
					var json = JSON.parse_string(json_text)
					if typeof(json) == TYPE_DICTIONARY and json.has("status"):
						result[name_no_ext] = LevelIndicator.string_to_status(json["status"])
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		Log.trace(Log.Level.ERROR, "Could not open directory: %s" % dir);


	return result


# signal
func _on_frame_start_level(level: ILevel) -> void:
	visible = false

	add_child(level)
	level.reparent(get_tree().get_root())
	level.start_level()

	Global.ui.start_level()
	level_selected.emit()


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

# event


# setget
