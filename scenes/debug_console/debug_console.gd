## File:	debug_console/debug_console.gd
## Debug console. 
## Take commands and return informations or execute functions 
##
## Created: 06/12/2023
extends Control

var open: bool = false

@onready var output: RichTextLabel = $TextLabel
@onready var input: TextEdit = $TextEdit
@onready var command_handler: CommandHandler = $CommandHandler


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	_listen_inputs()


func output_text(text: String) -> void:
	input.text = ""
	output.text += "\n{0}".format([text])
	
	
func output_error(text: String) -> void:
	input.text = ""
	output.text += "\n{1}{0}{2}".format([
		text,
		"[color=red]",
		"[/color]"
	])


func _listen_inputs() -> void:
	if (Input.is_action_just_pressed("toggle_console")):
		open = !open
		_update()
		
	if (Input.is_action_just_pressed("console_push")):
		var input_text: String = input.text
		_process_command(input_text)


func _process_command(in_text: String) -> void:
	# Remove all escapes characters from input
	var text: String = in_text.strip_escapes()
	if (text.length() == 0): return
	
	# Print output
	output_text(">>> {0}".format([text]))
	
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
		if (command["command"] != command_token): 
			continue
		
		if (command["args"].size() != tokens.size()):
			output_error("<!> Failure executing command '{0}' expected {1} parameters".format([command_token, command["args"].size()]))
			return
			
		for i in range(tokens.size()):
			if (!_check_type(tokens[i], command["args"][i])):
				output_error("<!> Failure executing command '{0}' parameter {1} ('{2}') if of wrong type.".format([
					command_token,
					i+1,
					tokens[i]
				]))
				return
		found = true
		output_text(command_handler.callv(command_token, tokens))
	
	if (!found):
		output_error("<!> Unknow command !")


func _check_type(in_string: String, in_type: CommandHandler.Types):
	if (in_type == command_handler.Types.ARG_INT):
		return in_string.is_valid_int()
	if (in_type == command_handler.Types.ARG_FLOAT):
		return in_string.is_valid_float()
	if (in_type == command_handler.Types.ARG_STRING):
		return true
	if (in_type == command_handler.Types.ARG_FLOAT):
		return (in_string == "true" or in_string == "false")
	return false

	
func _update() -> void:
	visible = open
