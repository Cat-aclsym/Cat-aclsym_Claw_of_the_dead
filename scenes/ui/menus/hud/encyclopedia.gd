## © [2026] A7 Studio. All rights reserved. Trademark.

## UI component that displays information about towers and enemies.
class_name Encyclopedia
extends Control


## Signal emitted when the menu is closed.
signal menu_close


## Internal data structure for all entries.
var _all_entries: Dictionary = {
	"ENEMIES": [],
	"TOWERS": []
}
## Current frame index for entity animation.
var _anim_frame: int = 0
## Timer for entity animation frames.
var _anim_timer: float = 0.0
## Animation data for the currently displayed entity.
var _current_anim_data: Dictionary = {}
## Current category being displayed ("TOWERS" or "ENEMIES").
var _current_category: String = "ENEMIES"
## Font size for stat headers.
var _current_header_font_size: int = 40
## Current index within the category.
var _current_index: int = 0
## Font size for stat values.
var _current_stat_font_size: int = 32
## Base font used for text.
var _font: Font = preload("res://assets/ui/fonts/dotgothic/DotGothic16-Regular.ttf")
## Height of a background animation frame.
var _frame_height: int = 832
## Width of a background animation frame.
var _frame_width: int = 1396
## Number of frames per row in the background atlas.
var _frames_per_row: int = 8
## Flag indicating if a page turn animation is in progress.
var _is_turning_page: bool = false
## Active marquee tweens for cleanup when stats grid is rebuilt.
var _marquee_tweens: Array[Tween] = []
## Direction of the page turn (1 forward, -1 backward).
var _page_anim_direction: int = 1
## Duration of the page turn animation.
var _page_anim_duration: float = 0.3
## Timer for the page turn animation.
var _page_anim_timer: float = 0.0
## Total number of frames in the page turn animation.
var _page_total_frames: int = 10

## Background texture used for the encyclopedia pages.
@onready var background_texture: TextureRect = %BackgroundTexture
@onready var close_button: TextureButton = %CloseTextureButton
@onready var content_layout: Control = %ContentLayout
@onready var enemies_button: TextureButton = %EnemiesButton
@onready var enemies_exclamation: TextureRect = %EnemiesExclamation
@onready var item_exclamation: TextureRect = %ItemExclamation
@onready var name_label: Label = %NameLabel
@onready var next_button: TextureButton = %NextButton
@onready var prev_button: TextureButton = %PrevButton
@onready var scroll_indicator: TextureRect = %ScrollIndicator
@onready var scroll_indicator_top: TextureRect = %ScrollIndicatorTop
@onready var sprite_rect: TextureRect = %SpriteRect
@onready var stats_grid: GridContainer = %StatsGrid
@onready var stats_scroll: ScrollContainer = $GuiMarginContainer/MenuLayout/ContentLayout/RightPageVBox/StatsScroll
@onready var towers_button: TextureButton = %TowersButton
@onready var towers_exclamation: TextureRect = %TowersExclamation
## List of signal connections for UI elements, must be last because it uses onready vars.
@onready var signals: Array[Dictionary] = [
	{SignalUtil.TO: _on_close_pressed, SignalUtil.WHAT: "pressed", SignalUtil.WHO: close_button},
	{SignalUtil.TO: _on_category_pressed.bind("ENEMIES"), SignalUtil.WHAT: "pressed", SignalUtil.WHO: enemies_button},
	{SignalUtil.TO: _on_next_pressed, SignalUtil.WHAT: "pressed", SignalUtil.WHO: next_button},
	{SignalUtil.TO: _on_prev_pressed, SignalUtil.WHAT: "pressed", SignalUtil.WHO: prev_button},
	{SignalUtil.TO: _on_category_pressed.bind("TOWERS"), SignalUtil.WHAT: "pressed", SignalUtil.WHO: towers_button},
]


