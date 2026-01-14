## © [2024] A7 Studio. All rights reserved. Trademark.
##
## In-game debug console for executing commands and displaying output.
## Provides a command-line interface for debugging and development purposes.
## Supports custom commands and colored output.
class_name Console extends Control

## Directory where command scripts are located
@export_dir var commands_directory: String = "res://scripts/commands"
## Color for error messages
@export var color_error: Color = Color("#fb4934")
## Color for debug messages
@export var color_debug: Color = Color("#689d6a")

@onready var output: RichTextLabel = %Output
@onready var input: TextEdit = %Input
@onready var suggestions_label: RichTextLabel = %Suggestions

var _available_commands: Array[String] = []
var _current_suggestions: Array[String] = []
var _suggestion_index: int = -1
var _command_history: Array[String] = []
var _history_index: int = -1
var _history_stash: String = ""
var _is_navigating_history: bool = false

# Built-in functions
func _ready() -> void:
	Global.console = self
	input.grab_focus()
	_load_available_commands()
	suggestions_label.hide()
	suggestions_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	push_command("help", false)

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
func push_color(text: String, color_val: Variant) -> void:
	var color_str: String = ""
	if color_val is Color:
		color_str = "#" + color_val.to_html(false)
	else:
		color_str = str(color_val)

	var colored_text: String = "[color=%s]%s[/color]" % [color_str, text]

	push_text(colored_text, false)
	if Global.debug:
		Log.save_message(text)


## Pushes an error message in red color.
func push_error(text: String) -> void:
	push_color(text, color_error)


## Pushes a debug message in green color.
func push_debug(text: String) -> void:
	push_color(text, color_debug)


## Executes a command string in the console.
func push_command(command: String, add_to_history: bool = true) -> void:
	command = command.strip_edges()
	if command.is_empty():
		return

	if add_to_history:
		if _command_history.is_empty() or _command_history[-1] != command:
			_command_history.append(command)
	_history_index = -1

	push_text("> %s" % command)
	_process_command(command)
	_clear_suggestions()


# Private functions
## Loads starting command scripts from the commands directory.
func _load_available_commands() -> void:
	var cmd_dir := DirAccess.open(commands_directory)
	assert(cmd_dir != null, "Failed to open commands directory: " + commands_directory)

	for path in cmd_dir.get_files():
		if path.ends_with(".gd"):
			_available_commands.append(path.trim_suffix(".gd"))
	_available_commands.sort()


## Listens for global console inputs (toggle, push, cancel).
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

	if Input.is_action_just_pressed("console_push"):
		push_command(input.text)
		input.text = ""
		_clear_suggestions()
		return

## Callback triggered when console input text changes.
func _on_input_text_changed() -> void:
	if _suggestion_index >= 0 and (Input.is_action_just_pressed("ui_focus_next") or Input.is_key_pressed(KEY_TAB)):
		return

	# Reset history index if user types something manual
	if not _is_navigating_history and _history_index != -1:
		_history_index = -1

	_update_suggestions()

## Callback triggered on console input GUI events.
func _on_input_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB:
			_handle_tab_completion()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE and event.ctrl_pressed:
			_update_suggestions()
			get_viewport().set_input_as_handled()
		elif not _current_suggestions.is_empty() and (event.keycode == KEY_UP or event.keycode == KEY_DOWN):
			if event.keycode == KEY_UP:
				_navigate_suggestions(-1)
			else:
				_navigate_suggestions(1)
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_UP or event.keycode == KEY_DOWN):
			# History navigation: allowed if empty input OR already navigating history
			if input.text.strip_edges().is_empty() or _history_index != -1:
				if event.keycode == KEY_UP:
					_navigate_history(-1)
				else:
					_navigate_history(1)
				get_viewport().set_input_as_handled()
				# Force TextEdit to not move cursor internally
				input.accept_event()
		elif _history_index != -1 and (event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT):
			# Validate history selection by moving cursor
			_history_index = -1

## Handles the tab-completion logic.
func _handle_tab_completion() -> void:
	if _current_suggestions.is_empty():
		_update_suggestions()
		if _current_suggestions.is_empty():
			return

	_complete_suggestion()

