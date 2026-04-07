## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the game's user interface elements including HUD and pause menu.
## This class handles the initialization and management of UI components such as the pause menu, HUD, and pause button functionality.
class_name UI
extends CanvasLayer

## Flag indicating if the UI has been initialized
var _initialized: bool = false

@onready var hud: HUD = get_node("HUD")

# core
func _ready() -> void:
	Global.ui = self
	if hud == null:
		Log.trace(Log.Level.FATAL, "UI : HUD node is null! Children: %s" % str(get_children()))
	assert(hud != null, "hud node not found")
	_initialized = true

# public
## Initializes and displays the HUD for a new level.
## [br]This function must be called when starting a new level to set up the UI.
func start_level() -> void:
	assert(_initialized, "UI not properly initialized")
	Log.trace(Log.Level.INFO, "HUD : Loading level interface")
	hud.load_ui()

## Cleans up and hides the HUD when leaving a level.
## [br]This function must be called when exiting a level to clean up the UI.
func end_level() -> void:
	assert(_initialized, "UI not properly initialized")
	Log.trace(Log.Level.INFO, "HUD : Unloading level interface")
	hud.unload_ui()
	# Auto-save progression when exiting a level
	ProgressionManager.save_game()
