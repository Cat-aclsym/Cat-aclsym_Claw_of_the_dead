## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Debug overlay listing every stat icon alongside its label and stat key(s).
## Only accessible from the home screen when [member Global.debug] is true.
class_name StatsIconsDebug
extends Control

signal menu_close

enum DisplayMode { LIST, GRID }

## All stat icons with their display label and the stat key(s) they represent.
const _STATS: Array[Dictionary] = [
	{"label": "Damage", "keys": "damage", "icon": "res://assets/ui/stats/attack.png"},
	{"label": "Damage Multiplier", "keys": "damage_multiplier", "icon": "res://assets/ui/stats/attack-multiplier.png"},
	{"label": "Fire Rate", "keys": "fire_rate", "icon": "res://assets/ui/stats/fire-rate.png"},
	{"label": "Speed", "keys": "speed", "icon": "res://assets/ui/stats/speed.png"},
	{"label": "Shoot Range", "keys": "shoot_range", "icon": "res://assets/ui/stats/range.png"},
	{"label": "Spread Angle", "keys": "spread_angle", "icon": "res://assets/ui/stats/spread.png"},
	{"label": "Projectile Count", "keys": "projectile_count", "icon": "res://assets/ui/stats/bullets.png"},
	{"label": "AoE Range", "keys": "aoe_range", "icon": "res://assets/ui/stats/aoe-range.png"},
	{"label": "Pierce Count", "keys": "pierce_count", "icon": "res://assets/ui/stats/pierce-count.png"},
	{"label": "Pierce Reduction", "keys": "pierce_reduction", "icon": "res://assets/ui/stats/pierce-reduction.png"},
	{"label": "Burn Damage", "keys": "aoe_tick · burn_damage_base", "icon": "res://assets/ui/stats/burn-damage.png"},
	{"label": "Burn Duration", "keys": "aoe_duration · burn_duration", "icon": "res://assets/ui/stats/burn-duration.png"},
	{"label": "Chain Bounces", "keys": "chain_bounces", "icon": "res://assets/ui/stats/electricity-chain-bounces.png"},
	{"label": "Chain Range", "keys": "chain_range", "icon": "res://assets/ui/stats/electricity-chain-range.png"},
	{"label": "Chain Falloff", "keys": "chain_damage_falloff", "icon": "res://assets/ui/stats/electricity-chain-falloff.png"},
	{"label": "Electricity Damage", "keys": "electrify_tick_damage", "icon": "res://assets/ui/stats/electricity-base.png"},
	{"label": "Electricity Duration", "keys": "electrify_duration", "icon": "res://assets/ui/stats/electricity-duration.png"},
	{"label": "Electricity Interval", "keys": "electrify_tick_interval", "icon": "res://assets/ui/stats/electricity-interval.png"},
	{"label": "Electricity Slow", "keys": "electrify_slow_amount", "icon": "res://assets/ui/stats/electricity-slow.png"},
]

const _GRID_COLUMNS: int = 8

var _mode: DisplayMode = DisplayMode.LIST

@onready var _close_button: Button = %CloseButton
@onready var _mode_button: Button = %ModeToggleButton
@onready var _stats_container: VBoxContainer = %StatsContainer

func _ready() -> void:
	assert(_close_button != null, "CloseButton node not found")
	assert(_mode_button != null, "ModeToggleButton node not found")
	assert(_stats_container != null, "StatsContainer node not found")
	_close_button.pressed.connect(_on_close_pressed)
	_mode_button.pressed.connect(_on_mode_toggle)
	_populate()

func _populate() -> void:
	for child in _stats_container.get_children():
		child.queue_free()
	if _mode == DisplayMode.LIST:
		_populate_list()
	else:
		_populate_grid()

func _populate_list() -> void:
	for entry: Dictionary in _STATS:
		var texture: Texture2D = load(entry["icon"]) as Texture2D

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

func _populate_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = _GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	_stats_container.add_child(grid)

	for entry: Dictionary in _STATS:
		var texture: Texture2D = load(entry["icon"]) as Texture2D

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

func _on_mode_toggle() -> void:
	_mode = DisplayMode.GRID if _mode == DisplayMode.LIST else DisplayMode.LIST
	_mode_button.text = "Switch to List" if _mode == DisplayMode.GRID else "Switch to Grid"
	_populate()

func _on_close_pressed() -> void:
	menu_close.emit()
