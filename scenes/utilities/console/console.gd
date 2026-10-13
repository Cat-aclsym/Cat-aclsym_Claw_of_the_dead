## © [2026] A7 Studio. All rights reserved. Trademark.
##
## In-game debug console for executing commands and displaying output.
## Provides a command-line interface for debugging and development purposes.
## Supports custom commands and colored output.
class_name Console extends Control


const COMMANDS_DIRECTORY: String = "res://scripts/commands"
const CONSOLE_COLOR_ERROR: String = "#fb4934"


## Color for debug messages
@export var color_debug: Color = Color("#689d6a")
## Color for error messages
@export var color_error: Color = Color("#fb4934")
## Directory where command scripts are located
@export_dir var commands_directory: String = "res://scripts/commands"

var _command_history: Array[String] = []
var _commands: Dictionary[String, ICommand] = {}
var _current_suggestions: Array[String] = []
var _history_index: int = -1
var _history_stash: String = ""
var _is_navigating_history: bool = false
var _is_output_manual_scroll: bool = false
var _suggestion_index: int = -1

@onready var input: TextEdit = %Input
@onready var output: RichTextLabel = %Output
@onready var suggestions_label: RichTextLabel = %Suggestions

# Built-in functions
func _ready() -> void:
	if not Global.debug:
		queue_free()
		return
	Global.console = self
	set_process_input(true)
	# Hidden console must not focus the TextEdit: Android shows the soft keyboard for a focused TextEdit
	# even when the control is not visible.
	input.virtual_keyboard_enabled = visible
	if visible:
		input.grab_focus()
	output.scroll_active = true
	output.scroll_following = false
	output.selection_enabled = true
	output.mouse_filter = Control.MOUSE_FILTER_STOP
	suggestions_label.hide()
	suggestions_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	push_command("help", false)

	SignalUtil.connects([
		{SignalUtil.WHO: input, SignalUtil.WHAT: "text_changed", SignalUtil.TO: _on_input_text_changed},
		{SignalUtil.WHO: input, SignalUtil.WHAT: "gui_input", SignalUtil.TO: _on_input_gui_input}
	])


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_output_wheel(event.button_index)
			get_viewport().set_input_as_handled()
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			input.grab_focus()
			get_viewport().set_input_as_handled()
			return


func _process(_delta: float) -> void:
	_listen_inputs()


# Public functions
## Returns every command script found in [member commands_directory], instantiated once on first use and keyed by command name.
func get_commands() -> Dictionary[String, ICommand]:
	if _commands.is_empty():
		_load_commands()
	return _commands


## Pushes colored text to the console output.
func push_color(text: String, color_val: Variant) -> void:
	var color_str: String = ""
	if color_val is Color:
		color_str = "#" + color_val.to_html(false)
	else:
		color_str = str(color_val)

	push_text("[color=%s]%s[/color]" % [color_str, text])


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

## Pushes a debug message in green color.
func push_debug(text: String) -> void:
	push_color(text, color_debug)

func push_error_(text: String) -> void:
	push_color(text, CONSOLE_COLOR_ERROR)


## Pushes text to the console output. Only displays it: [Log] alone writes the log file.
func push_text(text: String) -> void:
	output.append_text("%s\n" % text)
	if not _is_output_manual_scroll:
		output.scroll_to_line(output.get_line_count())


# Private functions
## Builds a rich text signature line for the given command, the argument at [param current_arg_index] (command name = 0) is highlighted.
func _build_signature(cmd: ICommand, command_name: String, current_arg_index: int, current_args: Array) -> String:
	return "  %s %s  — %s" % [command_name, cmd.get_signature(current_args, current_arg_index - 1), cmd.description()]

## Clears and hides suggestions.
func _clear_suggestions() -> void:
	_current_suggestions.clear()
	_suggestion_index = -1
	suggestions_label.hide()

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
	var completed_cmd: ICommand = get_commands().get(completed_command)
	if completed_cmd != null and not completed_cmd.get_args().is_empty():
		# Recalculate suggestions for the new command text
		_update_suggestions()
	else:
		_clear_suggestions()