## Updates the page turn animation and scroll indicators.
## [param delta] The time since the last frame.
func _process(delta: float) -> void:
	if _is_turning_page:
		_page_anim_timer += delta
		var progress: float = clamp(_page_anim_timer / _page_anim_duration, 0.0, 1.0)

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

	var float_offset: float = sin(Time.get_ticks_msec() * 0.005) * 5.0
	var scroll_v_bar := stats_scroll.get_v_scroll_bar()

	if scroll_indicator.visible:
		scroll_indicator.position.y = stats_scroll.position.y + stats_scroll.size.y - scroll_indicator.size.y + float_offset
		if scroll_v_bar.value >= (scroll_v_bar.max_value - scroll_v_bar.page - 10):
			scroll_indicator.modulate.a = lerp(scroll_indicator.modulate.a, 0.0, delta * 10.0)
		else:
			scroll_indicator.modulate.a = lerp(scroll_indicator.modulate.a, 0.7, delta * 10.0)

	if scroll_indicator_top.visible:
		scroll_indicator_top.position.y = stats_scroll.position.y - 10 + float_offset
		if scroll_v_bar.value <= 10:
			scroll_indicator_top.modulate.a = lerp(scroll_indicator_top.modulate.a, 0.0, delta * 10.0)
		else:
			scroll_indicator_top.modulate.a = lerp(scroll_indicator_top.modulate.a, 0.7, delta * 10.0)

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


## Initializes the ui and entries.
func _ready() -> void:
	_initialize_entries()
	_update_background_texture()
	_update_display(false)
	SignalUtil.connects(signals)

	name_label.add_theme_font_override("font", _font)
	name_label.add_theme_font_size_override("font_size", 48)
	towers_button.add_theme_font_override("font", _font)
	enemies_button.add_theme_font_override("font", _font)


## Adds an enemy entry to the internal dictionary.
## [param p_id] The unique ID from StatsDB.
## [param p_entry_name] The translated name of the enemy.
## [param p_enemy_data] The raw data from StatsDB.
func _add_enemy_entry_from_data(p_id: String, p_entry_name: String, p_enemy_data: Dictionary) -> void:
	var scene_path: String = p_enemy_data.get("scene", "")
	if not ResourceLoader.exists(scene_path): return

	var stats_dict: Dictionary = {
		"ENCYCLOPEDIA.STATS.HEALTH": str(p_enemy_data.get("max_health", 0.0)),
		"ENCYCLOPEDIA.STATS.REWARD": str(p_enemy_data.get("reward", 0)),
		"ENCYCLOPEDIA.STATS.SPEED": "%.1f" % p_enemy_data.get("speed", 0.0)
	}

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
		"id": p_id,
		"name": p_entry_name,
		"scene_path": scene_path,
		"sprite": null,
		"stats": stats_dict,
		"type": "ENEMIES",
	})


## Adds a category header to the stats grid.
## [param p_text] The text to display.
func _add_stat_category_header(p_text: String) -> void:
	var header: Label = Label.new()
	header.text = p_text
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.theme_type_variation = "HeaderSmall"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_theme_font_override("font", _font)
	header.add_theme_font_size_override("font_size", _current_header_font_size)
	header.add_theme_color_override("font_color", Color("5d2e2b"))
	stats_grid.add_child(header)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_grid.add_child(spacer)


## Adds a stat row (key and value) to the grid.
## [param p_key] The stat label.
## [param p_val] The stat value.
func _add_stat_row(p_key: String, p_val: String) -> void:
	var key_container := Control.new()
	key_container.custom_minimum_size = Vector2(220, _current_stat_font_size + 10)
	key_container.clip_contents = true
	key_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_grid.add_child(key_container)

	var label_key: Label = Label.new()
	label_key.text = p_key
	label_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if p_key.length() > 15 else HORIZONTAL_ALIGNMENT_RIGHT
	label_key.autowrap_mode = TextServer.AUTOWRAP_OFF
	label_key.add_theme_font_override("font", _font)
	label_key.add_theme_font_size_override("font_size", _current_stat_font_size)
	label_key.add_theme_color_override("font_color", Color("874c2b"))
	key_container.add_child(label_key)

	label_key.size = label_key.get_combined_minimum_size()
	if p_key.length() <= 15:
		label_key.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if p_key.length() > 15:
		_animate_marquee(label_key, key_container)

	var label_val: Label = Label.new()
	label_val.text = p_val
	label_val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label_val.autowrap_mode = TextServer.AUTOWRAP_OFF
	label_val.add_theme_font_override("font", _font)
	label_val.add_theme_font_size_override("font_size", _current_stat_font_size)
	label_val.add_theme_color_override("font_color", Color("a87355"))
	stats_grid.add_child(label_val)


