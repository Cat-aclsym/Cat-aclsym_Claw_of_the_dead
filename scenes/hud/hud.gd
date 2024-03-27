extends CanvasLayer

@onready var option_menu = $HomeMenu
@onready var menu_pause: MenuPause = $MenuPause
@onready var levels_menu = $LevelsMenu

# signals
func _on_pause_button_pressed():
	menu_pause.visible = !menu_pause.visible
	get_tree().paused = menu_pause.visible
