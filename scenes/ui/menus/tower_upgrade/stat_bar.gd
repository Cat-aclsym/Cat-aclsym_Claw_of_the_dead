## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Displays a stat entry with icon on the left, name label and tick icons on the right.
class_name StatBar
extends HBoxContainer

const TICK_FULL: Texture2D = preload("res://assets/ui/icons/stat-tick-full.png")
const TICK_EMPTY: Texture2D = preload("res://assets/ui/icons/stat-tick-empty.png")
const TICK_COUNT: int = 15
const TICK_SIZE: int = 28

const MAX_STAT_VALUE: float = 200.0
## Bullet stat keys that are visual/internal only and must not be shown in the UI.
const SKIP_BULLET_STATS: Array[String] = [
	"is_charging",
	"lightning_blue_tint_strength",
	"lightning_width_scale",
]

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

var _blinking_ticks: Array[TextureRect] = []

@onready var _icon: TextureRect = $StatIcon
@onready var _stat_name_label: Label = $ContentColumn/StatName
@onready var _ticks_container: HBoxContainer = $ContentColumn/TicksContainer

func _ready() -> void:
	# Run during game pause so the upgrade menu animation plays correctly.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if _blinking_ticks.is_empty():
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var alpha: float = lerp(0.15, 1.0, sin(t * TAU / 1.6) * 0.5 + 0.5)
	for tick: TextureRect in _blinking_ticks:
		if is_instance_valid(tick):
			tick.modulate.a = alpha

## Sets up the stat entry with icon, name, and tick icons representing the stat value.
## [br] [param stat_name] The stat identifier used for icon lookup and label text.
## [br] [param current_value] The current stat value before the upgrade.
## [br] [param new_value] The stat value after the upgrade.
## [br] [param max_value] The reference ceiling for normalizing tick count.
## [br] [param show_change] If true, blinking ticks highlight the changed portion.
func setup(stat_name: String, current_value: float, new_value: float, max_value: float = MAX_STAT_VALUE, show_change: bool = false) -> void:
	var icon: Texture2D = _get_icon_for_stat(stat_name)
	if icon != null:
		_icon.texture = icon

	_stat_name_label.text = _format_stat_name(stat_name)

	var current_ticks: int = int(round(clamp(current_value / max_value, 0.0, 1.0) * TICK_COUNT))
	var new_ticks: int = int(round(clamp(new_value / max_value, 0.0, 1.0) * TICK_COUNT))

	for i in TICK_COUNT:
		var is_gained: bool = new_ticks > current_ticks and i >= current_ticks and i < new_ticks
		var is_lost: bool = new_ticks < current_ticks and i >= new_ticks and i < current_ticks
		var is_filled: bool = i < new_ticks or is_lost
		var should_blink: bool = show_change and (is_gained or is_lost)

		if should_blink:
			# Overlay: static empty underneath, blinking full on top.
			var wrapper: Control = Control.new()
			wrapper.custom_minimum_size = Vector2(TICK_SIZE, TICK_SIZE)

			var bg: TextureRect = _make_tick(TICK_EMPTY)
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			wrapper.add_child(bg)

			var fg: TextureRect = _make_tick(TICK_FULL)
			fg.set_anchors_preset(Control.PRESET_FULL_RECT)
			wrapper.add_child(fg)

			_ticks_container.add_child(wrapper)
			_blinking_ticks.append(fg)
		else:
			_ticks_container.add_child(_make_tick(TICK_FULL if is_filled else TICK_EMPTY))

## Creates a TextureRect tick with the shared display settings.
func _make_tick(texture: Texture2D) -> TextureRect:
	var tick: TextureRect = TextureRect.new()
	tick.custom_minimum_size = Vector2(TICK_SIZE, TICK_SIZE)
	tick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tick.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tick.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tick.texture = texture
	return tick

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
