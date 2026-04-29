## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Générateur principal de maps en runtime.
## Orchestre la génération complète d'une IMap jouable.

class_name MapGeneratorRuntimeMain
extends RefCounted

## Génère une map complète selon la configuration
## Retourne un Dictionary avec "map" (Node2D) et "game_map" (RuntimeGameMap)
static func generate_map(config: GenConfig) -> Dictionary:
	# 1. Créer un RNG avec le seed (ou générer un seed aléatoire si 0)
	var rng = RandomNumberGenerator.new()
	if config.seed == 0:
		# Générer un seed aléatoire basé sur le temps
		var temp_rng = RandomNumberGenerator.new()
		temp_rng.randomize()
		config.seed = temp_rng.randi()
	rng.seed = config.seed
	Log.trace(Log.Level.INFO, "MapGeneratorRuntimeMain: Using seed %d" % config.seed)

	# 2. Retry adaptatif selon la difficulté pour améliorer la qualité perçue.
	var max_attempts: int = _get_attempts_for_difficulty(config.difficulty)
	var best_game_map: RuntimeGameMap = null
	var best_map_instance: Node2D = null
	var best_rank_score: float = INF
	var best_validation_score: float = -1.0
	var best_quality_score: float = -1.0

	var target_range: Vector2 = _get_difficulty_range(config.difficulty)
	var target_center: float = (target_range.x + target_range.y) / 2.0

	var builder: MapBuilder = MapBuilder.new()

	for attempt in range(max_attempts):
		# 3. Créer la map vide
		var game_map: RuntimeGameMap = RuntimeGameMap.new(config.width, config.height)

		# 4. Générer les chemins avec le RNG
		var path_gen = PathGeneratorRuntime.new(config.width, config.height, rng)
		var paths_data = path_gen.generate_paths(config.style, config.num_paths)

		# 5. Appliquer les chemins et autres éléments avec le RNG
		var map_gen = MapGeneratorRuntime.new(config.width, config.height, rng)
		map_gen.apply_paths_to_map(game_map, paths_data)
		map_gen.apply_borders(game_map)
		map_gen.generate_buildable_zones(
			game_map,
			config.buildable_density,
			config.enemy_types,
			config.difficulty
		)
		map_gen.add_decorations(game_map, config.decoration_density)

		if not _passes_generation_constraints(game_map, config):
			continue

		# 6. Valider (score difficulté) et garder la meilleure
		var validation = MapValidator.validate(game_map)
		if validation.is_valid:
			var score_delta: float = abs(validation.difficulty_score - target_center)
			var quality_score: float = _compute_quality_score(game_map)
			# Ranking pondéré:
			# - priorité à la proximité de difficulté (70%)
			# - puis qualité de map (30%)
			var rank_score: float = score_delta * 0.7 + (1.0 - quality_score) * 0.3
			if validation.difficulty_score >= target_range.x and validation.difficulty_score <= target_range.y:
				var map_instance = builder.build_map(game_map)
				return {
					"map": map_instance,
					"game_map": game_map,
					"rng": rng,
					"meta": {
						"difficulty_score": validation.difficulty_score,
						"quality_score": quality_score,
						"attempts": attempt + 1,
						"max_attempts": max_attempts,
						"in_target_range": true
					}
				}
			if rank_score < best_rank_score:
				best_rank_score = rank_score
				best_game_map = game_map
				best_validation_score = validation.difficulty_score
				best_quality_score = quality_score

	# 7. Fallback sur la meilleure map trouvée
	if best_game_map != null:
		best_map_instance = builder.build_map(best_game_map)
		return {
			"map": best_map_instance,
			"game_map": best_game_map,
			"rng": rng,
			"meta": {
				"difficulty_score": best_validation_score,
				"quality_score": best_quality_score,
				"attempts": max_attempts,
				"max_attempts": max_attempts,
				"in_target_range": false
			}
		}

	# Sinon, renvoyer une map brute (rare)
	var fallback_game_map: RuntimeGameMap = RuntimeGameMap.new(config.width, config.height)
	var fallback_map_instance: Node2D = builder.build_map(fallback_game_map)
	return {
		"map": fallback_map_instance,
		"game_map": fallback_game_map,
		"rng": rng,
		"meta": {
			"difficulty_score": -1.0,
			"quality_score": -1.0,
			"attempts": max_attempts,
			"max_attempts": max_attempts,
			"in_target_range": false
		}
	}

