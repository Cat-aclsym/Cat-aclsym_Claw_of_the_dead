## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Prévisualisation de la map générée.
## Affiche une mini-map et des statistiques détaillées.

class_name MapPreview
extends Control

signal close_requested

var game_map: RuntimeGameMap = null
var map_stats: Dictionary = {}

@onready var close_button: Button = get_node_or_null("Panel/VBoxContainer/HeaderContainer/CloseButton")
@onready var preview_canvas: Control = get_node_or_null("Panel/VBoxContainer/ContentContainer/PreviewCanvas")
@onready var stats_container: VBoxContainer = get_node_or_null("Panel/VBoxContainer/ContentContainer/StatsContainer")

func _ready() -> void:
	if close_button != null:
		close_button.pressed.connect(func(): close_requested.emit())
	visible = false

## Affiche la prévisualisation d'une map
func show_preview(p_game_map: RuntimeGameMap, p_stats: Dictionary) -> void:
	game_map = p_game_map
	map_stats = p_stats
	visible = true
	_update_preview()
	_update_stats()

## Met à jour la mini-map
func _update_preview() -> void:
	if game_map == null:
		return
	if preview_canvas == null:
		return
	
	# Nettoyer le canvas
	for child in preview_canvas.get_children():
		child.queue_free()
	
	var canvas_size = preview_canvas.size
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
			
			var rect = ColorRect.new()
			rect.color = color
			rect.position = Vector2(x * tile_size, y * tile_size)
			rect.size = Vector2(tile_size, tile_size)
			preview_canvas.add_child(rect)
	
	# Dessiner les chemins en surbrillance
	for path in game_map.paths:
		for i in range(path.points.size() - 1):
			var start = path.points[i]
			var end = path.points[i + 1]
			
			var line = Line2D.new()
			line.add_point(Vector2(start.x * tile_size + tile_size / 2, start.y * tile_size + tile_size / 2))
			line.add_point(Vector2(end.x * tile_size + tile_size / 2, end.y * tile_size + tile_size / 2))
			line.width = 2.0
			line.default_color = Color.MAGENTA
			preview_canvas.add_child(line)

## Met à jour les statistiques
func _update_stats() -> void:
	if map_stats.is_empty():
		return
	if stats_container == null:
		return
	
	# Nettoyer les stats existantes
	for child in stats_container.get_children():
		child.queue_free()
	
	# Titre
	var title = Label.new()
	title.text = "Statistiques de la Map"
	title.add_theme_font_size_override("font_size", 18)
	stats_container.add_child(title)
	
	# Séparateur
	var separator = HSeparator.new()
	stats_container.add_child(separator)
	
	# Dimensions
	var dim_label = Label.new()
	dim_label.text = "Dimensions: %d x %d" % [map_stats.width, map_stats.height]
	stats_container.add_child(dim_label)
	
	# Nombre de chemins
	var paths_label = Label.new()
	paths_label.text = "Chemins: %d" % map_stats.num_paths
	stats_container.add_child(paths_label)
	
	# Longueurs des chemins
	if map_stats.has("path_lengths") and map_stats.path_lengths.size() > 0:
		for i in range(map_stats.path_lengths.size()):
			var length_label = Label.new()
			length_label.text = "  Chemin %d: %d tuiles" % [i + 1, map_stats.path_lengths[i]]
			stats_container.add_child(length_label)
	
	# Longueur moyenne
	if map_stats.has("avg_path_length"):
		var avg_label = Label.new()
		avg_label.text = "Longueur moyenne: %.1f tuiles" % map_stats.avg_path_length
		stats_container.add_child(avg_label)
	
	# Zones buildables
	var buildable_label = Label.new()
	buildable_label.text = "Zones buildables: %d" % map_stats.buildable_zones
	stats_container.add_child(buildable_label)
	
	# Ratio buildable
	var total_tiles = map_stats.width * map_stats.height
	var buildable_ratio = float(map_stats.buildable_zones) / float(total_tiles) * 100.0
	var ratio_label = Label.new()
	ratio_label.text = "Ratio: %.1f%%" % buildable_ratio
	stats_container.add_child(ratio_label)
	
	# Spawns et sorties
	if map_stats.has("spawns") and map_stats.has("exits"):
		var spawns_label = Label.new()
		spawns_label.text = "Points de spawn: %d" % map_stats.spawns
		stats_container.add_child(spawns_label)
		
		var exits_label = Label.new()
		exits_label.text = "Points de sortie: %d" % map_stats.exits
		stats_container.add_child(exits_label)