## Finds a command in the registry, logs an error in the console unless [param silent].
func _find_command(command_token: String, silent: bool = false) -> ICommand:
	var cmd: ICommand = get_commands().get(command_token)
	if cmd == null and not silent:
		push_error_("No command named '%s'" % command_token)
	return cmd

## Handles the tab-completion logic.
func _handle_tab_completion() -> void:
	if _current_suggestions.is_empty():
		_update_suggestions()
		if _current_suggestions.is_empty():
			return

	_complete_suggestion()


## Listens for global console inputs (toggle, push, cancel).
func _listen_inputs() -> void:
	if Input.is_action_just_pressed("toggle_console"):
		visible = not visible
		if visible:
			input.virtual_keyboard_enabled = true
			input.grab_focus()
		else:
			_release_console_text_input()
			_clear_suggestions()

	if Input.is_action_just_pressed("ui_cancel"):
		if suggestions_label.visible:
			_clear_suggestions()
		elif visible:
			visible = false
			_release_console_text_input()
			_clear_suggestions()
		return

	if Input.is_action_just_pressed("console_push"):
		push_command(input.text)
		input.text = ""
		_clear_suggestions()
		return

## Instantiates every command script of the commands directory into [member _commands], sorted by name.
func _load_commands() -> void:
	var cmd_dir := DirAccess.open(commands_directory)
	assert(cmd_dir != null, "Failed to open commands directory: " + commands_directory)

	var paths: PackedStringArray = cmd_dir.get_files()
	paths.sort()
	for path: String in paths:
		if not path.ends_with(".gd"):
			continue
		var script: GDScript = load("%s/%s" % [commands_directory, path])
		if script == null:
			Log.trace(Log.Level.ERROR, "Console: failed to load command script %s" % path)
			continue
		_commands[path.trim_suffix(".gd")] = script.new()

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
		elif event.keycode == KEY_PAGEUP or event.keycode == KEY_PAGEDOWN:
			var scroll := output.get_v_scroll_bar()
			var amount := scroll.page if scroll.page > 0 else 200.0
			var delta := -amount if event.keycode == KEY_PAGEUP else amount
			_scroll_output(delta)
			input.accept_event()
		elif (event.keycode == KEY_UP or event.keycode == KEY_DOWN) and event.ctrl_pressed:
			var delta := -40.0 if event.keycode == KEY_UP else 40.0
			_scroll_output(delta)
			input.accept_event()
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

## Callback triggered when console input text changes.
func _on_input_text_changed() -> void:
	if _suggestion_index >= 0 and (Input.is_action_just_pressed("ui_focus_next") or Input.is_key_pressed(KEY_TAB)):
		return

	# Reset history index if user types something manually
	if not _is_navigating_history and _history_index != -1:
		_history_index = -1

	_update_suggestions()

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

	push_error_("%d" % err)


## Drops focus and hides the soft keyboard after the console is closed.
func _release_console_text_input() -> void:
	input.virtual_keyboard_enabled = false
	input.release_focus()
	if OS.get_name() == "Android":
		DisplayServer.virtual_keyboard_hide()


## Scrolls the output and updates follow state.
func _scroll_output(amount: float) -> void:
	var scroll := output.get_v_scroll_bar()
	if not scroll:
		return
	scroll.value = clamp(scroll.value + amount, scroll.min_value, scroll.max_value)
	var at_bottom := scroll.value >= scroll.max_value - scroll.page - 1.0
	_is_output_manual_scroll = not at_bottom

