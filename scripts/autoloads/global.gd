## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Store global variables.
## <!> Please ask your referent before update this script.
## <!> The node references are null until their node is ready (and may hold a freed node after a scene change),
## <!> check them with [method @GlobalScope.is_instance_valid] before use.
extends Node

## Emitted each time a pause source is requested or released, with the resulting [member paused] value.
signal pause_changed(paused: bool)

## Pause sources that also pause the scene tree, the others only freeze the gameplay.
const TREE_PAUSING_SOURCES: Array[StringName] = [&"dialogue", &"new_enemy", &"pause_menu"]
## Pause sources that play their own animations: they keep the engine time scale running.
## [br]Dialogic stops revealing text at a time scale of 0, so [code]&"dialogue"[/code] needs it too.
const TIME_RUNNING_SOURCES: Array[StringName] = [&"dialogue", &"level_end", &"new_enemy"]

var camera: Camera = null
var console: Console = null
var cursor: BuildPlacement = null
var hud: HUD = null
var ui: UI = null
## True while at least one source requested a pause, see [method request_pause].
var paused: bool:
	get: return not _pause_sources.is_empty()

## Debug-only builds (console, watchers, etc.). Mirrors the Godot export feature `debug`
## (true in the editor and debug export templates, false in release exports).
var debug: bool = OS.has_feature("debug"): set = _set_debug

var _initialized: bool = false: set = _set_initialized
var _pause_sources: Dictionary[StringName, bool] = {}

# core
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Log.init()
	_initialized = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		Log.close()


# public
## Forgets every pause source, called when a level is replaced or left.
func clear_pauses() -> void:
	if _pause_sources.is_empty():
		return
	_pause_sources.clear()
	_apply_pause_sources()


## Returns true when a pause source needs the engine time scale at 0 (see [constant TIME_RUNNING_SOURCES]).
func is_time_frozen() -> bool:
	return _pause_sources.keys().any(func(source: StringName) -> bool: return source not in TIME_RUNNING_SOURCES)


## Releases the pause of [param source], the game resumes once every source released its pause.
func release_pause(source: StringName) -> void:
	if _pause_sources.erase(source):
		_apply_pause_sources()


## Pauses the game on behalf of [param source], requesting twice with the same source counts once.
## [br]Example: [code]Global.request_pause(&"upgrade_menu")[/code] then [code]Global.release_pause(&"upgrade_menu")[/code].
func request_pause(source: StringName) -> void:
	if _pause_sources.has(source):
		return
	_pause_sources[source] = true
	_apply_pause_sources()


# private
## Pauses the scene tree when a tree-pausing source is active and notifies the change.
func _apply_pause_sources() -> void:
	get_tree().paused = TREE_PAUSING_SOURCES.any(func(source: StringName) -> bool: return _pause_sources.has(source))
	pause_changed.emit(paused)


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
