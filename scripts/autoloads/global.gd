## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Store global variables.
## <!> Please ask your referent before update this script.
## <!> Be careful before query global variable.
## <!> Always checks var != null
extends Node

# Public Variables
var ui: UI = null: get = _get_ui
var camera: Camera = null: get = _get_camera
var cursor: TowerPlacement = null: get = _get_cursor
var console: Console = null: get = _get_console
var hud: HUD = null: get = _get_hud
var paused: bool = false

## Represents the current game release status
var debug: bool = true: set = _set_debug

# Private Variables
var _initialized: bool = false: set = _set_initialized

# Built-in Functions
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Log.init()
	_initialized = true

# Private Functions
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
