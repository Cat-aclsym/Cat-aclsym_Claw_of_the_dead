## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Displays a stat entry with icon on the left, name label and tick icons on the right.
class_name StatBar
extends HBoxContainer

const MAX_STAT_VALUE: float = 200.0
## Bullet stat keys that are visual/internal only and must not be shown in the UI.
const SKIP_BULLET_STATS: Array[String] = [
	"is_charging",
	"lightning_blue_tint_strength",
	"lightning_width_scale",
]
const TICK_COUNT: int = 15
const TICK_EMPTY: Texture2D = preload("res://assets/ui/icons/stat_tick_empty.png")
const TICK_FULL: Texture2D = preload("res://assets/ui/icons/stat_tick_full.png")
const TICK_SIZE: int = 28

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
## [br] [param stat_name] The stat identifier used for icon lookup and label text ([code]STAT.<NAME>[/code] translation key).
## [br] [param current_value] The current stat value before the upgrade.
## [br] [param new_value] The stat value after the upgrade.
## [br] [param max_value] The reference ceiling for normalizing tick count.
## [br] [param show_change] If true, blinking ticks highlight the changed portion.
func setup(stat_name: String, current_value: float, new_value: float, max_value: float = MAX_STAT_VALUE, show_change: bool = false) -> void:
	var icon: Texture2D = StatIcon.for_stat(stat_name)
	if icon != null:
		_icon.texture = icon

	_stat_name_label.text = tr("STAT.%s" % stat_name.to_upper())

	var current_ticks: int = int(round(clamp(current_value / max_value, 0.0, 1.0) * TICK_COUNT))
	var new_ticks: int = int(round(clamp(new_value / max_value, 0.0, 1.0) * TICK_COUNT))

	for i: int in TICK_COUNT:
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