## Completes the currently selected suggestion in the input field.
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
		var completed_value := _current_suggestions[_suggestion_index]

		# Replace last part or add to input
		if full_input.ends_with(" "):
			input.text = full_input + completed_value + " "
		else:
			parts[-1] = completed_value
			input.text = " ".join(parts) + " "

		input.set_caret_column(input.text.length())
		_update_suggestions()
		return

	var completed_command := _current_suggestions[_suggestion_index]
	input.text = completed_command + " "
	input.set_caret_column(input.text.length())

	# Stay open if command has arguments
	var cmd_path := "%s/%s.gd" % [commands_directory, completed_command]
	var has_args := false
	if FileAccess.file_exists(cmd_path):
		var cmd_script = load(cmd_path)
		if cmd_script:
			var cmd_instance: ICommand = cmd_script.new()
			if cmd_instance.has_method("get_args"):
				has_args = not cmd_instance.get_args().is_empty()

	if has_args:
		# Recalculate suggestions for the new command text
		_update_suggestions()
	else:
		_clear_suggestions()

## Updates the list of command and argument suggestions.
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
	var args_typed := parts.size() - 1
	var args_def: Array = []

	if is_typing_args:
		var cmd := _find_command(command_prefix, true)
		if cmd:
			args_def = cmd.get_args()
			if not args_def.is_empty():
				if full_input.ends_with(" "):
					if args_typed >= args_def.size():
						_clear_suggestions()
						return
				else:
					if args_typed > args_def.size():
						_clear_suggestions()
						return

	if is_typing_args:
		var cmd := _find_command(command_prefix, true)
		if cmd and args_typed < args_def.size():
			var current_arg_def: Dictionary = args_def[args_typed]
			var arg_type: int = current_arg_def.get("type", 0)
			var current_input := parts[-1] if not full_input.ends_with(" ") else ""

			match arg_type:
				ICommand.Types.ARG_COMMAND:
					for cmd_name in _available_commands:
						if cmd_name.begins_with(current_input):
							_current_suggestions.append(cmd_name)
				ICommand.Types.ARG_TOWER:
					var tower_script = load("res://scenes/gameplay/entities/tower/i_tower.gd")
					if tower_script and tower_script.has_source_code():
						var tower_types = tower_script.get_script_constant_map().get("TowerType")
						if tower_types:
							for tower_type in tower_types.keys():
								if tower_type.begins_with(current_input.to_upper()):
									_current_suggestions.append(tower_type)
				ICommand.Types.ARG_ENEMY:
					var enemy_script = load("res://scenes/gameplay/entities/enemy/i_enemy.gd")
					if enemy_script and enemy_script.has_source_code():
						var enemy_types = enemy_script.get_script_constant_map().get("EnemyType")
						if enemy_types:
							for enemy_type in enemy_types.keys():
								if enemy_type.begins_with(current_input.to_upper()):
									_current_suggestions.append(enemy_type)
				ICommand.Types.ARG_ENUM:
					var enum_values: Array = current_arg_def.get("enum_values", [])
					for value in enum_values:
						if value.begins_with(current_input):
							_current_suggestions.append(value)
				ICommand.Types.ARG_INGAME_TOWER:
					var ilevel_script = load("res://scenes/gameplay/world/level/i_level.gd")
					var itower_script = load("res://scenes/gameplay/entities/tower/i_tower.gd")
					if ilevel_script and itower_script:
						var current_lvl = ilevel_script.get("current_level")
						if current_lvl and current_lvl.get("map"):
							for child in current_lvl.get("map").get_children():
								if child.get_script() == itower_script:
									if child.name.begins_with(current_input):
										_current_suggestions.append(child.name)
				_:
					pass
	else:
		for cmd in _available_commands:
			if cmd.begins_with(command_prefix):
				_current_suggestions.append(cmd)

	_current_suggestions.sort()

	if not _current_suggestions.is_empty():
		_suggestion_index = 0
		_show_suggestions()
	elif is_typing_args:
		# Show signature even without suggestions when typing args
		_show_suggestions()
	else:
		_clear_suggestions()

