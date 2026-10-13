## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Debug overlay listing every stat icon alongside its label and stat key(s).
## Only accessible from the home screen when [member Global.debug] is true.
class_name StatsIconsDebug
extends Control

signal menu_close

enum DisplayMode { LIST, GRID }

const _GRID_COLUMNS: int = 8

## All stat icons with their display label and the stat key(s) they represent.
const _STATS: Array[Dictionary] = [
	{"label": "Damage", "keys": "damage", "icon": StatIcon.Id.ATTACK},
	{"label": "Damage Multiplier", "keys": "damage_multiplier", "icon": StatIcon.Id.ATTACK_MULTIPLIER},
	{"label": "Fire Rate", "keys": "fire_rate", "icon": StatIcon.Id.FIRE_RATE},
	{"label": "Speed", "keys": "speed", "icon": StatIcon.Id.SPEED},
	{"label": "Shoot Range", "keys": "shoot_range", "icon": StatIcon.Id.RANGE},
	{"label": "Spread Angle", "keys": "spread_angle", "icon": StatIcon.Id.SPREAD},
	{"label": "Projectile Count", "keys": "projectile_count", "icon": StatIcon.Id.BULLETS},
	{"label": "AoE Range", "keys": "aoe_range", "icon": StatIcon.Id.AOE_RANGE},
	{"label": "Pierce Count", "keys": "pierce_count", "icon": StatIcon.Id.PIERCE_COUNT},
	{"label": "Pierce Reduction", "keys": "pierce_reduction", "icon": StatIcon.Id.PIERCE_REDUCTION},
	{"label": "Burn Damage", "keys": "aoe_tick · burn_damage_base", "icon": StatIcon.Id.BURN_DAMAGE},
	{"label": "Burn Duration", "keys": "aoe_duration · burn_duration", "icon": StatIcon.Id.BURN_DURATION},
	{"label": "Chain Bounces", "keys": "chain_bounces", "icon": StatIcon.Id.ELECTRICITY_CHAIN_BOUNCES},
	{"label": "Chain Range", "keys": "chain_range", "icon": StatIcon.Id.ELECTRICITY_CHAIN_RANGE},
	{"label": "Chain Falloff", "keys": "chain_damage_falloff", "icon": StatIcon.Id.ELECTRICITY_CHAIN_FALLOFF},
	{"label": "Electricity Damage", "keys": "electrify_tick_damage", "icon": StatIcon.Id.ELECTRICITY_BASE},
	{"label": "Electricity Duration", "keys": "electrify_duration", "icon": StatIcon.Id.ELECTRICITY_DURATION},
	{"label": "Electricity Interval", "keys": "electrify_tick_interval", "icon": StatIcon.Id.ELECTRICITY_INTERVAL},
	{"label": "Electricity Slow", "keys": "electrify_slow_amount", "icon": StatIcon.Id.ELECTRICITY_SLOW},
]

var _mode: DisplayMode = DisplayMode.LIST

@onready var _close_button: Button = %CloseButton
@onready var _mode_button: Button = %ModeToggleButton
@onready var _stats_container: VBoxContainer = %StatsContainer

func _ready() -> void:
	assert(_close_button != null, "CloseButton node not found")
	assert(_mode_button != null, "ModeToggleButton node not found")
	assert(_stats_container != null, "StatsContainer node not found")
	SignalUtil.connects([
		{SignalUtil.WHO: _close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_pressed},
		{SignalUtil.WHO: _mode_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_mode_toggle},
	])
	_populate()

func _on_close_pressed() -> void:
	menu_close.emit()

func _on_mode_toggle() -> void:
	_mode = DisplayMode.GRID if _mode == DisplayMode.LIST else DisplayMode.LIST
	_mode_button.text = "Switch to List" if _mode == DisplayMode.GRID else "Switch to Grid"
	_populate()

func _populate() -> void:
	for child in _stats_container.get_children():
		child.queue_free()
	if _mode == DisplayMode.LIST:
		_populate_list()
	else:
		_populate_grid()

func _populate_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = _GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	_stats_container.add_child(grid)

	for entry: Dictionary in _STATS:
		var texture: Texture2D = StatIcon.texture(entry["icon"])

		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(120.0, 0.0)
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_theme_constant_override("separation", 6)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(64.0, 64.0)
		icon.texture = texture
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(icon)

		var name_label := Label.new()
		name_label.text = entry["label"]
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(name_label)

		grid.add_child(cell)

func _populate_list() -> void:
	for entry: Dictionary in _STATS:
		var texture: Texture2D = StatIcon.texture(entry["icon"])

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(64.0, 64.0)
		icon.texture = texture
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)

		var text_col := VBoxContainer.new()
		text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var name_label := Label.new()
		name_label.text = entry["label"]
		name_label.add_theme_font_size_override("font_size", 16)
		text_col.add_child(name_label)

		var keys_label := Label.new()
		keys_label.text = entry["keys"]
		keys_label.add_theme_font_size_override("font_size", 12)
		keys_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		text_col.add_child(keys_label)

		row.add_child(text_col)
		_stats_container.add_child(row)
