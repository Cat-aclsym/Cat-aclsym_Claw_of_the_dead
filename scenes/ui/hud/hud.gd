class_name HUD
extends CanvasLayer

@onready var menu_pause: PauseMenu = $MenuPause
@onready var in_game_menu: IngameMenu = $IngameMenu
@onready var pause_button: Button = $PauseButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: pause_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_pause_button_pressed},
]


# core
func _ready() -> void:
	Global.hud = self
	SignalUtil.connects(signals)


# functionnal
func start_level() -> void:
	Log.trace(Log.Level.INFO, "HUD : Loading level interface")
	in_game_menu.load_ui()


func end_level() -> void:
	Log.trace(Log.Level.INFO, "HUD : Unloading level interface")
	in_game_menu.unload_ui()


# signals
func _on_pause_button_pressed():
	menu_pause.visible = !menu_pause.visible
	get_tree().paused = menu_pause.visible