static func _get_difficulty_range(difficulty: int) -> Vector2:
	# Reprend les mêmes bornes que evaluator.py côté Python.
	# Map_enums.gd: EASY=0, MEDIUM=1, HARD=2
	if difficulty == 0: # EASY
		return Vector2(0.1, 0.3)
	elif difficulty == 1: # MEDIUM
		return Vector2(0.4, 0.6)
	return Vector2(0.7, 0.9)

static func _get_attempts_for_difficulty(difficulty: int) -> int:
	# EASY=0, MEDIUM=1, HARD=2
	if difficulty == 2:
		return 12
	if difficulty == 1:
		return 9
	return 6

static func _compute_quality_score(game_map: RuntimeGameMap) -> float:
	# Score final [0..1], plus élevé = meilleure qualité.
	# 1) coverage des buildables autour des chemins (40%)
	var coverage_score: float = _compute_buildable_coverage_score(game_map)
	# 2) fairness: chemins de longueurs comparables (30%)
	var fairness_score: float = _compute_path_fairness_score(game_map)
	# 3) chokepoints: présence de sections où la pose est plus stratégique (30%)
	var chokepoint_score: float = _compute_chokepoint_score(game_map)
	return clamp(coverage_score * 0.4 + fairness_score * 0.3 + chokepoint_score * 0.3, 0.0, 1.0)

static func _compute_buildable_coverage_score(game_map: RuntimeGameMap) -> float:
	var total_buildable: int = 0
	var useful_buildable: int = 0
	for x in range(game_map.width):
		for y in range(game_map.height):
			var tile = game_map.get_tile(x, y)
			if tile == null or tile.type != 2:
				continue
			total_buildable += 1
			var near_paths: int = 0
			for path in game_map.paths:
				for point in path.points:
					if Vector2i(x, y).distance_to(point) <= 2.5:
						near_paths += 1
						break
			if near_paths >= 1:
				useful_buildable += 1
	if total_buildable == 0:
		return 0.0
	return float(useful_buildable) / float(total_buildable)

static func _compute_path_fairness_score(game_map: RuntimeGameMap) -> float:
	if game_map.paths.size() <= 1:
		return 1.0
	var lengths: Array[float] = []
	var avg: float = 0.0
	for p in game_map.paths:
		var plen: float = float(p.points.size())
		lengths.append(plen)
		avg += plen
	avg /= float(game_map.paths.size())
	if avg <= 0.0:
		return 0.0
	var variance: float = 0.0
	for l in lengths:
		variance += pow(l - avg, 2.0)
	variance /= float(lengths.size())
	var std_dev: float = sqrt(variance)
	# Plus l'écart-type est bas, plus la fairness est haute.
	var normalized: float = clamp(1.0 - (std_dev / max(1.0, avg)), 0.0, 1.0)
	return normalized

static func _compute_chokepoint_score(game_map: RuntimeGameMap) -> float:
	var path_tiles: int = 0
	var chokepoint_like: int = 0
	for path in game_map.paths:
		for point in path.points:
			path_tiles += 1
			var open_neighbors: int = 0
			for dir in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var t = game_map.get_tile(point.x + dir.x, point.y + dir.y)
				if t != null and t.type in [0, 2]:
					open_neighbors += 1
			# Peu d'ouverture autour du path => effet chokepoint
			if open_neighbors <= 1:
				chokepoint_like += 1
	if path_tiles == 0:
		return 0.0
	return float(chokepoint_like) / float(path_tiles)

static func _passes_generation_constraints(game_map: RuntimeGameMap, config: GenConfig) -> bool:
	# Path length min/max
	if config.min_path_length > 0:
		for p in game_map.paths:
			if p.points.size() < config.min_path_length:
				return false
	if config.max_path_length > 0:
		for p in game_map.paths:
			if p.points.size() > config.max_path_length:
				return false

	# Buildable min/max
	var buildable_count: int = 0
	for x in range(game_map.width):
		for y in range(game_map.height):
			var t = game_map.get_tile(x, y)
			if t != null and t.type == 2:
				buildable_count += 1

	if config.min_buildable_zones > 0 and buildable_count < config.min_buildable_zones:
		return false
	if config.max_buildable_zones > 0 and buildable_count > config.max_buildable_zones:
		return false

	return true

## Crée une configuration par défaut
static func create_default_config() -> GenConfig:
	var config = GenConfig.new()
	config.width = 25
	config.height = 15
	config.difficulty = 1  # Difficulty.MEDIUM
	config.style = 1  # MapStyle.MANY_TURNS
	config.num_paths = 1
	config.buildable_density = 0.2
	config.decoration_density = 0.05
	return config
