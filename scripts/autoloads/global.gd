## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Store global variables.
## <!> Please ask your referent before update this script.
## <!> The node references are null until their node is ready (and may hold a freed node after a scene change),
## <!> check them with [method @GlobalScope.is_instance_valid] before use.
extends Node

var camera: Camera = null
var console: Console = null
var cursor: BuildPlacement = null
var hud: HUD = null
var ui: UI = null
var paused: bool = false

## Debug-only builds (console, watchers, etc.). Mirrors the Godot export feature `debug`
## (true in the editor and debug export templates, false in release exports).
var debug: bool = OS.has_feature("debug"): set = _set_debug

var _initialized: bool = false: set = _set_initialized

# core
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Log.init()
	_initialized = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		Log.close()


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
