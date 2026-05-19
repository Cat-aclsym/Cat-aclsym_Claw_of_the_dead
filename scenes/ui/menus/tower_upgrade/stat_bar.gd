## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Displays a stat entry with name label and tick icons.
class_name StatBar
extends VBoxContainer

const TICK_FULL: Texture2D = preload("res://assets/ui/icons/stat-tick-full.png")
const TICK_EMPTY: Texture2D = preload("res://assets/ui/icons/stat-tick-empty.png")
const TICK_COUNT: int = 10
const TICK_SIZE: int = 20

@onready var _stat_name_label: Label = $StatName
@onready var _ticks_container: HBoxContainer = $TicksContainer

## Sets up the stat entry with tick icons representing the stat value.
## [br] [param stat_name] The stat identifier used for the label text.
## [br] [param current_value] The current stat value before the upgrade.
## [br] [param new_value] The stat value after the upgrade.
## [br] [param max_value] The reference ceiling for normalizing tick count.
## [br] [param show_change] If true, blinking ticks highlight the changed portion.
func setup(stat_name: String, current_value: float, new_value: float, max_value: float = 200.0, show_change: bool = false) -> void:
	_stat_name_label.text = _format_stat_name(stat_name)

	var current_ticks: int = int(round(clamp(current_value / max_value, 0.0, 1.0) * TICK_COUNT))
	var new_ticks: int = int(round(clamp(new_value / max_value, 0.0, 1.0) * TICK_COUNT))

	for i in TICK_COUNT:
		var tick: TextureRect = TextureRect.new()
		tick.custom_minimum_size = Vector2(TICK_SIZE, TICK_SIZE)
		tick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tick.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tick.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		var is_gained: bool = new_ticks > current_ticks and i >= current_ticks and i < new_ticks
		var is_lost: bool = new_ticks < current_ticks and i >= new_ticks and i < current_ticks
		var is_filled: bool = i < new_ticks or is_lost

		tick.texture = TICK_FULL if is_filled else TICK_EMPTY
		_ticks_container.add_child(tick)

		if show_change and (is_gained or is_lost):
			_animate_tick(tick)

## Formats snake_case stat name to Title Case.
func _format_stat_name(stat_name: String) -> String:
	var words: PackedStringArray = stat_name.split("_")
	var formatted_words: Array[String] = []
	for word in words:
		if word.length() > 0:
			formatted_words.append(word.capitalize())
	return " ".join(formatted_words)

## Repeating sine fade to highlight a tick that is being gained or lost.
func _animate_tick(tick: TextureRect) -> void:
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(tick, "modulate:a", 0.15, 0.55)
	tween.tween_property(tick, "modulate:a", 1.0, 0.55)
