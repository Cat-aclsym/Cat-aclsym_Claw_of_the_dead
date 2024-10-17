## © [2024] A7 Studio. All rights reserved. Trademark.
## File:	debug_console/debug_console.gd
## Debug console.
## Take commands, return informations and execute functions
##
## Author: Benjamin Borello
## Created: 06/12/2023
class_name DebugConsole
extends Control

var open: bool = false

@onready var output: RichTextLabel = $TextLabel
@onready var input: TextEdit = $TextEdit
@onready var command_handler: CommandHandler = $CommandHandler


func _ready():
	Global.debug_console = self


func _process(_delta: float) -> void:
	_listen_inputs()


# Output text to console
func output_text(text: String) -> void:
	input.text = ""
	output.text += "\n{0}".format([text])


# Yield error to console
func output_error(text: String) -> void:
	input.text = ""
	output.text += "\n{1}{0}{2}".format([
		text,
		"[color=red]",
		"[/color]"
	])


# Listend for debug console related keybinds
func _listen_inputs() -> void:
	if Input.is_action_just_pressed("toggle_console"):
		open = not open
		_update()

	if Input.is_action_just_pressed("console_push"):
		var input_text: String = input.text
		_process_command(input_text)


# Try to execute console command
func _process_command(in_text: String) -> void:
	# Remove all escapes characters from input
	var text: String = in_text.strip_escapes()
	if text.length() == 0: return

	# Print output
	output_text("> {0}".format([text]))

	# Extracts tokens from input
	var tokens := Array(text.split(" "))

	# trim it
	for i in range(tokens.count("")):
		tokens.erase("")

	if tokens.size() == 0:
		return

	# First word of the command is the "main" command word
	var found: bool = false
	var command_token: String = tokens.pop_front()

	# Find command into valids command
	for command in command_handler.valid_commands:
		if command["command"] != command_token:
			continue

		if command["args"].size() != tokens.size():
			output_error("<!> Failure executing command '{0}' expected {1} parameters".format([command_token, command["args"].size()]))
			return

		for i in range(tokens.size()):
			if not _check_type(tokens[i], command["args"][i]):
				output_error("<!> Failure executing command '{0}' parameter {1} ('{2}') if of wrong type.".format([
					command_token,
					i+1,
					tokens[i]
				]))
				return
		found = true
		output_text(command_handler.callv(command_token, tokens))

	if not found:
		output_error("<!> Unknow command !")


# Verify if executed command has correct arguments
func _check_type(in_string: String, in_type: CommandHandler.Types) -> bool:
	if in_type == command_handler.Types.ARG_INT:
		return in_string.is_valid_int()
	if in_type == command_handler.Types.ARG_FLOAT:
		return in_string.is_valid_float()
	if in_type == command_handler.Types.ARG_STRING:
		return true
	if in_type == command_handler.Types.ARG_FLOAT:
		return in_string == "true" or in_string == "false"
	return false


# Update console visibility
func _update() -> void:
	visible = open
