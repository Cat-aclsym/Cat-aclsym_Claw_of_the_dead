## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Displays a stat bar with icon, name and progress bar.
class_name StatBar
extends HBoxContainer

const _ICON_AOE_RANGE: Texture2D = preload("res://assets/ui/stats/aoe-range.png")
const _ICON_ATTACK: Texture2D = preload("res://assets/ui/stats/attack.png")
const _ICON_ATTACK_MULTIPLIER: Texture2D = preload("res://assets/ui/stats/attack-multiplier.png")
const _ICON_BULLETS: Texture2D = preload("res://assets/ui/stats/bullets.png")
const _ICON_BURN_DAMAGE: Texture2D = preload("res://assets/ui/stats/burn-damage.png")
const _ICON_BURN_DURATION: Texture2D = preload("res://assets/ui/stats/burn-duration.png")
const _ICON_ELECTRICITY_BASE: Texture2D = preload("res://assets/ui/stats/electricity-base.png")
const _ICON_ELECTRICITY_CHAIN: Texture2D = preload("res://assets/ui/stats/electricity-chain-bounces.png")
const _ICON_ELECTRICITY_CHAIN_FALLOFF: Texture2D = preload("res://assets/ui/stats/electricity-chain-falloff.png")
const _ICON_ELECTRICITY_CHAIN_RANGE: Texture2D = preload("res://assets/ui/stats/electricity-chain-range.png")
const _ICON_ELECTRICITY_DURATION: Texture2D = preload("res://assets/ui/stats/electricity-duration.png")
const _ICON_ELECTRICITY_INTERVAL: Texture2D = preload("res://assets/ui/stats/electricity-interval.png")
const _ICON_ELECTRICITY_SLOW: Texture2D = preload("res://assets/ui/stats/electricity-slow.png")
const _ICON_FIRE_RATE: Texture2D = preload("res://assets/ui/stats/fire-rate.png")
const _ICON_PIERCE_COUNT: Texture2D = preload("res://assets/ui/stats/pierce-count.png")
const _ICON_PIERCE_REDUCTION: Texture2D = preload("res://assets/ui/stats/pierce-reduction.png")
const _ICON_RANGE: Texture2D = preload("res://assets/ui/stats/range.png")
const _ICON_SPEED: Texture2D = preload("res://assets/ui/stats/speed.png")
const _ICON_SPREAD: Texture2D = preload("res://assets/ui/stats/spread.png")

@onready var _icon: TextureRect = $VBoxContainer/HBoxContainer/StatIcon
@onready var _progress_bar: TextureProgressBar = $VBoxContainer/TextureProgressBar
@onready var _stat_name_label: Label = $VBoxContainer/HBoxContainer/StatName

## Sets up the stat bar with the given data.
## [br] [param stat_name] determines the icon and label text.
## [br] [param show_change] if true, appends the change arrow to the tooltip.
func setup(stat_name: String, current_value: float, new_value: float, max_value: float = 200.0, show_change: bool = false) -> void:
	var icon: Texture2D = _get_icon_for_stat(stat_name)
	if icon != null:
		_icon.texture = icon

	_stat_name_label.text = _format_stat_name(stat_name)

	var normalized: float = clamp(new_value / max_value, 0.0, 1.0)
	_progress_bar.value = normalized * max_value

	if show_change:
		_progress_bar.tooltip_text = "%s: %.2f → %.2f" % [_stat_name_label.text, current_value, new_value]
	else:
		_progress_bar.tooltip_text = "%s: %.2f" % [_stat_name_label.text, new_value]

## Formats snake_case stat name to Title Case.
func _format_stat_name(stat_name: String) -> String:
	var words: PackedStringArray = stat_name.split("_")
	var formatted_words: Array[String] = []
	for word in words:
		if word.length() > 0:
			formatted_words.append(word.capitalize())
	return " ".join(formatted_words)

## Returns the icon matching [param stat_name], or null if unmapped.
func _get_icon_for_stat(stat_name: String) -> Texture2D:
	match stat_name:
		"aoe_range":
			return _ICON_AOE_RANGE
		"damage":
			return _ICON_ATTACK
		"chain_damage_falloff":
			return _ICON_ELECTRICITY_CHAIN_FALLOFF
		"damage_multiplier":
			return _ICON_ATTACK_MULTIPLIER
		"projectile_count":
			return _ICON_BULLETS
		"aoe_tick", "burn_damage_base":
			return _ICON_BURN_DAMAGE
		"aoe_duration", "burn_duration":
			return _ICON_BURN_DURATION
		"electrify_tick_damage":
			return _ICON_ELECTRICITY_BASE
		"chain_bounces":
			return _ICON_ELECTRICITY_CHAIN
		"chain_range":
			return _ICON_ELECTRICITY_CHAIN_RANGE
		"electrify_duration":
			return _ICON_ELECTRICITY_DURATION
		"electrify_tick_interval":
			return _ICON_ELECTRICITY_INTERVAL
		"electrify_slow_amount":
			return _ICON_ELECTRICITY_SLOW
		"fire_rate":
			return _ICON_FIRE_RATE
		"pierce_count":
			return _ICON_PIERCE_COUNT
		"pierce_reduction":
			return _ICON_PIERCE_REDUCTION
		"shoot_range":
			return _ICON_RANGE
		"speed":
			return _ICON_SPEED
		"spread_angle":
			return _ICON_SPREAD
		_:
			return null
