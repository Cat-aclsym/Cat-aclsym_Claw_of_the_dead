## © [2024] A7 Studio. All rights reserved. Trademark.
## File:	autoloads/global.gd
## Store global variables.
##
## Created: 15/11/2023
##
## <!> Please ask your referent before update this script.
## <!> Be careful before query global variable.
## <!> Always checks var != null
extends Node

var ui: UI = null: get = _get_ui
var camera: Camera = null: get = _get_camera
var cursor: TowerPlacement = null: get = _get_cursor
var console: Console = null: get = _get_console
var hud: HUD = null: get = _get_hud

var paused: bool = false

## represent the current game release status : debug(true) or release(false)
## always initialized
## cant be modified if game is already initialized
var debug: bool = true: set = _set_debug

## represent the Global autload status
## cant be modified once set to true
var _initialized: bool = false: set = _set_initialized

# core
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	Log.init()

	_initialized = true


# public


# private


# signal


# event


# setget
## Global.debug variable guard
func _set_debug(new_value: bool) -> void:
	if not _initialized:
		debug = new_value
		return
	Log.trace(Log.Level.WARN, "Cannot change 'debug' value after game is initialized.")

func _set_initialized(new_value: bool) -> void:
	if not _initialized:
		_initialized = new_value
		return
	Log.trace(Log.Level.WARN, "Cannot change 'initialized' value after game is initialized.")

func _get_camera() -> Camera:
	if _initialized: assert(camera, "Camera is null")
	return camera

func _get_cursor() -> TowerPlacement:
	if _initialized: assert(cursor, "Cursor is null")
	return cursor

func _get_console() -> Console:
	if _initialized: assert(console, "Console is null")
	return console

func _get_ui() -> UI:
	if _initialized: assert(ui, "UI is null")
	return ui

func _get_hud() -> HUD:
	if _initialized: assert(hud, "HUD is null")
	return hud
