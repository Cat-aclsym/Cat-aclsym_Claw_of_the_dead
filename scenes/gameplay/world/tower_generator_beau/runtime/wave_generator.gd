## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Générateur de vagues adaptées à la map générée.
## Génère des vagues selon la difficulté, la longueur des chemins, etc.

class_name WaveGenerator
extends RefCounted

## Génère des vagues adaptées à la map
## Retourne un Dictionary au format JSON des vagues
static func generate_waves(
	config: GenConfig,
	game_map: RuntimeGameMap,
	rng: RandomNumberGenerator
) -> Dictionary:
	var num_waves = _get_num_waves(config.difficulty)
	var waves: Array = []
	
	# Calculer la longueur moyenne des chemins
	var avg_path_length = _calculate_avg_path_length(game_map)
	
	# Calculer le budget total d'ennemis selon la difficulté
	var total_enemy_budget = _calculate_enemy_budget(config.difficulty, avg_path_length, num_waves)
	
	# Répartir le budget entre les vagues
	var budget_per_wave = total_enemy_budget / float(num_waves)
	
	for wave_idx in range(num_waves):
		var wave = _generate_wave(
			wave_idx,
			num_waves,
			budget_per_wave,
			config.difficulty,
			config.enemy_types,
			game_map.paths.size(),
			rng
		)
		waves.append(wave)
	
	return {
		"status": "done",
		"waves": waves
	}

## Calcule le nombre de vagues selon la difficulté
static func _get_num_waves(difficulty: int) -> int:
	match difficulty:
		0: return 3  # EASY
		1: return 5  # MEDIUM
		2: return 7  # HARD
		_: return 5

## Calcule la longueur moyenne des chemins
static func _calculate_avg_path_length(game_map: RuntimeGameMap) -> float:
	if game_map.paths.is_empty():
		return 20.0
	
	var total_length = 0.0
	for path in game_map.paths:
		total_length += path.points.size()
	
	return total_length / float(game_map.paths.size())

## Calcule le budget total d'ennemis
static func _calculate_enemy_budget(difficulty: int, path_length: float, num_waves: int) -> float:
	# Base budget selon la difficulté
	var base_budget: float
	match difficulty:
		0: base_budget = 30.0  # EASY
		1: base_budget = 60.0  # MEDIUM
		2: base_budget = 145.0  # HARD (plus de pression)
		_: base_budget = 60.0
	
	# Ajuster selon la longueur du chemin (plus long = plus d'ennemis)
	var length_multiplier = path_length / 20.0  # Normaliser à 20
	
	# Ajuster selon le nombre de vagues
	var wave_multiplier = num_waves / 5.0  # Normaliser à 5 vagues
	
	# Hard: léger boost global supplémentaire
	if difficulty == 2:
		wave_multiplier *= 1.15
	
	return base_budget * length_multiplier * wave_multiplier

## Génère une vague individuelle
static func _generate_wave(
	wave_idx: int,
	total_waves: int,
	budget: float,
	difficulty: int,
	enemy_types: Array[String],
	num_paths: int,
	rng: RandomNumberGenerator
) -> Array:
	var wave: Array = []
	
	# Attente initiale
	wave.append({"wait_s": 1})
	
	# Calculer le budget pour cette vague (augmente avec l'index)
	var wave_budget = budget * (1.0 + wave_idx * 0.3)
	if difficulty == 2:
		# Hard: courbe de croissance plus agressive.
		wave_budget = budget * (1.0 + wave_idx * 0.42)
		# Mini spike toutes les 2 vagues (sauf la première).
		if wave_idx > 0 and wave_idx % 2 == 0:
			wave_budget *= 1.22
	
	# Déterminer les types d'ennemis à utiliser
	var available_enemies = _get_available_enemies(enemy_types, wave_idx, total_waves, difficulty)
	
	# Générer les spawns
	var remaining_budget = wave_budget
	var spawn_count = 0
	var max_spawns = 5 + wave_idx  # Plus de spawns dans les vagues suivantes
	if difficulty == 2:
		max_spawns += 2
	
	while remaining_budget > 0 and spawn_count < max_spawns:
		# Choisir un type d'ennemi
		var enemy_id = _choose_enemy(available_enemies, wave_idx, total_waves, difficulty, rng)
		var enemy_cost = _get_enemy_cost(enemy_id)
		
		# Calculer le nombre d'ennemis pour ce spawn
		var count = _calculate_enemy_count(enemy_cost, remaining_budget, difficulty, rng)
		if count <= 0:
			break
		
		# Choisir un spawner (chemin)
		var spawner = rng.randi_range(0, num_paths - 1)
		
		# Ajouter le spawn
		wave.append({
			"enemy_id": enemy_id,
			"count": count,
			"spawner": spawner
		})
		
		remaining_budget -= enemy_cost * count
		spawn_count += 1
		
		# Attente entre les spawns (plus court dans les vagues difficiles)
		if remaining_budget > 0 and spawn_count < max_spawns:
			var wait_time: float
			if difficulty == 2:
				# Hard: cadence serrée
				wait_time = rng.randf_range(0.35, max(0.7, 1.25 - (wave_idx * 0.08)))
			elif difficulty == 1:
				wait_time = rng.randf_range(0.8, max(1.1, 1.9 - (wave_idx * 0.08)))
			else:
				wait_time = rng.randf_range(1.1, max(1.5, 2.4 - (wave_idx * 0.06)))
			wave.append({"wait_s": wait_time})
	
	# Attente finale
	var end_wait: float = 3.0
	if difficulty == 2:
		end_wait = 2.0
	elif difficulty == 1:
		end_wait = 2.6
	wave.append({"wait_s": end_wait})
	
	return wave

