class_name HUD extends CanvasLayer

@onready var menu_pause: MenuPause = $MenuPause
@onready var in_game_menu: Control = $InGameMenu
@onready var in_game_menu_le_vrai: IngameMenu = $IngameMenu


# core
func _ready() -> void:
	Global.hud = self


# functionnal
func start_level() -> void:
	Log.info("HUD : Loading level interface")
	in_game_menu.visible = true
	in_game_menu.load_ui()


func end_level() -> void:
	Log.info("HUD : Unloading level interface")
	in_game_menu.visible = false
	in_game_menu.unload_ui()


# signals
func _on_pause_button_pressed():
	menu_pause.visible = !menu_pause.visible
	get_tree().paused = menu_pause.visible
