## File:	autoloads/global.gd
## Store global variables.
##
## Created: 15/11/2023
##
## <!> Please ask your referent before update this script.
## <!> Be careful before query global variable.
## <!> Always checks var != null
extends Node

var ig_menu = null
var camera: Camera = null
var cursor: CursorController = null
var debug_console: DebugConsole = null
var hud: HUD = null
var paused: bool = false

# core
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# public


# private


# signal


# event


# setget

