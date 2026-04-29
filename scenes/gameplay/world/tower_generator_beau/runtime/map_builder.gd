## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Constructeur de IMap dynamique à partir d'une RuntimeGameMap.
## Crée les nœuds TileMap et Path2D nécessaires pour le jeu.

class_name MapBuilder
extends RefCounted

const I_MAP_SCENE = preload("res://scenes/gameplay/world/map/i_map.tscn")
const WATER_OVERLAY_LAYER := 1

# Mapping TileType vers Source ID dans le TileSet
const TILE_SOURCE_MAPPING = {
	0: 0,      # EMPTY -> Grass
	1: 4,      # PATH -> Way
	2: 1,      # BUILDABLE -> Gravel
	3: 4,      # SPAWN -> Way
	4: 4,      # EXIT -> Way
	5: 6,      # OBSTACLE -> Rock
	6: 3,      # WATER -> Water
	7: 2       # SAND -> Sand
}

## Construit une instance IMap complète à partir d'une RuntimeGameMap
func build_map(game_map: RuntimeGameMap) -> Node2D:
	Log.trace(Log.Level.INFO, "MapBuilder: Building map %dx%d" % [game_map.width, game_map.height])
	
	# Charger la scène de base IMap
	var map_instance = I_MAP_SCENE.instantiate()
	var tilemap: TileMap = map_instance.get_node("TileMapPlains")
	var paths_node: Node2D = map_instance.get_node("Paths")
	var controller: TowerPlacement = map_instance.get_node_or_null("Controller")
	
	if tilemap == null:
		Log.trace(Log.Level.ERROR, "MapBuilder: TileMapPlains not found!")
		return map_instance
	
	if controller == null:
		Log.trace(Log.Level.ERROR, "MapBuilder: Controller (TowerPlacement) not found in IMap scene!")
	else:
		Log.trace(Log.Level.INFO, "MapBuilder: Controller found in map instance")
	
	# Vérifier que le TileSet est bien configuré
	if tilemap.tile_set == null:
		Log.trace(Log.Level.ERROR, "MapBuilder: TileSet is null!")
		return map_instance
	
	# Construire le TileMap
	_build_tilemap(tilemap, game_map)
	
	# Construire les Path2D
	_build_paths(paths_node, game_map)
	
	# Positionner la caméra au centre de la map
	_setup_camera(map_instance, game_map)
	
	Log.trace(Log.Level.INFO, "MapBuilder: Map built successfully")
	return map_instance

## Configure la caméra pour qu'elle soit centrée sur la map
func _setup_camera(map_instance: Node2D, game_map: RuntimeGameMap) -> void:
	var camera: Camera2D = map_instance.get_node_or_null("Camera2D")
	if camera == null:
		return
	
	# Calculer le centre de la map en coordonnées isométriques
	# Pour une map de width x height, le centre est approximativement :
	# px = (width/2 - height/2) * 32
	# py = (width/2 + height/2) * 16
	var center_x = (game_map.width / 2.0 - game_map.height / 2.0) * 32
	var center_y = (game_map.width / 2.0 + game_map.height / 2.0) * 16
	camera.position = Vector2(center_x, center_y)
	
	# Configurer le zoom comme dans les maps normales
	camera.zoom = Vector2(1.6, 1.6)
	
	# Configurer les limites de la caméra
	camera.limit_left = -250
	camera.limit_top = -250
	camera.limit_right = game_map.width * 64  # Approximatif
	camera.limit_bottom = game_map.height * 64  # Approximatif
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	
	# Activer la caméra
	camera.enabled = true
	camera.make_current()

