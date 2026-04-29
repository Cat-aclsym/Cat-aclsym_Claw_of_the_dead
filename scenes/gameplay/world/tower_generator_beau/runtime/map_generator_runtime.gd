## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Générateur de map complète en runtime.
## Portage GDScript de map_generator.py

class_name MapGeneratorRuntime
extends RefCounted

var width: int
var height: int
var rng: RandomNumberGenerator

func _init(w: int, h: int, random_gen: RandomNumberGenerator = null):
	width = w
	height = h
	if random_gen != null:
		rng = random_gen
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()

## Applique les chemins générés à la map
func apply_paths_to_map(game_map: RuntimeGameMap, paths_data: Array) -> void:
	for path_data in paths_data:
		var spawn: Vector2i = path_data[0]
		var exit_pt: Vector2i = path_data[1]
		var path_points: Array[Vector2i] = path_data[2]
		
		# Créer le MapPath et l'ajouter
		var map_path = MapPath.new(path_points)
		game_map.paths.append(map_path)
		
		# Marquer les tuiles comme chemin
		for point in path_points:
			game_map.set_tile_type(point.x, point.y, 1)  # TileType.PATH
		
		# Marquer spawn et exit
		game_map.set_tile_type(spawn.x, spawn.y, 3)  # TileType.SPAWN
		game_map.set_tile_type(exit_pt.x, exit_pt.y, 4)  # TileType.EXIT

## Applique les bordures d'eau et de sable
func apply_borders(game_map: RuntimeGameMap) -> void:
	for x in range(width):
		for y in range(height):
			var tile = game_map.get_tile(x, y)
			if tile == null:
				continue
			
			# Ne pas écraser les chemins
			if tile.type in [1, 3, 4]:  # PATH, SPAWN, EXIT
				continue
			
			# Eau à l'extrémité absolue
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				tile.type = 6  # TileType.WATER
			# Sable juste après l'eau
			elif x == 1 or x == width - 2 or y == 1 or y == height - 2:
				tile.type = 7  # TileType.SAND

## Génère les zones constructibles autour des chemins
func generate_buildable_zones(game_map: RuntimeGameMap, density: float, enemy_types: Array, difficulty: int = 1) -> void:
	var potential: Array[MapTile] = []
	
	# Trouver toutes les tuiles vides proches des chemins (rayon manhattan <= 2)
	# pour obtenir des placements de tours plus pertinents que juste l'adjacence directe.
	for path in game_map.paths:
		for point in path.points:
			var px = point.x
			var py = point.y
			
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					if abs(dx) + abs(dy) > 2:
						continue
					var nx = px + dx
					var ny = py + dy
					var tile = game_map.get_tile(nx, ny)
					if tile and tile.type == 0:  # TileType.EMPTY
						# Calculer le score stratégique (distance aux chemins, nombre de chemins couverts)
						tile.score = _calculate_tile_score(game_map, nx, ny)
						if not potential.has(tile):
							potential.append(tile)
	
	# Trier par score décroissant
	potential.sort_custom(func(a, b): return a.score > b.score)
	
	# Sélectionner les meilleures zones selon la densité
	var effective_density = density * _difficulty_density_multiplier(difficulty)
	effective_density = clamp(effective_density, 0.0, 1.0)
	var max_buildable = int(potential.size() * effective_density)
	var minimum_buildable = _minimum_buildable_target(game_map, difficulty)
	max_buildable = maxi(max_buildable, mini(minimum_buildable, potential.size()))
	var spacing = _difficulty_buildable_spacing(difficulty)
	var selected_points: Array[Vector2i] = []
	for i in range(potential.size()):
		if selected_points.size() >= max_buildable:
			break
		var candidate = potential[i]
		var cpos = Vector2i(candidate.x, candidate.y)
		var too_close = false
		for pos in selected_points:
			if cpos.distance_to(pos) < spacing:
				too_close = true
				break
		if too_close:
			continue
		candidate.type = 2  # TileType.BUILDABLE
		selected_points.append(cpos)
	
	# Filet de sécurité: garantir un minimum de zones posables
	# même si le spacing strict bloque trop de tuiles.
	if selected_points.size() < minimum_buildable:
		for i in range(potential.size()):
			if selected_points.size() >= minimum_buildable:
				break
			var fallback_candidate = potential[i]
			if fallback_candidate.type == 2:
				continue
			fallback_candidate.type = 2
			selected_points.append(Vector2i(fallback_candidate.x, fallback_candidate.y))

