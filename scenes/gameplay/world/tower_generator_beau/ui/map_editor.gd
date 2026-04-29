## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Éditeur de map manuel.
## Permet de modifier les tuiles après génération.

class_name MapEditor
extends Control

signal map_updated(game_map: RuntimeGameMap)
signal close_requested

enum EditMode {
	NONE,
	PATH,
	BUILDABLE,
	OBSTACLE,
	ERASE
}

var game_map: RuntimeGameMap = null
var map_instance: Node2D = null
var current_mode: EditMode = EditMode.NONE
var is_editing: bool = false

@onready var close_button: Button = get_node_or_null("Panel/VBoxContainer/HeaderContainer/CloseButton")
@onready var mode_container: HBoxContainer = get_node_or_null("Panel/VBoxContainer/ModeContainer")
@onready var editor_canvas: Control = get_node_or_null("Panel/VBoxContainer/EditorCanvas")
@onready var status_label: Label = get_node_or_null("Panel/VBoxContainer/StatusLabel")

var path_button: Button
var buildable_button: Button
var obstacle_button: Button
var erase_button: Button

func _ready() -> void:
	if close_button != null:
		close_button.pressed.connect(func(): close_requested.emit())
	visible = false
	if mode_container != null:
		_setup_mode_buttons()

## Configure les boutons de mode
func _setup_mode_buttons() -> void:
	path_button = Button.new()
	path_button.text = "Chemin"
	path_button.toggle_mode = true
	path_button.pressed.connect(func(): _set_mode(EditMode.PATH))
	mode_container.add_child(path_button)
	
	buildable_button = Button.new()
	buildable_button.text = "Buildable"
	buildable_button.toggle_mode = true
	buildable_button.pressed.connect(func(): _set_mode(EditMode.BUILDABLE))
	mode_container.add_child(buildable_button)
	
	obstacle_button = Button.new()
	obstacle_button.text = "Obstacle"
	obstacle_button.toggle_mode = true
	obstacle_button.pressed.connect(func(): _set_mode(EditMode.OBSTACLE))
	mode_container.add_child(obstacle_button)
	
	erase_button = Button.new()
	erase_button.text = "Effacer"
	erase_button.toggle_mode = true
	erase_button.pressed.connect(func(): _set_mode(EditMode.ERASE))
	mode_container.add_child(erase_button)

## Ouvre l'éditeur avec une map
func start_editing(p_game_map: RuntimeGameMap, p_map_instance: Node2D) -> void:
	game_map = p_game_map
	map_instance = p_map_instance
	is_editing = true
	visible = true
	current_mode = EditMode.NONE
	_update_editor_display()
	_update_status()

## Ferme l'éditeur
func stop_editing() -> void:
	is_editing = false
	visible = false
	current_mode = EditMode.NONE

## Définit le mode d'édition
func _set_mode(mode: EditMode) -> void:
	if current_mode == mode:
		current_mode = EditMode.NONE
	else:
		current_mode = mode
	
	_update_mode_buttons()
	_update_status()

## Met à jour l'état des boutons
func _update_mode_buttons() -> void:
	path_button.button_pressed = (current_mode == EditMode.PATH)
	buildable_button.button_pressed = (current_mode == EditMode.BUILDABLE)
	obstacle_button.button_pressed = (current_mode == EditMode.OBSTACLE)
	erase_button.button_pressed = (current_mode == EditMode.ERASE)

## Met à jour le statut
func _update_status() -> void:
	if status_label == null:
		return
	match current_mode:
		EditMode.NONE:
			status_label.text = "Sélectionnez un mode d'édition"
		EditMode.PATH:
			status_label.text = "Mode: Chemin - Cliquez sur les tuiles pour créer un chemin"
		EditMode.BUILDABLE:
			status_label.text = "Mode: Zone buildable - Cliquez sur les tuiles pour les rendre buildables"
		EditMode.OBSTACLE:
			status_label.text = "Mode: Obstacle - Cliquez sur les tuiles pour ajouter des obstacles"
		EditMode.ERASE:
			status_label.text = "Mode: Effacer - Cliquez sur les tuiles pour les effacer"

## Met à jour l'affichage de l'éditeur
func _update_editor_display() -> void:
	if game_map == null:
		return
	if editor_canvas == null:
		return
	
	# Nettoyer le canvas
	for child in editor_canvas.get_children():
		child.queue_free()
	
	var canvas_size = editor_canvas.size
	var tile_size = min(canvas_size.x / float(game_map.width), canvas_size.y / float(game_map.height))
	
	# Dessiner les tuiles
	for x in range(game_map.width):
		for y in range(game_map.height):
			var tile = game_map.get_tile(x, y)
			if tile == null:
				continue
			
			var color: Color
			match tile.type:
				0: color = Color.GRAY  # EMPTY
				1: color = Color.BROWN  # PATH
				2: color = Color.GREEN  # BUILDABLE
				3: color = Color.CYAN  # SPAWN
				4: color = Color.RED  # EXIT
				5: color = Color.DARK_GREEN  # OBSTACLE
				6: color = Color.BLUE  # WATER
				7: color = Color.YELLOW  # SAND
				_: color = Color.WHITE
			
			var button = Button.new()
			button.text = ""
			button.flat = true
			button.modulate = color
			button.position = Vector2(x * tile_size, y * tile_size)
			button.size = Vector2(tile_size, tile_size)
			button.pressed.connect(_on_tile_clicked.bind(x, y))
			editor_canvas.add_child(button)

## Gère le clic sur une tuile
func _on_tile_clicked(x: int, y: int) -> void:
	if current_mode == EditMode.NONE or game_map == null:
		return
	
	var tile = game_map.get_tile(x, y)
	if tile == null:
		return
	
	match current_mode:
		EditMode.PATH:
			# Ne pas modifier les bordures (eau/sable)
			if tile.type != 6 and tile.type != 7:
				game_map.set_tile_type(x, y, 1)  # PATH
		EditMode.BUILDABLE:
			if tile.type != 6 and tile.type != 7:
				game_map.set_tile_type(x, y, 2)  # BUILDABLE
		EditMode.OBSTACLE:
			if tile.type != 6 and tile.type != 7:
				game_map.set_tile_type(x, y, 5)  # OBSTACLE
		EditMode.ERASE:
			if tile.type != 6 and tile.type != 7:
				game_map.set_tile_type(x, y, 0)  # EMPTY
	
	# Mettre à jour l'affichage et la map 3D
	_update_editor_display()
	_apply_changes_to_map_instance()
	map_updated.emit(game_map)

## Applique les changements à l'instance de map
func _apply_changes_to_map_instance() -> void:
	if map_instance == null:
		return
	
	var tilemap: TileMap = map_instance.get_node_or_null("TileMapPlains")
	if tilemap == null:
		return
	
	# Reconstruire le TileMap avec les nouvelles données
	var builder = MapBuilder.new()
	# On ne peut pas reconstruire directement, il faudrait recréer la map
	# Pour l'instant, on log juste
	Log.trace(Log.Level.INFO, "MapEditor: Changes applied to game_map, map_instance needs rebuild")
