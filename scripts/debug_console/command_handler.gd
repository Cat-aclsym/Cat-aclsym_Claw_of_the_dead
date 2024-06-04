## File:	debug_console/command_handler.gd
## Handler for debug console commands
##
## Author: Benjamin Borello
## Created: 06/12/2023
class_name CommandHandler
extends Control


enum Types {
	ARG_INT,
	ARG_STRING,
	ARG_BOOL,
	ARG_FLOAT
}


const valid_commands = [
	{
		"command": "help",
		"description" : "Display list of all commands and their description.",
		"args": []
	},
	{
		"command": "foo",
		"description" : "Test command",
		"args": [Types.ARG_STRING, Types.ARG_INT]
	},
	{
		"command": "exit",
		"description" : "Exit the program.",
		"args": []
	},
	{
		"command": "set_money",
		"description" : "Change current amount of money",
		"args": [Types.ARG_INT]
	},
]

# Print all available commands with their description and args
func help() -> String:
	var out: String = ""
	
	var first := true
	for command in valid_commands:
		if (!first):
			out += "\n"
		out += "\t- {0} ".format([command["command"]])
		
		for arg in command["args"]:
			out += "{0} ".format([_type_to_string(arg)])
			
		out += "\n\t\t {0}".format([command["description"]])
		first = false
			
	return out


# Exemple command
func foo(what, amount) -> String:
	return "foo command has been call with INT {1} and STR '{0}' args".format([what, amount])


# Exit game
func exit() -> String:
	get_tree().quit()
	return ""
	
	
func set_money(amount) -> String:
	if not ILevel.current_level:
		return "You must be in a level to use this method"
		
	ILevel.current_level.coins = int(amount)
	return "money =  {0}".format([amount])

# Types enum to str
func _type_to_string(in_type: Types) -> String:
	if (in_type == Types.ARG_INT):
		return "INT"
	if (in_type == Types.ARG_FLOAT):
		return "FLOAT"
	if (in_type == Types.ARG_STRING):
		return "STR"
	if (in_type == Types.ARG_BOOL):
		return "BOOL"
		
	return "fuck"