## Handles mouse wheel scrolling for the output.
func _scroll_output_wheel(button_index: int) -> void:
	var scroll := output.get_v_scroll_bar()
	if not scroll:
		return
	var amount := scroll.page / 5.0 if scroll.page > 0 else 50.0
	var delta := -amount if button_index == MOUSE_BUTTON_WHEEL_UP else amount
	_scroll_output(delta)

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
	var typed_args := parts_no_empty.slice(1, parts_no_empty.size() - 1 if not full_input.ends_with(" ") else parts_no_empty.size())

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
			var signature := _build_signature(cmd, command_prefix, current_arg_index, typed_args)
			if not signature.is_empty():
				suggestions_text += "\n" + signature
	else:
		# When listing commands, show signature of selected command
		if _suggestion_index >= 0 and _suggestion_index < _current_suggestions.size():
			var selected_cmd_name := _current_suggestions[_suggestion_index]
			var cmd := _find_command(selected_cmd_name, true)
			if cmd:
				var signature := _build_signature(cmd, selected_cmd_name, -1, [])
				if not signature.is_empty():
					suggestions_text += "\n" + signature

	suggestions_text += "[/font_size][/code]"
	suggestions_label.text = suggestions_text
	suggestions_label.show()

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
	var has_trailing_space := full_input.ends_with(" ")
	var is_typing_args := parts.size() > 1 or has_trailing_space
	var args_typed := parts.size() - 1 if has_trailing_space else parts.size() - 2
	var args_def: Array = []

	if is_typing_args:
		var cmd := _find_command(command_prefix, true)
		if cmd:
			var current_args := parts.slice(1, parts.size() - 1 if not has_trailing_space else parts.size())
			args_def = cmd.get_args_dynamic(current_args)
			if not args_def.is_empty():
				if args_typed >= args_def.size():
					_clear_suggestions()
					return

				var current_arg_def: Dictionary = args_def[args_typed]
				var arg_type: int = current_arg_def.get("type", ICommand.Types.ARG_UNKNOWN)
				var current_input := parts[-1] if not has_trailing_space else ""

				match arg_type:
					ICommand.Types.ARG_CHALLENGE:
						var challenge_dir := DirAccess.open("res://data/challenges/")
						if challenge_dir:
							for file_name in challenge_dir.get_files():
								if file_name.ends_with(".json"):
									var challenge_id := file_name.trim_suffix(".json")
									if challenge_id.to_lower().begins_with(current_input.to_lower()):
										_current_suggestions.append(challenge_id)
					ICommand.Types.ARG_COMMAND:
						for cmd_name: String in get_commands():
							if cmd_name.to_lower().begins_with(current_input.to_lower()):
								_current_suggestions.append(cmd_name)
					ICommand.Types.ARG_ENEMY:
						for enemy_id: String in StatsDB.get_enemy_ids():
							if enemy_id.to_lower().begins_with(current_input.to_lower()):
								_current_suggestions.append(enemy_id)
					ICommand.Types.ARG_ENUM:
						var enum_values: Array = current_arg_def.get("enum_values", [])
						for value: String in enum_values:
							if value.to_lower().begins_with(current_input.to_lower()):
								_current_suggestions.append(value)
					ICommand.Types.ARG_INGAME_TOWER:
						var current_lvl: ILevel = ILevel.current_level
						if current_lvl and current_lvl.map:
							for child: Node in current_lvl.map.get_children():
								if child is ITower and child.name.to_lower().begins_with(current_input.to_lower()):
									_current_suggestions.append(String(child.name))
					ICommand.Types.ARG_LEVEL:
						var level_dir := DirAccess.open("res://data/levels/")
						if level_dir:
							for file_name in level_dir.get_files():
								if file_name.ends_with(".json"):
									var level_id := file_name.trim_suffix(".json")
									if level_id.to_lower().begins_with(current_input.to_lower()):
										_current_suggestions.append(level_id)
					ICommand.Types.ARG_TOWER:
						for tower_id: String in StatsDB.get_tower_ids():
							if tower_id.to_lower().begins_with(current_input.to_lower()):
								_current_suggestions.append(tower_id)
					_:
						pass
	else:
		for cmd_name: String in get_commands():
			if cmd_name.to_lower().begins_with(command_prefix.to_lower()):
				_current_suggestions.append(cmd_name)

	_current_suggestions.sort()

	if not _current_suggestions.is_empty():
		_suggestion_index = 0
		_show_suggestions()
	elif is_typing_args:
		# Show signature even without suggestions when typing args
		_show_suggestions()
	else:
		_clear_suggestions()