## Adds a tower entry to the internal dictionary.
## [param p_id] The unique ID from StatsDB.
## [param p_entry_name] The translated name of the tower.
## [param p_tower_data] The raw data from StatsDB.
func _add_tower_entry_from_data(p_id: String, p_entry_name: String, p_tower_data: Dictionary) -> void:
	var scene_path: String = p_tower_data.get("scene", "")
	if not ResourceLoader.exists(scene_path): return

	var base_stats: Dictionary = p_tower_data.get("base", {})
	var bullet_stats: Dictionary = base_stats.get("bullet_stats", {})

	_all_entries["TOWERS"].append({
		"id": p_id,
		"name": p_entry_name,
		"scene_path": scene_path,
		"sprite": null,
		"stats": {
			"ENCYCLOPEDIA.STATS.COST": str(base_stats.get("cost", 0)),
			"ENCYCLOPEDIA.STATS.DAMAGE": str(bullet_stats.get("damage", 0.0)),
			"ENCYCLOPEDIA.STATS.FIRERATE": "%.1f" % base_stats.get("fire_rate", 0.0),
			"ENCYCLOPEDIA.STATS.RANGE": str(base_stats.get("shoot_range", 0.0))
		},
		"type": "TOWERS",
	})


## Animates a label with a marquee effect if it's too long for its container.
## [param p_label] The label to animate.
## [param p_container] The parent container.
func _animate_marquee(p_label: Label, p_container: Control) -> void:
	await get_tree().process_frame

	if not is_instance_valid(p_label) or not is_instance_valid(p_container):
		return

	var text_width: float = p_label.get_combined_minimum_size().x
	var container_width: float = p_container.size.x

	if text_width > container_width:
		var scroll_dist: float = text_width - container_width + 20
		var duration: float = scroll_dist / 30.0

		var tween := create_tween().set_loops().set_parallel(false)
		tween.tween_interval(1.5)
		tween.tween_property(p_label, "position:x", -scroll_dist, duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(1.5)
		tween.tween_property(p_label, "position:x", 0.0, duration).set_trans(Tween.TRANS_LINEAR)
		_marquee_tweens.append(tween)


## Checks if scroll indicators should be visible.
func _check_scroll_indicator() -> void:
	if not is_instance_valid(scroll_indicator) or not is_instance_valid(scroll_indicator_top): return

	stats_grid.get_parent().queue_sort()
	var v_bar := stats_scroll.get_v_scroll_bar()
	var can_scroll = v_bar.max_value > stats_scroll.size.y
	scroll_indicator.visible = can_scroll
	scroll_indicator_top.visible = can_scroll

	if can_scroll:
		scroll_indicator.modulate.a = 0.7 if v_bar.value < (v_bar.max_value - v_bar.page - 10) else 0.0
		scroll_indicator_top.modulate.a = 0.7 if v_bar.value > 10 else 0.0
	else:
		scroll_indicator.modulate.a = 0.0
		scroll_indicator_top.modulate.a = 0.0


## Extracts sprite information from a scene instance.
## [param p_node] The node to extract from.
func _get_sprite_from_instance(p_node: Node) -> Dictionary:
	var data: Dictionary = {
		"animation": &"",
		"fps": 5.0,
		"frames": null,
		"scale": Vector2.ONE,
		"texture": null
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
				data["scale"] = anim_sprite.scale
	elif p_node.has_node("Sprite2D"):
		var sprite_2d: Sprite2D = p_node.get_node("Sprite2D") as Sprite2D
		data["texture"] = sprite_2d.texture
		data["scale"] = sprite_2d.scale
	return data


## Loads all tower and enemy entries from StatsDB.
func _initialize_entries() -> void:
	var tower_name_mapping: Dictionary = {
		"bat_01": "TOWER.1.NAME",
		"bat_02": "TOWER.2.NAME"
	}
	var enemy_name_mapping: Dictionary = {
		"big_daddy": "ENEMY.BIGDADDY.NAME",
		"damage_zombie": "ENEMY.FAT.NAME",
		"default_zombie": "ENEMY.DEFAULT.NAME",
		"rat": "ENEMY.RAT.NAME"
	}

	var tower_ids: Array = StatsDB.get_tower_ids()
	for tower_id_item in tower_ids:
		var tower_id: String = tower_id_item as String
		var tower_data: Dictionary = StatsDB.get_tower(tower_id)
		var entry_name: String = tower_name_mapping.get(tower_id, tower_id.to_upper() + ".NAME")
		_add_tower_entry_from_data(tower_id, entry_name, tower_data)

	var enemy_ids: Array = StatsDB.get_enemy_ids()
	for enemy_id_item in enemy_ids:
		var enemy_id: String = enemy_id_item as String
		var enemy_data: Dictionary = StatsDB.get_enemy(enemy_id)
		var entry_name: String = enemy_name_mapping.get(enemy_id, enemy_id.to_upper() + ".NAME")
		_add_enemy_entry_from_data(enemy_id, entry_name, enemy_data)


## Switches the current category.
## [param p_category] The new category ("TOWERS" or "ENEMIES").
func _on_category_pressed(p_category: String) -> void:
	if _is_turning_page: return
	if _current_category == p_category: return

	_current_category = p_category
	_current_index = 0
	_update_background_texture()
	_update_display(true, 1)


## Closes the encyclopedia menu.
func _on_close_pressed() -> void:
	if _is_turning_page: return
	menu_close.emit()


## Navigates to the next entry.
func _on_next_pressed() -> void:
	if _is_turning_page: return
	var entries: Array = _all_entries.get(_current_category, [])
	if _current_index < entries.size() - 1:
		_current_index += 1
		_update_display(true, 1)


## Navigates to the previous entry.
func _on_prev_pressed() -> void:
	if _is_turning_page: return
	if _current_index > 0:
		_current_index -= 1
		_update_display(true, -1)


## Sets the AtlasTexture region for the background animation.
## [param p_frame] The frame index to display.
func _set_background_frame(p_frame: int) -> void:
	var atlas: AtlasTexture = background_texture.texture as AtlasTexture
	if not atlas: return

	var row: int = p_frame / _frames_per_row
	var col: int = p_frame % _frames_per_row
	atlas.region = Rect2(col * _frame_width, row * _frame_height, _frame_width, _frame_height)


## Updates the background sprite based on the category.
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


## Updates visibility of category exclamation marks.
func _update_category_exclamations() -> void:
	enemies_exclamation.visible = ProgressionManager.has_unseen_encyclopedia_enemies()
	towers_exclamation.visible = ProgressionManager.has_unseen_encyclopedia_towers()


## Starts the page turn animation or updates the display instantly.
## [param p_animate] Whether to use an animation.
## [param p_direction] Animation direction (1 or -1).
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


## Updates the UI labels, sprites and stats for the current entry.
func _update_ui_elements() -> void:
	var entries: Array = _all_entries.get(_current_category, [])
	if entries.is_empty(): return

	var entry: Dictionary = entries[_current_index]

	var is_discovered: bool = false
	if _current_category == "TOWERS":
		is_discovered = ProgressionManager.is_tower_unlocked(entry["id"])
		if is_discovered:
			item_exclamation.visible = not ProgressionManager.is_tower_encyclopedia_seen(entry["id"])
			ProgressionManager.mark_tower_encyclopedia_seen(entry["id"])
		else:
			item_exclamation.visible = false
	else:
		is_discovered = ProgressionManager.is_enemy_seen(entry["id"])
		if is_discovered:
			item_exclamation.visible = not ProgressionManager.is_enemy_encyclopedia_seen(entry["id"])
			ProgressionManager.mark_enemy_encyclopedia_seen(entry["id"])
		else:
			item_exclamation.visible = false

	_update_category_exclamations()

	for tween in _marquee_tweens:
		if is_instance_valid(tween):
			tween.kill()
	_marquee_tweens.clear()

	for child in stats_grid.get_children():
		child.queue_free()

	if not is_discovered:
		_current_anim_data = {}
		_anim_timer = 0.0
		_anim_frame = 0

		name_label.text = "?"
		name_label.add_theme_color_override("font_color", Color("5d2e2b"))
		name_label.add_theme_font_size_override("font_size", 120)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		sprite_rect.texture = null
		sprite_rect.custom_minimum_size = Vector2.ZERO

		_add_stat_category_header("ENCYCLOPEDIA.NOT_DISCOVERED")

		prev_button.modulate.a = 1.0 if _current_index > 0 else 0.0
		prev_button.disabled = _current_index == 0
		next_button.modulate.a = 1.0 if _current_index < entries.size() - 1 else 0.0
		next_button.disabled = _current_index >= entries.size() - 1
		towers_button.disabled = (_current_category == "TOWERS")
		enemies_button.disabled = (_current_category == "ENEMIES")
		return

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
	name_label.add_theme_color_override("font_color", Color("5d2e2b"))

	var displayed_name: String = tr(entry["name"])
	var name_len: int = displayed_name.length()

	if name_len > 28:
		name_label.add_theme_font_size_override("font_size", 20)
	elif name_len > 22:
		name_label.add_theme_font_size_override("font_size", 26)
	elif name_len > 18:
		name_label.add_theme_font_size_override("font_size", 32)
	elif name_len > 14:
		name_label.add_theme_font_size_override("font_size", 40)
	else:
		name_label.add_theme_font_size_override("font_size", 48)

	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if _current_anim_data.has("texture") and _current_anim_data["texture"] != null:
		sprite_rect.texture = _current_anim_data["texture"]
		var base_scale: Vector2 = _current_anim_data.get("scale", Vector2.ONE)
		sprite_rect.custom_minimum_size = Vector2(160, 160) * base_scale
	else:
		sprite_rect.texture = null
		sprite_rect.custom_minimum_size = Vector2.ZERO

	stats_scroll.scroll_vertical = 0

	var stats: Dictionary = entry["stats"]
	var combat_stats: Dictionary = {}
	var economy_stats: Dictionary = {}
	var combat_keys: Array[String] = [
		"ENCYCLOPEDIA.STATS.ATTACK_DURATION",
		"ENCYCLOPEDIA.STATS.COOLDOWN",
		"ENCYCLOPEDIA.STATS.DAMAGE",
		"ENCYCLOPEDIA.STATS.DISABLE_DURATION",
		"ENCYCLOPEDIA.STATS.FIRERATE",
		"ENCYCLOPEDIA.STATS.HEALTH",
		"ENCYCLOPEDIA.STATS.POST_ATTACK",
		"ENCYCLOPEDIA.STATS.PRE_ATTACK",
		"ENCYCLOPEDIA.STATS.RANGE",
		"ENCYCLOPEDIA.STATS.SPEED"
	]
	var economy_keys: Array[String] = ["ENCYCLOPEDIA.STATS.COST", "ENCYCLOPEDIA.STATS.REWARD"]

	for k in stats:
		if k in combat_keys: combat_stats[k] = stats[k]
		elif k in economy_keys: economy_stats[k] = stats[k]

	var total_rows: int = stats.size()
	if not combat_stats.is_empty(): total_rows += 1
	if not economy_stats.is_empty(): total_rows += 1

	if total_rows > 12:
		_current_header_font_size = 28
		_current_stat_font_size = 20
		stats_grid.add_theme_constant_override("v_separation", 8)
	else:
		_current_header_font_size = 32
		_current_stat_font_size = 24
		stats_grid.add_theme_constant_override("v_separation", 16)

	if not combat_stats.is_empty():
		_add_stat_category_header("ENCYCLOPEDIA.CATEGORY.COMBAT")
		for k in combat_stats: _add_stat_row(k, combat_stats[k])

	if not economy_stats.is_empty():
		_add_stat_category_header("ENCYCLOPEDIA.CATEGORY.ECONOMY")
		for k in economy_stats: _add_stat_row(k, economy_stats[k])

	prev_button.modulate.a = 1.0 if _current_index > 0 else 0.0
	prev_button.disabled = _current_index == 0
	next_button.modulate.a = 1.0 if _current_index < entries.size() - 1 else 0.0
	next_button.disabled = _current_index >= entries.size() - 1
	towers_button.disabled = (_current_category == "TOWERS")
	enemies_button.disabled = (_current_category == "ENEMIES")

	get_tree().process_frame.connect(_check_scroll_indicator, CONNECT_ONE_SHOT)
