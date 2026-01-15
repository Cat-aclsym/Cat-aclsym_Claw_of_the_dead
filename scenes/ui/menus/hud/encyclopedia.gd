## © [2024] A7 Studio. All rights reserved. Trademark.

class_name Encyclopedia
extends Control


## Signal emitted when the menu is closed
signal menu_close

@onready var close_button: TextureButton = %CloseTextureButton
@onready var prev_button: TextureButton = %PrevButton
@onready var next_button: TextureButton = %NextButton
@onready var towers_button: TextureButton = %TowersButton
@onready var enemies_button: TextureButton = %EnemiesButton
@onready var sprite_rect: TextureRect = %SpriteRect
@onready var name_label: Label = %NameLabel
@onready var stats_grid: GridContainer = %StatsGrid
@onready var content_layout: Control = %ContentLayout
@onready var background_texture: TextureRect = %BackgroundTexture


var _all_entries: Dictionary = {
	"TOWERS": [],
	"ENEMIES": []
}
var _current_category: String = "ENEMIES"
var _current_index: int = 0

# Animation state
var _current_anim_data: Dictionary = {}
var _anim_timer: float = 0.0
var _anim_frame: int = 0

# Page turn animation
var _is_turning_page: bool = false
var _page_anim_timer: float = 0.0
var _page_anim_duration: float = 0.3
var _page_anim_direction: int = 1 # 1 for forward, -1 for reverse
var _page_total_frames: int = 10
var _frame_width: int = 1396 # Largeur d'une frame (1396w)
var _frame_height: int = 832 # Hauteur d'une frame (832h)
var _frames_per_row: int = 8

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_pressed},
	{SignalUtil.WHO: prev_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_prev_pressed},
	{SignalUtil.WHO: next_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_next_pressed},
	{SignalUtil.WHO: towers_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_category_pressed.bind("TOWERS")},
	{SignalUtil.WHO: enemies_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_category_pressed.bind("ENEMIES")},
]

func _ready() -> void:
	_initialize_entries()
	_update_background_texture()
	_update_display(false) # Start without animation
	SignalUtil.connects(signals)

func _on_close_pressed() -> void:
	if _is_turning_page: return
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

	_all_entries["TOWERS"].append({
		"name": p_entry_name,
		"type": "TOWERS",
		"scene_path": scene_path,
		"sprite": null,
		"stats": {
			"ENCYCLOPEDIA.STATS.COST": str(base_stats.get("cost", 0)),
			"ENCYCLOPEDIA.STATS.FIRERATE": "%.1f" % base_stats.get("fire_rate", 0.0),
			"ENCYCLOPEDIA.STATS.RANGE": str(base_stats.get("shoot_range", 0.0)),
			"ENCYCLOPEDIA.STATS.DAMAGE": str(bullet_stats.get("damage", 0.0))
		}
	})

func _add_enemy_entry_from_data(p_entry_name: String, p_enemy_data: Dictionary) -> void:
	var scene_path: String = p_enemy_data.get("scene", "")
	if not ResourceLoader.exists(scene_path): return

	var stats_dict: Dictionary = {
		"ENCYCLOPEDIA.STATS.HEALTH": str(p_enemy_data.get("max_health", 0.0)),
		"ENCYCLOPEDIA.STATS.SPEED": "%.1f" % p_enemy_data.get("speed", 0.0),
		"ENCYCLOPEDIA.STATS.REWARD": str(p_enemy_data.get("reward", 0))
	}

	# Add extra stats if they exist (e.g. for Big Daddy)
	if p_enemy_data.has("extra"):
		var extra: Dictionary = p_enemy_data["extra"]
		if extra.has("shoot_range"): stats_dict["ENCYCLOPEDIA.STATS.RANGE"] = str(extra["shoot_range"])
		if extra.has("fire_rate"): stats_dict["ENCYCLOPEDIA.STATS.FIRERATE"] = "%.1f" % extra["fire_rate"]
		if extra.has("tower_disable_duration"): stats_dict["ENCYCLOPEDIA.STATS.DISABLE_DURATION"] = "%.1fs" % extra["tower_disable_duration"]
		if extra.has("pre_attack_delay"): stats_dict["ENCYCLOPEDIA.STATS.PRE_ATTACK"] = "%.1fs" % extra["pre_attack_delay"]
		if extra.has("attack_duration"): stats_dict["ENCYCLOPEDIA.STATS.ATTACK_DURATION"] = "%.1fs" % extra["attack_duration"]
		if extra.has("post_attack_delay"): stats_dict["ENCYCLOPEDIA.STATS.POST_ATTACK"] = "%.1fs" % extra["post_attack_delay"]
		if extra.has("attack_cooldown"): stats_dict["ENCYCLOPEDIA.STATS.COOLDOWN"] = "%.1fs" % extra["attack_cooldown"]

	_all_entries["ENEMIES"].append({
		"name": p_entry_name,
		"type": "ENEMIES",
		"scene_path": scene_path,
		"sprite": null,
		"stats": stats_dict
	})

