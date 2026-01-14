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

# Built-in functions
func _ready() -> void:
	Global.console = self
	input.grab_focus()
	_load_available_commands()
	suggestions_label.hide()
	suggestions_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	push_command("help")

	SignalUtil.connects([
		{SignalUtil.WHO: input, SignalUtil.WHAT: "text_changed", SignalUtil.TO: _on_input_text_changed},
		{SignalUtil.WHO: input, SignalUtil.WHAT: "gui_input", SignalUtil.TO: _on_input_gui_input}
	])


func _process(_delta: float) -> void:
	_listen_inputs()


# Public functions
## Pushes text to the console output.
func push_text(text: String, save: bool = true) -> void:
	output.text += "%s\n" % text

	if Global.debug and save:
		Log.save_message(text)


## Pushes colored text to the console output.
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
	command = command.strip_edges()
	if command.is_empty():
		return

	push_text("> %s" % command)
	_process_command(command)
	_clear_suggestions()


# Private functions
func _load_available_commands() -> void:
	var cmd_dir := DirAccess.open(COMMANDS_DIRECTORY)
	assert(cmd_dir != null, "Failed to open commands directory")

	for path in cmd_dir.get_files():
		if path.ends_with(".gd"):
			_available_commands.append(path.trim_suffix(".gd"))
	_available_commands.sort()


func _listen_inputs() -> void:
	if Input.is_action_just_pressed("toggle_console"):
		visible = not visible
		if visible:
			input.grab_focus()
		else:
			_clear_suggestions()

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
		push_command(input.text)
		input.text = ""
		_clear_suggestions()
		return

func _on_input_text_changed() -> void:
	if _suggestion_index >= 0 and (Input.is_action_just_pressed("ui_focus_next") or Input.is_key_pressed(KEY_TAB)):
		return

	_update_suggestions()

func _on_input_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB:
			_handle_tab_completion()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE and event.ctrl_pressed:
			_update_suggestions()
			get_viewport().set_input_as_handled()

func _handle_tab_completion() -> void:
	if _current_suggestions.is_empty():
		_update_suggestions()
		if _current_suggestions.is_empty():
			return

	_complete_suggestion()

func _complete_suggestion() -> void:
	if _current_suggestions.is_empty():
		return

	# If nothing is selected, select the first item
	if _suggestion_index == -1:
		_suggestion_index = 0

	var full_input := input.text
	var parts := full_input.split(" ", false)
	var is_typing_args := parts.size() > 1 or (full_input.ends_with(" ") and not full_input.is_empty())

	if is_typing_args:
		# If we are typing args, we only switch the selected suggestion in the list
		# but we don't change the command name in the input
		_show_suggestions()
		return

	var completed_command := _current_suggestions[_suggestion_index]
	input.text = completed_command + " "
	input.set_caret_column(input.text.length())

	# Stay open if command has arguments
	var cmd_path := "%s/%s.gd" % [COMMANDS_DIRECTORY, completed_command]
	var has_args := false
	if FileAccess.file_exists(cmd_path):
		var cmd_script = load(cmd_path)
		if cmd_script:
			var cmd_instance: ICommand = cmd_script.new()
			if cmd_instance.has_method("get_args"):
				has_args = not cmd_instance.get_args().is_empty()
			if not has_args:
				has_args = not cmd_instance.expected_args_types().is_empty()

	if has_args:
		# Recalculate suggestions for the new command text
		_update_suggestions()
	else:
		_clear_suggestions()

func _update_suggestions() -> void:
	_current_suggestions.clear()
	_suggestion_index = -1

	var full_input := input.text
	if full_input.strip_edges().is_empty():
		_clear_suggestions()
		return

	var parts := full_input.split(" ", false)
	if parts.is_empty():
		_clear_suggestions()
		return

	var command_prefix := parts[0]
	var is_typing_args := parts.size() > 1 or full_input.ends_with(" ")

	if is_typing_args:
		var cmd := _find_command(command_prefix, true)
		if cmd:
			var args_def := cmd.get_args()
			if not args_def.is_empty():
				var args_typed := parts.size() - 1
				if full_input.ends_with(" "):
					if args_typed >= args_def.size():
						_clear_suggestions()
						return
				else:
					if args_typed > args_def.size():
						_clear_suggestions()
						return

	for cmd in _available_commands:
		if is_typing_args:
			# If we are typing arguments, only suggest the exact command match
			if cmd == command_prefix:
				_current_suggestions.append(cmd)
		else:
			# If we are typing the command, suggest everything that starts with it
			if cmd.begins_with(command_prefix):
				_current_suggestions.append(cmd)

	if not _current_suggestions.is_empty():
		_show_suggestions()
	else:
		_clear_suggestions()

func _show_suggestions() -> void:
	var full_input := input.text
	var parts := full_input.split(" ", false)
	var parts_no_empty: Array[String] = []
	for p in parts:
		if not p.is_empty():
			parts_no_empty.append(p)

	var current_arg_index := parts_no_empty.size() - 1
	if full_input.ends_with(" "):
		current_arg_index += 1

	var suggestions_text := "[code][font_size=14]"
	for i in range(_current_suggestions.size()):
		var cmd_token := _current_suggestions[i]
		var is_selected := (i == _suggestion_index)
		var line := ("→ " if is_selected else "  ")

		if is_selected:
			line += "[b]"

		line += cmd_token

		# Try to show arguments hint
		var cmd_path := "%s/%s.gd" % [COMMANDS_DIRECTORY, cmd_token]
		if FileAccess.file_exists(cmd_path):
			var cmd_script = load(cmd_path)
			if cmd_script:
				var cmd_instance: ICommand = cmd_script.new()
				if cmd_instance.has_method("get_args"):
					var args: Array = cmd_instance.get_args()
					if not args.is_empty():
						for j in range(args.size()):
							var arg_def: Dictionary = args[j]
							var arg_name: String = arg_def.get("name", "arg")
							var type_str: String = cmd_instance.type_to_string(arg_def.get("type", 0))
							var is_current_arg := (j + 1 == current_arg_index)

							var arg_text := ""
							if arg_def.get("optional", false):
								arg_text = " [%s: %s]" % [arg_name, type_str]
							else:
								arg_text = " <%s: %s>" % [arg_name, type_str]

							if is_current_arg:
								line += "[b][u]" + arg_text + "[/u][/b]"
							else:
								line += arg_text
					else:
						# Fallback for commands not updated yet
						var old_args := cmd_instance.expected_args_types()
						for j in range(old_args.size()):
							var type_enum := old_args[j]
							var is_current_arg := (j + 1 == current_arg_index)
							var arg_text := " <%s>" % cmd_instance.type_to_string(type_enum)
							if is_current_arg:
								line += "[b][u]" + arg_text + "[/u][/b]"
							else:
								line += arg_text

		if is_selected:
			line += "[/b]"

		suggestions_text += line + "\n"
	suggestions_text += "[/font_size][/code]"
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

func _find_command(command_token: String, silent: bool = false) -> ICommand:
	var cmd_dir := DirAccess.open(COMMANDS_DIRECTORY)
	assert(cmd_dir != null, "Failed to open commands directory")

	var cmd_paths: PackedStringArray = cmd_dir.get_files()
	for path in cmd_paths:
		if path == command_token + ".gd":
			return load("%s/%s" % [COMMANDS_DIRECTORY, path]).new()

	if not silent:
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
