## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Dialog pour afficher et charger les maps sauvegardées.

class_name SavedMapsDialog
extends AcceptDialog

signal map_selected(map_name: String)

@onready var maps_list: ItemList = $VBoxContainer/MapsList
@onready var delete_button: Button = $VBoxContainer/ButtonsContainer/DeleteButton
@onready var load_button: Button = $VBoxContainer/ButtonsContainer/LoadButton

var _saved_maps: Array[Dictionary] = []

# core
func _ready() -> void:
	title = "Maps Sauvegardées"
	
	# Connecter les signaux
	if maps_list:
		maps_list.item_selected.connect(_on_map_selected)
	if delete_button:
		delete_button.pressed.connect(_on_delete_button_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_button_pressed)
	
	load_button.disabled = true
	delete_button.disabled = true
	
	_refresh_maps_list()

# public
func _refresh_maps_list() -> void:
	if maps_list == null:
		return
	
	maps_list.clear()
	_saved_maps = MapSaver.list_saved_maps()
	
	for map_info in _saved_maps:
		var map_name = map_info.get("display_name", map_info.get("name", "Unknown"))
		var created_at = map_info.get("created_at", 0)
		var date_str = ""
		
		if created_at > 0:
			var date = Time.get_datetime_dict_from_unix_time(created_at)
			date_str = "%02d/%02d/%04d %02d:%02d" % [date.day, date.month, date.year, date.hour, date.minute]
		
		var display_text = "%s - %s" % [map_name, date_str]
		maps_list.add_item(display_text)
	
	if _saved_maps.is_empty():
		maps_list.add_item("Aucune map sauvegardée")
		maps_list.set_item_disabled(0, true)

# private
func _on_map_selected(index: int) -> void:
	if index < 0 or index >= _saved_maps.size():
		load_button.disabled = true
		delete_button.disabled = true
		return
	
	load_button.disabled = false
	delete_button.disabled = false

func _on_load_button_pressed() -> void:
	var selected_indices = maps_list.get_selected_items()
	if selected_indices.is_empty():
		return
	
	var index = selected_indices[0]
	if index < 0 or index >= _saved_maps.size():
		return
	
	var map_name = _saved_maps[index].get("name", "")
	if map_name.is_empty():
		return
	
	map_selected.emit(map_name)
	hide()

func _on_delete_button_pressed() -> void:
	var selected_indices = maps_list.get_selected_items()
	if selected_indices.is_empty():
		return
	
	var index = selected_indices[0]
	if index < 0 or index >= _saved_maps.size():
		return
	
	var map_name = _saved_maps[index].get("name", "")
	if map_name.is_empty():
		return
	
	# Demander confirmation
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Supprimer la map '%s' ?" % map_name
	confirm_dialog.confirmed.connect(func(): _delete_map(map_name))
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()

func _delete_map(map_name: String) -> void:
	if MapSaver.delete_saved_map(map_name):
		_refresh_maps_list()
		load_button.disabled = true
		delete_button.disabled = true