## Construit le TileMap avec toutes les tuiles
func _build_tilemap(tilemap: TileMap, game_map: RuntimeGameMap) -> void:
	# Nettoyer le TileMap existant
	tilemap.clear()
	
	var tiles_placed = 0
	var water_tiles_count := 0
	var overlay_tiles_ok := 0
	var overlay_tiles_mismatch := 0
	
	# Parcourir toutes les tuiles de la map
	for x in range(game_map.width):
		for y in range(game_map.height):
			var tile = game_map.get_tile(x, y)
			if tile == null:
				# Si la tuile est null, placer de l'herbe par défaut
				tilemap.set_cell(0, Vector2i(x, y), 0, _get_default_atlas_coords(0, x, y), 0)
				tiles_placed += 1
				continue
			
			var source_id = TILE_SOURCE_MAPPING.get(tile.type, 0)
			var atlas_coords = _get_default_atlas_coords(tile.type, x, y)
			var alternative_id = 0
			
			# Gestion spéciale pour l'eau (bordures)
			if tile.type == 6:  # TileType.WATER
				water_tiles_count += 1
				atlas_coords = _get_water_border_coords(game_map, x, y)
				# Layer 0 : Eau statique
				tilemap.set_cell(0, Vector2i(x, y), source_id, atlas_coords, 0)
				# Layer overlay : Animation de vagues au-dessus de l'eau statique.
				tilemap.set_cell(WATER_OVERLAY_LAYER, Vector2i(x, y), 5, Vector2i(0, 0), 0)
				tiles_placed += 1
			else:
				tilemap.set_cell(0, Vector2i(x, y), source_id, atlas_coords, 0)
				tiles_placed += 1
	
	# Diagnostic: valider que layer_1 contient bien la tuile animée.
	# (Si mismatch ici, le set_cell ou l'index de layer ne correspond pas à la scène)
	for x in range(game_map.width):
		for y in range(game_map.height):
			var tile = game_map.get_tile(x, y)
			if tile == null:
				continue
			if tile.type != 6:
				continue
			var expected_atlas: Vector2i = Vector2i(0, 0)
			var expected_source: int = 5
			var placed_source := tilemap.get_cell_source_id(WATER_OVERLAY_LAYER, Vector2i(x, y))
			var placed_atlas := tilemap.get_cell_atlas_coords(WATER_OVERLAY_LAYER, Vector2i(x, y))
			if placed_source == expected_source and placed_atlas == expected_atlas:
				overlay_tiles_ok += 1
			else:
				overlay_tiles_mismatch += 1
	
	Log.trace(Log.Level.INFO, "MapBuilder: Placed %d tiles on TileMap (map size: %dx%d)" % [tiles_placed, game_map.width, game_map.height])
	Log.trace(Log.Level.INFO, "MapBuilder: Water tiles=%d, overlay ok=%d, overlay mismatch=%d" % [water_tiles_count, overlay_tiles_ok, overlay_tiles_mismatch])

func _get_default_atlas_coords(tile_type: int, x: int, y: int) -> Vector2i:
	# Mode ultra lisible: pas de variation atlas pour éviter tout rendu "pierreux".
	# On garde uniquement les types gameplay (path/buildable/sable/eau) distingués par source_id.
	return Vector2i(0, 0)

## Détermine les coordonnées d'atlas pour les bordures d'eau
func _get_water_border_coords(game_map: RuntimeGameMap, x: int, y: int) -> Vector2i:
	# Garder exactement la même priorité que l'exporter Python pour
	# avoir un rendu de l'eau identique entre génération offline et runtime.
	if x == 0:
		return Vector2i(2, 0)
	elif y >= game_map.height - 1:
		return Vector2i(4, 0)
	elif y == 0:
		return Vector2i(3, 0)
	elif x == game_map.width - 1:
		return Vector2i(4, 0)
	return Vector2i(1, 0)

## Construit les nœuds Path2D avec leurs Curve2D
func _build_paths(paths_node: Node2D, game_map: RuntimeGameMap) -> void:
	# Nettoyer les chemins existants
	for child in paths_node.get_children():
		child.queue_free()
	
	# Obtenir le TileMap pour utiliser map_to_local
	var map_instance = paths_node.get_parent()
	var tilemap: TileMap = map_instance.get_node_or_null("TileMapPlains")
	if tilemap == null:
		Log.trace(Log.Level.ERROR, "MapBuilder: TileMapPlains not found for path conversion!")
		return
	
	# Créer un Path2D pour chaque chemin
	for i in range(game_map.paths.size()):
		var path = game_map.paths[i]
		
		# Créer la Curve2D
		var curve = Curve2D.new()
		for point in path.points:
			# Utiliser map_to_local du TileMap pour convertir les coordonnées de tuile en coordonnées monde
			# Cela garantit que les points sont alignés avec les tuiles
			var world_pos = tilemap.map_to_local(Vector2i(point.x, point.y))
			curve.add_point(world_pos)
		
		# Créer le Path2D
		var path2d = Path2D.new()
		path2d.name = "Path2D_%d" % i
		# Pas besoin d'offset si on utilise map_to_local
		path2d.position = Vector2.ZERO
		path2d.curve = curve
		
		paths_node.add_child(path2d)
		Log.trace(Log.Level.INFO, "MapBuilder: Created Path2D_%d with %d points" % [i, path.points.size()])