## Displays the suggestions and current command signature in the suggestions label.
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

	var is_typing_args := parts_no_empty.size() > 1 or (full_input.ends_with(" ") and not full_input.is_empty())
	var command_prefix := parts_no_empty[0] if not parts_no_empty.is_empty() else ""

	var suggestions_text := "[code][font_size=12]"

	# Display suggestion list
	for i in range(_current_suggestions.size()):
		var suggestion_token := _current_suggestions[i]
		var is_selected := (i == _suggestion_index)
		var line := ("→ " if is_selected else "  ")

		if is_selected:
			line += "[b]"

		line += suggestion_token

		if is_selected:
			line += "[/b]"

		suggestions_text += line + "\n"

	# Display command signature
	if is_typing_args and not command_prefix.is_empty():
		# When typing arguments, show signature with current arg highlighted
		var cmd := _find_command(command_prefix, true)
		if cmd:
			var signature := _build_signature(cmd, command_prefix, current_arg_index)
			if not signature.is_empty():
				suggestions_text += "\n" + signature
	else:
		# When listing commands, show signature of selected command
		if _suggestion_index >= 0 and _suggestion_index < _current_suggestions.size():
			var selected_cmd_name := _current_suggestions[_suggestion_index]
			var cmd := _find_command(selected_cmd_name, true)
			if cmd:
				var signature := _build_signature(cmd, selected_cmd_name, -1)
				if not signature.is_empty():
					suggestions_text += "\n" + signature

	suggestions_text += "[/font_size][/code]"
	suggestions_label.text = suggestions_text
	suggestions_label.show()

## Builds a rich text signature for the given command.
func _build_signature(cmd: ICommand, command_name: String, current_arg_index: int) -> String:
	var cmd_args := cmd.get_args()
	var signature := "  " + command_name

	for j in range(cmd_args.size()):
		var arg_def: Dictionary = cmd_args[j]
		var arg_name: String = arg_def.get("name", "arg")
		var arg_type: int = arg_def.get("type", 0)
		var type_str: String = _get_type_string(cmd, arg_def, arg_type)
		var is_current_arg := (j + 1 == current_arg_index)

		var arg_text := ""
		if arg_def.get("optional", false):
			arg_text = " [%s: %s]" % [arg_name, type_str]
		else:
			arg_text = " <%s: %s>" % [arg_name, type_str]

		if is_current_arg:
			signature += "[b][u]" + arg_text + "[/u][/b]"
		else:
			signature += arg_text

	signature += "  — " + cmd.description()
	return signature

## Gets a readable string for an argument type.
func _get_type_string(cmd: ICommand, arg_def: Dictionary, arg_type: int) -> String:
	var type_str: String = cmd.type_to_string(arg_type)
	if arg_type == ICommand.Types.ARG_ENUM:
		var enum_values: Array = arg_def.get("enum_values", [])
		if not enum_values.is_empty():
			type_str = "|".join(enum_values)
	return type_str

## Clears and hides suggestions.
func _clear_suggestions() -> void:
	_current_suggestions.clear()
	_suggestion_index = -1
	suggestions_label.hide()

## Tokenizes and executes a command.
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

## Finds a command script in the commands directory.
func _find_command(command_token: String, silent: bool = false) -> ICommand:
	var cmd_dir := DirAccess.open(commands_directory)
	assert(cmd_dir != null, "Failed to open commands directory")

	var cmd_paths: PackedStringArray = cmd_dir.get_files()
	for path in cmd_paths:
		if path == command_token + ".gd":
			return load("%s/%s" % [commands_directory, path]).new()

	if not silent:
		push_error("No command named '%s'" % command_token)
	return null

## Navigates up/down in the suggestions list.
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

## Navigates through command history.
func _navigate_history(direction: int) -> void:
	if _command_history.is_empty():
		return

	_is_navigating_history = true

	if direction == -1: # UP
		if _history_index == -1:
			_history_stash = input.text
			_history_index = _command_history.size() - 1
		else:
			_history_index = max(0, _history_index - 1)
	else: # DOWN
		if _history_index == -1:
			_is_navigating_history = false
			return

		_history_index += 1
		if _history_index >= _command_history.size():
			_history_index = -1
			input.text = _history_stash
			input.set_caret_column(input.text.length())
			_update_suggestions()
			_is_navigating_history = false
			return

	input.text = _command_history[_history_index]
	input.set_caret_column(input.text.length())
	_update_suggestions()
	_is_navigating_history = false
