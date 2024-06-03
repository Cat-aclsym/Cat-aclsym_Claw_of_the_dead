extends Control

var _is_ready: bool = false

@onready var construction_menu: PanelContainer = $VBoxContainer/PanelContainer


# functionnal
func load_ui() -> void:
	if ILevel.current_level == null:
		Log.error("Cannot load ingame ui, ILevel.current_level = null")
		return

	_is_ready = true
	ILevel.current_level.connect("stats_updated", _update)
	_update()


func unload_ui() -> void:
	_is_ready = false
	ILevel.current_level.disconnect("stats_updated", _update)


# internal
func _update() -> void:
	if !_is_ready:
		Log.error("Can update ingame ui if it is not ready!")
		return

	for tower_card in $VBoxContainer/PanelContainer/HBoxContainer.get_children():
		tower_card.update()


# signals
func _on_build_button_pressed() -> void:
	construction_menu.visible = !construction_menu.visible

	if !construction_menu.visible:
		return

	for tower_card in $VBoxContainer/PanelContainer/HBoxContainer.get_children():
		tower_card.update()