func _process(delta: float) -> void:
	if _is_turning_page:
		_page_anim_timer += delta
		var progress: float = clamp(_page_anim_timer / _page_anim_duration, 0.0, 1.0)
		
		# Calculate frame index
		var frame_idx: int
		if _page_anim_direction == 1:
			frame_idx = int(progress * (_page_total_frames - 1))
		else:
			frame_idx = int((1.0 - progress) * (_page_total_frames - 1))
		
		_set_background_frame(frame_idx)
		
		if progress >= 1.0:
			_is_turning_page = false
			content_layout.visible = true
			_update_ui_elements()
		return

	if not _current_anim_data.is_empty() and _current_anim_data.get("frames"):
		var frames: SpriteFrames = _current_anim_data["frames"]
		var anim: StringName = _current_anim_data["animation"]
		var fps: float = _current_anim_data["fps"]

		if fps > 0:
			_anim_timer += delta
			var frame_duration: float = 1.0 / fps
			if _anim_timer >= frame_duration:
				_anim_timer = 0.0
				var count: int = frames.get_frame_count(anim)
				if count > 0:
					_anim_frame = (_anim_frame + 1) % count
					sprite_rect.texture = frames.get_frame_texture(anim, _anim_frame)

func _get_sprite_from_instance(p_node: Node) -> Dictionary:
	var data: Dictionary = {
		"texture": null,
		"frames": null,
		"animation": &"",
		"fps": 5.0
	}
	if p_node.has_node("AnimatedSprite2D"):
		var anim_sprite: AnimatedSprite2D = p_node.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if anim_sprite.sprite_frames:
			var animation_names: PackedStringArray = anim_sprite.sprite_frames.get_animation_names()
			if not animation_names.is_empty():
				var anim: String = "idle" if anim_sprite.sprite_frames.has_animation("idle") else str(animation_names[0])
				data["texture"] = anim_sprite.sprite_frames.get_frame_texture(anim, 0)
				data["frames"] = anim_sprite.sprite_frames
				data["animation"] = StringName(anim)
				data["fps"] = anim_sprite.sprite_frames.get_animation_speed(anim)
	elif p_node.has_node("Sprite2D"):
		var sprite_2d: Sprite2D = p_node.get_node("Sprite2D") as Sprite2D
		data["texture"] = sprite_2d.texture
	return data

func _update_background_texture() -> void:
	var texture_path: String = ""
	if _current_category == "TOWERS":
		texture_path = "res://assets/ui/huds/encyclopedie_tours.png"
	else:
		texture_path = "res://assets/ui/huds/encyclopedie_ennemis.png"
	
	if ResourceLoader.exists(texture_path):
		var tex: Texture2D = load(texture_path)
		var atlas: AtlasTexture = background_texture.texture as AtlasTexture
		if atlas:
			atlas.atlas = tex
			_set_background_frame(0)

func _set_background_frame(p_frame: int) -> void:
	var atlas: AtlasTexture = background_texture.texture as AtlasTexture
	if not atlas: return
	
	var row: int = p_frame / _frames_per_row
	var col: int = p_frame % _frames_per_row
	atlas.region = Rect2(col * _frame_width, row * _frame_height, _frame_width, _frame_height)

func _update_display(p_animate: bool = true, p_direction: int = 1) -> void:
	if p_animate:
		_is_turning_page = true
		_page_anim_timer = 0.0
		_page_anim_direction = p_direction
		content_layout.visible = false
		_set_background_frame(0 if p_direction == 1 else _page_total_frames - 1)
	else:
		_is_turning_page = false
		content_layout.visible = true
		_set_background_frame(0)
		_update_ui_elements()

