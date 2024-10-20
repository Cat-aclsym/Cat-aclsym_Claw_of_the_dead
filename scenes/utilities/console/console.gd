## © [2024] A7 Studio. All rights reserved. Trademark.
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
## Push text to console
func push_text(text: String, save: bool = true) -> void:
	output.text += "%s\n" % text
	
	if Global.debug and save:
		Log.save_message(text)


## Push text to console with specified color
## If debug mode active, save text to log without color
func push_color(text: String, color: String) -> void:
	var colored_text: String = "{1}{0}{2}".format([
		text,
		"[color=%s]" % color,
		"[/color]"
	])

	push_text(colored_text, false)
	if Global.debug:
		Log.save_message(text)


func push_error(text: String) -> void:
	push_color(text, CONSOLE_COLOR_ERROR)


func push_debug(text: String) -> void:
	push_color(text, CONSOLE_COLOR_DEBUG)


## Push command to console to be executed
func push_command(command: String) -> void:
	# Remove all escapes characters from input
	command = command.strip_escapes()
	if command.length() == 0: 
		return

	push_text("> %s" % command)

	_process_command(command)


# private
func _listen_inputs() -> void:
	# toggle console visibility and focus
	if Input.is_action_just_pressed("toggle_console"):
		visible = not visible
		if visible:
			input.grab_focus()

	# push command and clear input content
	if Input.is_action_just_pressed("console_push"):
		push_command(input.text)
		input.text = ""


func _process_command(command: String) -> void:
	# Extracts tokens from input
	var tokens := Array(command.split(" "))

	# trim it
	for i in range(tokens.count("")):
		tokens.erase("")

	if tokens.size() == 0:
		return

	var command_token: String = tokens.pop_front()

	var cmd: ICommand = _find_command(command_token)
	if not cmd:
		return

	var err: int = cmd.execute(self, tokens)
	if err == 0:
		return

	self.push_error("%d" % err)


func _find_command(command_token: String) -> ICommand:
	var cmd_dir := DirAccess.open(COMMANDS_DIRECTORY)
	var cmd_paths: PackedStringArray = cmd_dir.get_files()
	for path in cmd_paths:
		if path == command_token + ".gd":
			return load("%s/%s" % [COMMANDS_DIRECTORY, path]).new()
	
	self.push_error("No command named '%s'" % command_token)
	return null


# signal


# event


# setget
