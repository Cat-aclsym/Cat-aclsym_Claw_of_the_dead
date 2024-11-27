## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Store global variables.
## <!> Please ask your referent before update this script.
## <!> Be careful before query global variable.
## <!> Always checks var != null
extends Node

var camera: Camera = null: get = _get_camera
var console: Console = null: get = _get_console
var cursor: TowerPlacement = null: get = _get_cursor
var hud: HUD = null: get = _get_hud
var ui: UI = null: get = _get_ui
var paused: bool = false

## Represents the current game release status
var debug: bool = true: set = _set_debug

var _initialized: bool = false: set = _set_initialized

# core
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Log.init()
	_initialized = true

# private
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

# getters
func _get_camera() -> Camera:
	if _initialized: assert(camera != null, "Camera is null")
	return camera

func _get_cursor() -> TowerPlacement:
	if _initialized: assert(cursor != null, "Cursor is null")
	return cursor

func _get_console() -> Console:
	if _initialized: assert(console != null, "Console is null")
	return console

func _get_ui() -> UI:
	if _initialized: assert(ui != null, "UI is null")
	return ui

func _get_hud() -> HUD:
	if _initialized: assert(hud != null, "HUD is null")
	return hud