func _update_ui_elements() -> void:
	var entries: Array = _all_entries.get(_current_category, [])
	if entries.is_empty(): return

	var entry: Dictionary = entries[_current_index]

	# Lazy load sprite and cache it
	if entry.get("sprite") == null:
		var scene_path: String = entry.get("scene_path", "")
		if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
			var scene_res: PackedScene = load(scene_path) as PackedScene
			if scene_res:
				var obj: Node = scene_res.instantiate()
				if obj:
					entry["sprite"] = _get_sprite_from_instance(obj)
					obj.queue_free()

	_current_anim_data = entry.get("sprite", {})
	_anim_timer = 0.0
	_anim_frame = 0

	name_label.text = entry["name"]
	if _current_anim_data.has("texture"):
		sprite_rect.texture = _current_anim_data["texture"]
	else:
		sprite_rect.texture = null

	# Clear stats
	for child in stats_grid.get_children():
		child.queue_free()

	# Add stats
	var stats: Dictionary = entry["stats"]

	# Determine if we should group
	var combat_keys: Array = ["ENCYCLOPEDIA.STATS.DAMAGE", "ENCYCLOPEDIA.STATS.FIRERATE", "ENCYCLOPEDIA.STATS.RANGE", "ENCYCLOPEDIA.STATS.HEALTH", "ENCYCLOPEDIA.STATS.SPEED", "ENCYCLOPEDIA.STATS.DISABLE_DURATION", "ENCYCLOPEDIA.STATS.PRE_ATTACK", "ENCYCLOPEDIA.STATS.ATTACK_DURATION", "ENCYCLOPEDIA.STATS.POST_ATTACK", "ENCYCLOPEDIA.STATS.COOLDOWN"]
	var economy_keys: Array = ["ENCYCLOPEDIA.STATS.COST", "ENCYCLOPEDIA.STATS.REWARD"]

	var combat_stats: Dictionary = {}
	var economy_stats: Dictionary = {}

	for k in stats:
		if k in combat_keys: combat_stats[k] = stats[k]
		elif k in economy_keys: economy_stats[k] = stats[k]

	if not combat_stats.is_empty():
		_add_stat_category_header("ENCYCLOPEDIA.CATEGORY.COMBAT")
		for k in combat_stats: _add_stat_row(k, combat_stats[k])

	if not economy_stats.is_empty():
		_add_stat_category_header("ENCYCLOPEDIA.CATEGORY.ECONOMY")
		for k in economy_stats: _add_stat_row(k, economy_stats[k])

	# Fixed positioning for buttons: use modulate to keep layout space
	prev_button.modulate.a = 1.0 if _current_index > 0 else 0.0
	prev_button.disabled = _current_index == 0

	next_button.modulate.a = 1.0 if _current_index < entries.size() - 1 else 0.0
	next_button.disabled = _current_index >= entries.size() - 1

	# Update category buttons visual state
	towers_button.disabled = (_current_category == "TOWERS")
	enemies_button.disabled = (_current_category == "ENEMIES")

func _add_stat_category_header(p_text: String) -> void:
	var header: Label = Label.new()
	header.text = p_text
	header.theme_type_variation = "HeaderSmall"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color.CHARTREUSE)
	stats_grid.add_child(header)
	stats_grid.add_child(Control.new()) # Empty space for the second column

func _add_stat_row(p_key: String, p_val: String) -> void:
	var label_key: Label = Label.new()
	label_key.text = p_key
	label_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_key.add_theme_font_size_override("font_size", 16)
	stats_grid.add_child(label_key)

	var label_val: Label = Label.new()
	label_val.text = p_val
	label_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_val.add_theme_font_size_override("font_size", 16)
	stats_grid.add_child(label_val)

func _on_category_pressed(p_category: String) -> void:
	if _is_turning_page: return
	if _current_category == p_category: return
	
	_current_category = p_category
	_current_index = 0
	_update_background_texture()
	_update_display(true, 1) # Animate forward for category switch

func _on_prev_pressed() -> void:
	if _is_turning_page: return
	if _current_index > 0:
		_current_index -= 1
		_update_display(true, -1) # Animate reverse

func _on_next_pressed() -> void:
	if _is_turning_page: return
	var entries: Array = _all_entries.get(_current_category, [])
	if _current_index < entries.size() - 1:
		_current_index += 1
		_update_display(true, 1) # Animate forward
