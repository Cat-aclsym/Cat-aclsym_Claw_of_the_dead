## © [2024] A7 Studio. All rights reserved. Trademark.
## Change font size of console.
extends ICommand


# public
func command_token() -> String:
	return "set_font_size"


func description() -> String:
	return "Set font size of debug console."


func expected_args_types() -> Array[ICommand.Types]:
	return [ICommand.Types.ARG_INT]


# private
func _execute(console: Console, args: Array) -> int:
	var new_size: int = int(args[0])

	console.input.add_theme_font_size_override("font_size", new_size)
	console.output.add_theme_font_size_override("bold_italics_font_size", new_size)
	console.output.add_theme_font_size_override("bold_font_size", new_size)
	console.output.add_theme_font_size_override("italics_font_size", new_size)
	console.output.add_theme_font_size_override("normal_font_size", new_size)
	console.output.add_theme_font_size_override("mono_font_size", new_size)

	console.push_text("Set font size to %d." % new_size)

	return OK