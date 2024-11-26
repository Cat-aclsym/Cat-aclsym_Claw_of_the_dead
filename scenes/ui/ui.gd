## © [2024] A7 Studio. All rights reserved. Trademark.
## File: scenes/ui/ui.gd
## Manages the game's user interface elements including HUD and pause menu.
class_name UI
extends CanvasLayer

# Private Variables
var _initialized: bool = false

# Onready Variables
@onready var menu_pause: PauseMenu = $MenuPause
@onready var hud: HUD = $HUD
@onready var pause_button: Button = $PauseButton

@onready var _signals: Array[Dictionary] = [
	{SignalUtil.WHO: pause_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_pause_button_pressed},
]

# Built-in Functions
func _ready() -> void:
	assert(menu_pause != null, "menu_pause node not found")
	assert(hud != null, "hud node not found")
	assert(pause_button != null, "pause_button node not found")

	Global.ui = self
	SignalUtil.connects(_signals)
	_initialized = true

# Public Functions
## Initializes and displays the HUD for a new level
func start_level() -> void:
	assert(_initialized, "UI not properly initialized")
	Log.trace(Log.Level.INFO, "HUD : Loading level interface")
	hud.load_ui()

## Cleans up and hides the HUD when leaving a level
func end_level() -> void:
	assert(_initialized, "UI not properly initialized")
	Log.trace(Log.Level.INFO, "HUD : Unloading level interface")
	hud.unload_ui()

# Private Functions
## Handles the pause button press event
func _on_pause_button_pressed() -> void:
	menu_pause.visible = !menu_pause.visible
	get_tree().paused = menu_pause.visible