## Retourne les ennemis disponibles pour cette vague
static func _get_available_enemies(enemy_types: Array[String], wave_idx: int, total_waves: int, difficulty: int) -> Array[String]:
	# Si des types sont spécifiés, les utiliser
	if not enemy_types.is_empty():
		return enemy_types
	
	# Sinon, déterminer selon la vague
	var available: Array[String] = ["ene.01"]  # Toujours disponible
	
	if wave_idx >= 1:
		available.append("ene.02")  # FAT disponible après la 1ère vague
	
	if wave_idx >= total_waves / 2:
		available.append("ene.03")  # RAT disponible à mi-parcours
	
	if wave_idx >= total_waves - 1:
		available.append("big_daddy")  # BOSS dans la dernière vague
	
	# Hard: introduire les variantes plus tôt.
	if difficulty == 2:
		if wave_idx >= 0 and not available.has("ene.03"):
			available.append("ene.03")
		if wave_idx >= total_waves - 2 and not available.has("big_daddy"):
			available.append("big_daddy")
	
	return available

## Choisit un ennemi selon la vague
static func _choose_enemy(available: Array[String], wave_idx: int, total_waves: int, difficulty: int, rng: RandomNumberGenerator) -> String:
	if available.is_empty():
		return "ene.01"
	
	# Probabilités selon la vague
	var weights: Dictionary = {}
	for enemy_id in available:
		var weight = 1.0
		
		if enemy_id == "ene.01":
			weight = 5.0  # Plus probable
		elif enemy_id == "ene.02":
			weight = 2.0 + wave_idx * 0.5
		elif enemy_id == "ene.03":
			weight = 1.0 + (wave_idx - total_waves / 2) * 0.3
		elif enemy_id == "big_daddy":
			weight = 0.5  # Rare
		
		# Hard: réduire la part de base et augmenter les menaces.
		if difficulty == 2:
			if enemy_id == "ene.01":
				weight *= 0.70
			elif enemy_id == "ene.02":
				weight *= 1.45
			elif enemy_id == "ene.03":
				weight *= 1.70
			elif enemy_id == "big_daddy":
				weight *= 1.35
		
		weights[enemy_id] = weight
	
	# Sélection pondérée
	var total_weight = 0.0
	for weight in weights.values():
		total_weight += weight
	
	var random = rng.randf() * total_weight
	var current = 0.0
	
	for enemy_id in weights.keys():
		current += weights[enemy_id]
		if random <= current:
			return enemy_id
	
	return available[0]

## Retourne le coût d'un ennemi (en points de budget)
static func _get_enemy_cost(enemy_id: String) -> float:
	match enemy_id:
		"ene.01": return 1.0  # Default
		"ene.02": return 3.0  # FAT
		"ene.03": return 1.5  # RAT
		"big_daddy": return 10.0  # BOSS
		_: return 1.0

## Calcule le nombre d'ennemis pour un spawn
static func _calculate_enemy_count(enemy_cost: float, budget: float, difficulty: int, rng: RandomNumberGenerator) -> int:
	var max_count = int(budget / enemy_cost)
	if max_count <= 0:
		return 0
	
	# Entre 1 et max_count, avec une préférence pour les groupes moyens
	var count = rng.randi_range(1, max_count)
	
	# Ajuster pour éviter les groupes trop petits ou trop grands
	if count < 3 and max_count >= 5:
		count = rng.randi_range(3, min(5, max_count))
	
	# Hard: groupes un peu plus denses, surtout pour les ennemis légers.
	if difficulty == 2 and enemy_cost <= 1.5 and max_count >= 6:
		count = maxi(count, rng.randi_range(4, min(8, max_count)))
	
	return count
