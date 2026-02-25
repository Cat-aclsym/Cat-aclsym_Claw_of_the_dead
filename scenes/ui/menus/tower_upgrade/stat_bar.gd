## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Displays a stat bar with icon, name and progress bar.
class_name StatBar
extends HBoxContainer

@onready var _icon: TextureRect = $VBoxContainer/HBoxContainer/StatIcon
@onready var _progress_bar: TextureProgressBar = $VBoxContainer/TextureProgressBar
@onready var _stat_name_label: Label = $VBoxContainer/HBoxContainer/StatName

## Sets up the stat bar with the given data
func setup(stat_name: String, current_value: float, new_value: float, icon: Texture2D, max_value: float = 200.0, show_change: bool = false) -> void:
	# Set icon
	if icon != null:
		_icon.texture = icon
	
	# Format and set stat name
	_stat_name_label.text = _format_stat_name(stat_name)
	
	# Set progress bar value
	var normalized: float = clamp(new_value / max_value, 0.0, 1.0)
	_progress_bar.value = normalized * max_value
	
	# Set tooltip
	var tooltip: String
	if show_change:
		tooltip = "%s: %.2f → %.2f" % [_stat_name_label.text, current_value, new_value]
	else:
		tooltip = "%s: %.2f" % [_stat_name_label.text, new_value]
	_progress_bar.tooltip_text = tooltip

## Formats stat name for display
func _format_stat_name(stat_name: String) -> String:
	# Convert snake_case to Title Case
	var words: PackedStringArray = stat_name.split("_")
	var formatted_words: Array[String] = []
	
	for word in words:
		if word.length() > 0:
			formatted_words.append(word.capitalize())
	
	return " ".join(formatted_words)
