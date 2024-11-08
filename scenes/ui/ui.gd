class_name UI
extends CanvasLayer

@onready var menu_pause: PauseMenu = $MenuPause
@onready var hud: HUD = $HUD
@onready var pause_button: Button = $PauseButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: pause_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_pause_button_pressed},
]

# core
func _ready() -> void:
	Global.ui = self
	SignalUtil.connects(signals)


# functionnal
func start_level() -> void:
	Log.trace(Log.Level.INFO, "HUD : Loading level interface")
	hud.load_ui()


func end_level() -> void:
	Log.trace(Log.Level.INFO, "HUD : Unloading level interface")
	hud.unload_ui()


# signals
func _on_pause_button_pressed():
	menu_pause.visible = !menu_pause.visible
	get_tree().paused = menu_pause.visible
