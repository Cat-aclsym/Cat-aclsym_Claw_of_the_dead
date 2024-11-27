## © [2024] A7 Studio. All rights reserved. Trademark.
##
## In-game debug console for executing commands and displaying output.
## Provides a command-line interface for debugging and development purposes.
## Supports custom commands and colored output.
class_name Console extends Control

const COMMANDS_DIRECTORY: String = "res://scripts/commands"
const CONSOLE_COLOR_ERROR: String = "#fb4934"
const CONSOLE_COLOR_DEBUG: String = "#689d6a"

@onready var output: RichTextLabel = %Output
@onready var input: TextEdit = %Input


# core
func _ready() -> void:
	Global.console = self
	input.grab_focus()


func _process(_delta: float) -> void:
	_listen_inputs()


# public
## Pushes text to the console output.
##
## If [param save] is true and debug mode is active, the message will be logged.
func push_text(text: String, save: bool = true) -> void:
	output.text += "%s\n" % text

	if Global.debug and save:
		Log.save_message(text)


## Pushes colored text to the console output.
##
## Uses BBCode for coloring. If debug mode is active, saves the uncolored text to log.
func push_color(text: String, color: String) -> void:
	var colored_text: String = "[color=%s]%s[/color]" % [color, text]

	push_text(colored_text, false)
	if Global.debug:
		Log.save_message(text)


## Pushes an error message in red color.
func push_error(text: String) -> void:
	push_color(text, CONSOLE_COLOR_ERROR)


## Pushes a debug message in green color.
func push_debug(text: String) -> void:
	push_color(text, CONSOLE_COLOR_DEBUG)


## Executes a command string in the console.
func push_command(command: String) -> void:
	command = command.strip_escapes()
	if command.is_empty():
		return

	push_text("> %s" % command)
	_process_command(command)


# private
func _listen_inputs() -> void:
	if Input.is_action_just_pressed("toggle_console"):
		visible = not visible
		if visible:
			input.grab_focus()

	if Input.is_action_just_pressed("console_push"):
		push_command(input.text)
		input.text = ""


func _process_command(command: String) -> void:
	var tokens := Array(command.split(" "))

	for i in range(tokens.count("")):
		tokens.erase("")

	if tokens.is_empty():
		return

	var command_token: String = tokens.pop_front()

	var cmd: ICommand = _find_command(command_token)
	if not cmd:
		return

	var err: int = cmd.execute(self, tokens)
	if err == OK:
		return

	push_error("%d" % err)


func _find_command(command_token: String) -> ICommand:
	var cmd_dir := DirAccess.open(COMMANDS_DIRECTORY)
	assert(cmd_dir != null, "Failed to open commands directory")

	var cmd_paths: PackedStringArray = cmd_dir.get_files()
	for path in cmd_paths:
		if path == command_token + ".gd":
			return load("%s/%s" % [COMMANDS_DIRECTORY, path]).new()

	push_error("No command named '%s'" % command_token)
	return null