## Calcule le score stratégique d'une tuile
func _calculate_tile_score(game_map: RuntimeGameMap, x: int, y: int) -> float:
	var score = 0.0
	
	# Distance aux chemins (plus proche = meilleur)
	var min_dist = INF
	for path in game_map.paths:
		for point in path.points:
			var dist = Vector2i(x, y).distance_to(point)
			if dist < min_dist:
				min_dist = dist
	
	score += 10.0 / (min_dist + 1.0)
	
	# Nombre de chemins à portée (plus de chemins = meilleur)
	var paths_in_range = 0
	for path in game_map.paths:
		for point in path.points:
			if Vector2i(x, y).distance_to(point) <= 2.5:
				paths_in_range += 1
				break
	
	score += paths_in_range * 5.0
	
	return score

## Ajoute des décorations (actuellement désactivé pour éviter les "trous")
func add_decorations(game_map: RuntimeGameMap, density: float) -> void:
	# Désactivé temporairement pour privilégier la lisibilité gameplay:
	# les joueurs doivent voir instantanément où poser des tours.
	return

func _distance_to_nearest_path(game_map: RuntimeGameMap, pos: Vector2i) -> float:
	var min_dist: float = INF
	for path in game_map.paths:
		for point in path.points:
			var dist: float = pos.distance_to(point)
			if dist < min_dist:
				min_dist = dist
	return min_dist

func _decoration_biome_score(game_map: RuntimeGameMap, pos: Vector2i) -> float:
	# Score 0..1 environ: favorise bords + proximité sable/eau + variation douce.
	var edge_dist: int = mini(mini(pos.x, width - 1 - pos.x), mini(pos.y, height - 1 - pos.y))
	var edge_score: float = 1.0 - clamp(float(edge_dist) / 8.0, 0.0, 1.0)
	
	var coastal_score: float = 0.0
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if dx == 0 and dy == 0:
				continue
			var nx: int = pos.x + dx
			var ny: int = pos.y + dy
			var ntile = game_map.get_tile(nx, ny)
			if ntile == null:
				continue
			if ntile.type == 6: # WATER
				coastal_score += 0.18
			elif ntile.type == 7: # SAND
				coastal_score += 0.08
	coastal_score = clamp(coastal_score, 0.0, 1.0)
	
	var n: float = _tile_noise01(pos.x, pos.y, 41)
	return clamp(edge_score * 0.35 + coastal_score * 0.45 + n * 0.20, 0.0, 1.0)

func _tile_noise01(x: int, y: int, salt: int) -> float:
	var h: int = abs((x * 73856093) ^ (y * 19349663) ^ (salt * 83492791))
	return float(h % 1000) / 999.0

func _difficulty_density_multiplier(difficulty: int) -> float:
	# Map_enums.gd Difficulty: EASY=0, MEDIUM=1, HARD=2
	if difficulty == 2:
		return 0.50
	if difficulty == 1:
		return 0.70
	if difficulty == 0:
		return 0.90
	return 0.75

func _difficulty_buildable_spacing(difficulty: int) -> float:
	# Hard => tours plus espacées => couverture moins triviale.
	if difficulty == 2:
		return 2.4
	if difficulty == 1:
		return 2.0
	return 1.6

func _minimum_buildable_target(game_map: RuntimeGameMap, difficulty: int) -> int:
	# Minimum dynamique pour éviter les maps rejetées (0 buildable).
	var area: int = game_map.width * game_map.height
	var base_min: int = maxi(6, int(round(float(area) * 0.02)))
	if difficulty == 2: # HARD
		return mini(base_min, 12)
	if difficulty == 1: # MEDIUM
		return mini(base_min + 2, 14)
	return mini(base_min + 4, 18) # EASY
