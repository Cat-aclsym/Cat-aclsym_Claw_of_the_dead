## © [2024] A7 Studio. All rights reserved. Trademark.

class_name Encyclopedia
extends Control

## Signal emitted when the menu is closed
signal menu_close

@onready var close_button: TextureButton = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/TopLineHBoxContainer/AspectRatioContainer/CloseTextureButton
@onready var prev_button: Button = $GuiMarginContainer/MenuMarginContainer/NavigationHBoxContainer/PrevButton
@onready var next_button: Button = $GuiMarginContainer/MenuMarginContainer/NavigationHBoxContainer/NextButton
@onready var sprite_rect: TextureRect = $GuiMarginContainer/MenuMarginContainer/ContentHBoxContainer/LeftPageVBox/SpriteAspectRatio/SpriteRect
@onready var name_label: Label = $GuiMarginContainer/MenuMarginContainer/ContentHBoxContainer/LeftPageVBox/NameLabel
@onready var stats_grid: GridContainer = $GuiMarginContainer/MenuMarginContainer/ContentHBoxContainer/RightPageVBox/StatsGrid
@onready var section_label: Label = $GuiMarginContainer/MenuMarginContainer/MenuRowVBoxContainer/TopLineHBoxContainer/SectionLabel

var _entries: Array[Dictionary] = []
var _current_index: int = 0

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_pressed},
	{SignalUtil.WHO: prev_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_prev_pressed},
	{SignalUtil.WHO: next_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_next_pressed},
]

func _ready() -> void:
	_initialize_entries()
	_update_display()
	SignalUtil.connects(signals)

func _on_close_pressed() -> void:
	menu_close.emit()

func _initialize_entries() -> void:
	# Mapping between JSON IDs and translation keys
	var tower_name_mapping: Dictionary = {
		"bat_01": "TOWER.1.NAME",
		"bat_02": "TOWER.2.NAME"
	}
	
	var enemy_name_mapping: Dictionary = {
		"default_zombie": "ENEMY.DEFAULT.NAME",
		"damage_zombie": "ENEMY.FAT.NAME",
		"rat": "ENEMY.RAT.NAME",
		"big_daddy": "ENEMY.BIGDADDY.NAME"
	}

	# Towers from StatsDB
	var tower_ids: Array = StatsDB.get_tower_ids()
	for tower_id_item in tower_ids:
		var tower_id: String = tower_id_item as String
		var tower_data: Dictionary = StatsDB.get_tower(tower_id)
		var entry_name: String = tower_name_mapping.get(tower_id, tower_id.to_upper() + ".NAME")
		_add_tower_entry_from_data(entry_name, tower_data)
	
	# Enemies from StatsDB
	var enemy_ids: Array = StatsDB.get_enemy_ids()
	for enemy_id_item in enemy_ids:
		var enemy_id: String = enemy_id_item as String
		var enemy_data: Dictionary = StatsDB.get_enemy(enemy_id)
		var entry_name: String = enemy_name_mapping.get(enemy_id, enemy_id.to_upper() + ".NAME")
		_add_enemy_entry_from_data(entry_name, enemy_data)

func _add_tower_entry_from_data(p_entry_name: String, p_tower_data: Dictionary) -> void:
	var scene_path: String = p_tower_data.get("scene", "")
	if not ResourceLoader.exists(scene_path): return
	
	var base_stats: Dictionary = p_tower_data.get("base", {})
	var bullet_stats: Dictionary = base_stats.get("bullet_stats", {})
	
	var scene_res: PackedScene = load(scene_path) as PackedScene
	if not scene_res: return
	
	var tower_obj: Node = scene_res.instantiate()
	if tower_obj:
		_entries.append({
			"name": p_entry_name,
			"type": "TOWERS",
			"sprite": _get_sprite_from_instance(tower_obj),
			"stats": {
				"ENCYCLOPEDIA.STATS.COST": str(base_stats.get("cost", 0)),
				"ENCYCLOPEDIA.STATS.FIRERATE": "%.1f" % base_stats.get("fire_rate", 0.0),
				"ENCYCLOPEDIA.STATS.RANGE": str(base_stats.get("shoot_range", 0.0)),
				"ENCYCLOPEDIA.STATS.DAMAGE": str(bullet_stats.get("damage", 0.0))
			}
		})
		tower_obj.queue_free()

func _add_enemy_entry_from_data(p_entry_name: String, p_enemy_data: Dictionary) -> void:
	var scene_path: String = p_enemy_data.get("scene", "")
	if not ResourceLoader.exists(scene_path): return
	
	var scene_res: PackedScene = load(scene_path) as PackedScene
	if not scene_res: return
	
	var enemy_obj: Node = scene_res.instantiate()
	if enemy_obj:
		_entries.append({
			"name": p_entry_name,
			"type": "ENEMIES",
			"sprite": _get_sprite_from_instance(enemy_obj),
			"stats": {
				"ENCYCLOPEDIA.STATS.HEALTH": str(p_enemy_data.get("max_health", 0.0)),
				"ENCYCLOPEDIA.STATS.SPEED": "%.1f" % p_enemy_data.get("speed", 0.0)
			}
		})
		enemy_obj.queue_free()

func _get_sprite_from_instance(p_node: Node) -> Texture2D:
	if p_node.has_node("AnimatedSprite2D"):
		var anim_sprite: AnimatedSprite2D = p_node.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if anim_sprite.sprite_frames:
			var anim: String = "idle" if anim_sprite.sprite_frames.has_animation("idle") else anim_sprite.sprite_frames.get_animation_names()[0]
			return anim_sprite.sprite_frames.get_frame_texture(anim, 0)
	elif p_node.has_node("Sprite2D"):
		var sprite_2d: Sprite2D = p_node.get_node("Sprite2D") as Sprite2D
		return sprite_2d.texture
	return null

func _update_display() -> void:
	if _entries.is_empty(): return
	
	var entry: Dictionary = _entries[_current_index]
	name_label.text = entry["name"]
	section_label.text = "ENCYCLOPEDIA.SECTION." + entry["type"]
	sprite_rect.texture = entry["sprite"] as Texture2D
	
	# Clear stats
	for child in stats_grid.get_children():
		child.queue_free()
	
	# Add stats
	var stats: Dictionary = entry["stats"]
	for stat_key in stats:
		var label_key: Label = Label.new()
		label_key.text = stat_key
		label_key.theme_type_variation = "HeaderSmall"
		stats_grid.add_child(label_key)
		
		var label_val: Label = Label.new()
		label_val.text = stats[stat_key]
		stats_grid.add_child(label_val)
	
	prev_button.visible = _current_index > 0
	next_button.visible = _current_index < _entries.size() - 1

func _on_prev_pressed() -> void:
	if _current_index > 0:
		_current_index -= 1
		_update_display()

func _on_next_pressed() -> void:
	if _current_index < _entries.size() - 1:
		_current_index += 1
		_update_display()
