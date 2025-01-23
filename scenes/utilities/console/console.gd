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
@onready var suggestions_label: RichTextLabel = %Suggestions

var _available_commands: Array[String] = []
var _current_suggestions: Array[String] = []
var _suggestion_index: int = -1

# core
func _ready() -> void:
	Global.console = self
	input.grab_focus()
	_load_available_commands()
	suggestions_label.hide()

	# Connect signals
	SignalUtil.connects([
		{SignalUtil.WHO: input, SignalUtil.WHAT: "text_changed", SignalUtil.TO: _on_input_text_changed}
	])


func _load_available_commands() -> void:
	var cmd_dir := DirAccess.open(COMMANDS_DIRECTORY)
	assert(cmd_dir != null, "Failed to open commands directory")

	for path in cmd_dir.get_files():
		if path.ends_with(".gd"):
			_available_commands.append(path.trim_suffix(".gd"))
	# Sort commands alphabetically
	_available_commands.sort()

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
	_clear_suggestions()

# private
func _listen_inputs() -> void:
	if Input.is_action_just_pressed("toggle_console"):
		visible = not visible
		if visible:
			input.grab_focus()
		else:
			_clear_suggestions()

	if Input.is_action_just_pressed("ui_focus_next"): # Tab key
		_handle_tab_completion()
		return

	if Input.is_action_just_pressed("ui_cancel"):
		if suggestions_label.visible:
			_clear_suggestions()
		else:
			visible = false
		return

	if Input.is_action_just_pressed("ui_up"):
		_navigate_suggestions(-1)
		return

	if Input.is_action_just_pressed("ui_down"):
		_navigate_suggestions(1)
		return

	if Input.is_action_just_pressed("console_push"):
		if suggestions_label.visible:
			_complete_suggestion()
			return

		push_command(input.text)
		input.text = ""
		_clear_suggestions()
		return

func _on_input_text_changed() -> void:
	if _suggestion_index >= 0 and Input.is_action_just_pressed("ui_focus_next"):
		return

	_update_suggestions()

func _handle_tab_completion() -> void:
	if _current_suggestions.is_empty():
		_update_suggestions()
		return

	_complete_suggestion()

func _complete_suggestion() -> void:
	if _suggestion_index >= 0 and _suggestion_index < _current_suggestions.size():
		input.text = _current_suggestions[_suggestion_index] + " "
		input.set_caret_column(input.text.length())
		_clear_suggestions()

func _update_suggestions() -> void:
	_current_suggestions.clear()
	_suggestion_index = -1

	var current_input := input.text.strip_edges()
	if current_input.is_empty():
		_clear_suggestions()
		return

	for cmd in _available_commands:
		# Only suggest if it begins with current input but isn't exactly the same
		if cmd.begins_with(current_input) and cmd != current_input:
			_current_suggestions.append(cmd)

	if not _current_suggestions.is_empty():
		_show_suggestions()
	else:
		_clear_suggestions()

func _show_suggestions() -> void:
	var suggestions_text := "[code]"
	for i in range(_current_suggestions.size()):
		var cmd := _current_suggestions[i]
		suggestions_text += ("→ " if i == _suggestion_index else "  ") + cmd + "\n"
	suggestions_text += "[/code]"

	suggestions_label.text = suggestions_text
	suggestions_label.show()

func _clear_suggestions() -> void:
	_current_suggestions.clear()
	_suggestion_index = -1
	suggestions_label.hide()

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

func _navigate_suggestions(direction: int) -> void:
	if _current_suggestions.is_empty():
		return

	if _suggestion_index == -1:
		_suggestion_index = 0 if direction > 0 else _current_suggestions.size() - 1
	else:
		_suggestion_index = (_suggestion_index + direction) % _current_suggestions.size()
		if _suggestion_index < 0:
			_suggestion_index = _current_suggestions.size() - 1

	_show_suggestions()
