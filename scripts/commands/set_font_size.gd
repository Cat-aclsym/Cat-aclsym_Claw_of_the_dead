## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Changes the font size of the console interface.
## Updates all text elements in the console with the specified font size.
extends ICommand


# Public functions
func description() -> String:
	return "Adjusts the font size of the console interface text."


func get_args() -> Array[Dictionary]:
	return [{"name": "size", "type": Types.ARG_INT}]


# Private functions
func _execute(console: Console, args: Array) -> int:
	var new_size: int = int(args[0])
	if new_size <= 0:
		console.push_error("Font size must be positive")
		return ERR_UNKNOWN_BEHAVIOR

	console.input.add_theme_font_size_override("font_size", new_size)
	console.output.add_theme_font_size_override("bold_italics_font_size", new_size)
	console.output.add_theme_font_size_override("bold_font_size", new_size)
	console.output.add_theme_font_size_override("italics_font_size", new_size)
	console.output.add_theme_font_size_override("normal_font_size", new_size)
	console.output.add_theme_font_size_override("mono_font_size", new_size)
	console.suggestions_label.add_theme_font_size_override("font_size", new_size)

	console.push_text("Set font size to %d." % new_size)

	return OK
