## File:	autoloads/global.gd
## Store global variables.
##
## Created: 15/11/2023
##
## <!> Please ask your referent before update this script.
## <!> Be careful before query global variable.
## <!> Always checks var != null
extends Node

## represent the current game version : debug(true) or release(false)
## always initialized
## cant be modified through code
var camera: Camera = null
var cursor: CursorController = null
var debug_console: DebugConsole = null
var debug: bool = true:
	set = _set_debug
var hud: HUD = null
var in_game_menu: IngameMenu = null
var paused: bool = false

# core
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Log.init()


# public


# private


# signal


# event


# setget
## Global.debug variable guard
func _set_debug(_value: bool) -> void:
	Log.trace(Log.Level.ERROR, "Cannot modify debug level from script")
	return
