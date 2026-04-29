## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Validateur de maps générées.
## Vérifie que la map est jouable et valide.

class_name MapValidator
extends RefCounted

## Résultat de validation
class ValidationResult:
	var is_valid: bool
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var difficulty_score: float = 0.0  # 0.0 = très facile, 1.0 = très difficile

## Valide une map générée
static func validate(game_map: RuntimeGameMap) -> ValidationResult:
	var result = ValidationResult.new()
	result.is_valid = true
	
	# 1. Vérifier qu'il y a au moins un chemin
	if game_map.paths.is_empty():
		result.is_valid = false
		result.errors.append("Aucun chemin généré")
		return result
	
	# 2. Vérifier que chaque chemin a au moins un spawn et une sortie
	for i in range(game_map.paths.size()):
		var path = game_map.paths[i]
		if path.points.is_empty():
			result.is_valid = false
			result.errors.append("Le chemin %d est vide" % i)
			continue
		
		# Vérifier que le premier point est un spawn
		var first_point = path.points[0]
		var first_tile = game_map.get_tile(first_point.x, first_point.y)
		if first_tile == null or first_tile.type != 3:  # TileType.SPAWN
			result.warnings.append("Le chemin %d ne commence pas par un spawn" % i)
		
		# Vérifier que le dernier point est une sortie
		var last_point = path.points[path.points.size() - 1]
		var last_tile = game_map.get_tile(last_point.x, last_point.y)
		if last_tile == null or last_tile.type != 4:  # TileType.EXIT
			result.warnings.append("Le chemin %d ne se termine pas par une sortie" % i)
	
	# 3. Vérifier qu'il y a des zones buildables
	var buildable_count = 0
	for x in range(game_map.width):
		for y in range(game_map.height):
			var tile = game_map.get_tile(x, y)
			if tile and tile.type == 2:  # TileType.BUILDABLE
				buildable_count += 1
	
	if buildable_count == 0:
		result.is_valid = false
		result.errors.append("Aucune zone buildable trouvée")
	elif buildable_count < 5:
		result.warnings.append("Très peu de zones buildables (%d)" % buildable_count)
	
	# 4. Vérifier que les chemins sont connectés (pas de trous)
	for path in game_map.paths:
		for i in range(path.points.size() - 1):
			var current = path.points[i]
			var next = path.points[i + 1]
			
			# Vérifier que les points adjacents sont bien connectés
			var dx = abs(current.x - next.x)
			var dy = abs(current.y - next.y)
			if dx > 1 or dy > 1 or (dx == 0 and dy == 0):
				result.warnings.append("Chemin avec points non adjacents détecté")
				break
	
	# 5. Calculer un score de difficulté approximatif
	result.difficulty_score = _calculate_difficulty_score(game_map)
	
	# Avertissements selon le score
	if result.difficulty_score < 0.2:
		result.warnings.append("Map très facile (score: %.2f)" % result.difficulty_score)
	elif result.difficulty_score > 0.8:
		result.warnings.append("Map très difficile (score: %.2f)" % result.difficulty_score)
	
	return result

## Calcule un score de difficulté (0.0 = facile, 1.0 = difficile)
static func _calculate_difficulty_score(game_map: RuntimeGameMap) -> float:
	if game_map.paths.is_empty():
		return 0.5
	
	# Facteurs de difficulté :
	# - Plus de chemins = plus difficile
	# - Chemins plus longs = plus facile (plus de temps pour tuer)
	# - Moins de zones buildables = plus difficile
	
	var path_count = game_map.paths.size()
	var avg_path_length = 0.0
	for path in game_map.paths:
		avg_path_length += path.points.size()
	if path_count > 0:
		avg_path_length /= float(path_count)
	
	var buildable_count = 0
	for x in range(game_map.width):
		for y in range(game_map.height):
			var tile = game_map.get_tile(x, y)
			if tile and tile.type == 2:  # TileType.BUILDABLE
				buildable_count += 1
	
	var total_tiles = game_map.width * game_map.height
	var buildable_ratio = float(buildable_count) / float(total_tiles)
	
	# Score : plus de chemins et moins de zones buildables = plus difficile
	var path_factor = min(path_count / 3.0, 1.0)  # Normaliser à 3 chemins max
	var buildable_factor = 1.0 - buildable_ratio  # Moins de buildable = plus difficile
	var length_factor = 1.0 - min(avg_path_length / 50.0, 1.0)  # Chemins courts = plus difficile
	
	var score = (path_factor * 0.4 + buildable_factor * 0.4 + length_factor * 0.2)
	return clamp(score, 0.0, 1.0)
