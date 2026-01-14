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
	# Towers
	_add_tower_entry("TOWER.1.NAME", "res://scenes/gameplay/entities/tower/towers/bat_01.tscn")
	_add_tower_entry("TOWER.2.NAME", "res://scenes/gameplay/entities/tower/towers/bat_02.tscn")
	_add_tower_entry("TOWER.FIRE.NAME", "res://scenes/gameplay/entities/tower/towers/debug_fire_tower.tscn")
	_add_tower_entry("TOWER.MULTISHOT.NAME", "res://scenes/gameplay/entities/tower/towers/debug_multishot_tower.tscn")
	_add_tower_entry("TOWER.PIERCING.NAME", "res://scenes/gameplay/entities/tower/towers/debug_piercing_tower.tscn")
	
	# Enemies
	_add_enemy_entry("ENEMY.RAT.NAME", "res://scenes/gameplay/entities/enemy/enemies/ene.01.tscn")
	_add_enemy_entry("ENEMY.DEFAULT.NAME", "res://scenes/gameplay/entities/enemy/enemies/ene.02.tscn")
	_add_enemy_entry("ENEMY.FAT.NAME", "res://scenes/gameplay/entities/enemy/enemies/ene.03.tscn")
	_add_enemy_entry("ENEMY.BIGDADDY.NAME", "res://scenes/gameplay/entities/enemy/enemies/big_daddy.tscn")

func _add_tower_entry(entry_name: String, scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path): return
	var scene := load(scene_path)
	var instance := scene.instantiate() as ITower
	if instance:
		_entries.append({
			"name": entry_name,
			"type": "TOWERS",
			"sprite": _get_sprite_from_instance(instance),
			"stats": {
				"ENCYCLOPEDIA.STATS.COST": str(instance.cost),
				"ENCYCLOPEDIA.STATS.FIRERATE": "%.1f" % instance.fire_rate,
				"ENCYCLOPEDIA.STATS.RANGE": str(instance.shoot_range),
				"ENCYCLOPEDIA.STATS.DAMAGE": str(instance.bullet_stats.get("damage", 0))
			}
		})
		instance.queue_free()

func _add_enemy_entry(entry_name: String, scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path): return
	var scene := load(scene_path)
	var instance := scene.instantiate() as IEnemy
	if instance:
		_entries.append({
			"name": entry_name,
			"type": "ENEMIES",
			"sprite": _get_sprite_from_instance(instance),
			"stats": {
				"ENCYCLOPEDIA.STATS.HEALTH": str(instance.max_health),
				"ENCYCLOPEDIA.STATS.SPEED": "%.1f" % instance.speed
			}
		})
		instance.queue_free()

func _get_sprite_from_instance(instance: Node) -> Texture2D:
	if instance.has_node("AnimatedSprite2D"):
		var anim_sprite = instance.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if anim_sprite.sprite_frames:
			var anim = "idle" if anim_sprite.sprite_frames.has_animation("idle") else anim_sprite.sprite_frames.get_animation_names()[0]
			return anim_sprite.sprite_frames.get_frame_texture(anim, 0)
	elif instance.has_node("Sprite2D"):
		return (instance.get_node("Sprite2D") as Sprite2D).texture
	return null

func _update_display() -> void:
	if _entries.is_empty(): return
	
	var entry = _entries[_current_index]
	name_label.text = entry["name"]
	section_label.text = "ENCYCLOPEDIA.SECTION." + entry["type"]
	sprite_rect.texture = entry["sprite"]
	
	# Clear stats
	for child in stats_grid.get_children():
		child.queue_free()
	
	# Add stats
	for stat_key in entry["stats"]:
		var label_key := Label.new()
		label_key.text = stat_key
		label_key.theme_type_variation = "HeaderSmall"
		stats_grid.add_child(label_key)
		
		var label_val := Label.new()
		label_val.text = entry["stats"][stat_key]
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

