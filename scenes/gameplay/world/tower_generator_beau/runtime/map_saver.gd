## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Système de sauvegarde/chargement des maps générées.
## Sauvegarde la configuration et permet de régénérer la map.

class_name MapSaver
extends RefCounted

const SAVED_MAPS_DIR = "user://saved_maps/"
const CONFIG_FILE_EXT = ".json"
const MAP_FILE_EXT = ".tscn"

## Sauvegarde une configuration de map
## Retourne le nom du fichier sauvegardé, ou null en cas d'erreur
static func save_config(config: GenConfig, map_name: String = "") -> String:
	# Créer le dossier si nécessaire
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saved_maps"):
		dir.make_dir_recursive("saved_maps")
	
	# Générer un nom de fichier unique si non fourni
	if map_name.is_empty():
		var timestamp = Time.get_unix_time_from_system()
		map_name = "map_%d" % int(timestamp)
	
	var filepath = SAVED_MAPS_DIR + map_name + CONFIG_FILE_EXT
	
	# S'assurer que le seed est défini avant la sauvegarde
	if config.seed == 0:
		Log.trace(Log.Level.WARN, "MapSaver: Config has seed=0, generating new seed before save")
		var temp_rng = RandomNumberGenerator.new()
		temp_rng.randomize()
		config.seed = temp_rng.randi()
	
	# Créer le dictionnaire de configuration
	var config_data = {
		"version": 1,
		"map_name": map_name,
		"created_at": Time.get_unix_time_from_system(),
		"config": {
			"width": config.width,
			"height": config.height,
			"difficulty": config.difficulty,
			"style": config.style,
			"num_paths": config.num_paths,
			"decoration_density": config.decoration_density,
			"buildable_density": config.buildable_density,
			"min_path_length": config.min_path_length,
			"max_path_length": config.max_path_length,
			"min_buildable_zones": config.min_buildable_zones,
			"max_buildable_zones": config.max_buildable_zones,
			"force_chokepoints": config.force_chokepoints,
			"obstacle_density": config.obstacle_density,
			"theme": config.theme,
			"enemy_types": config.enemy_types,
			"player_level": config.player_level,
			"seed": config.seed
		}
	}
	
	# Sauvegarder en JSON
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		Log.trace(Log.Level.ERROR, "MapSaver: Failed to open file for writing: %s" % filepath)
		return ""
	
	file.store_string(JSON.stringify(config_data, "\t"))
	file.close()
	
	Log.trace(Log.Level.INFO, "MapSaver: Saved config to %s with seed=%d" % [filepath, config.seed])
	return map_name

## Charge une configuration depuis un fichier
## Retourne la GenConfig, ou null en cas d'erreur
static func load_config(map_name: String) -> GenConfig:
	var filepath = SAVED_MAPS_DIR + map_name + CONFIG_FILE_EXT
	var file = FileAccess.open(filepath, FileAccess.READ)
	
	if file == null:
		Log.trace(Log.Level.ERROR, "MapSaver: Failed to open file for reading: %s" % filepath)
		return null
	
	var json_text = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not parsed.has("config"):
		Log.trace(Log.Level.ERROR, "MapSaver: Invalid config file format")
		return null
	
	var config_data = parsed["config"]
	var config = GenConfig.new()
	
	# Charger tous les champs
	config.width = config_data.get("width", 25)
	config.height = config_data.get("height", 15)
	config.difficulty = config_data.get("difficulty", 1)
	config.style = config_data.get("style", 1)
	config.num_paths = config_data.get("num_paths", 1)
	config.decoration_density = config_data.get("decoration_density", 0.05)
	config.buildable_density = config_data.get("buildable_density", 0.2)
	config.min_path_length = config_data.get("min_path_length", 0)
	config.max_path_length = config_data.get("max_path_length", 0)
	config.min_buildable_zones = config_data.get("min_buildable_zones", 0)
	config.max_buildable_zones = config_data.get("max_buildable_zones", 0)
	config.force_chokepoints = config_data.get("force_chokepoints", false)
	config.obstacle_density = config_data.get("obstacle_density", 0.1)
	config.theme = config_data.get("theme", "default")
	
	# Convertir enemy_types en Array[String]
	var enemy_types_raw = config_data.get("enemy_types", [])
	var enemy_types_array: Array[String] = []
	for item in enemy_types_raw:
		if item is String:
			enemy_types_array.append(item)
	config.enemy_types = enemy_types_array
	
	config.player_level = config_data.get("player_level", 1)
	
	# Charger le seed, ou générer un seed déterministe basé sur les autres paramètres pour les anciennes maps
	var loaded_seed = config_data.get("seed", 0)
	if loaded_seed == 0:
		# Ancienne map sans seed : générer un seed déterministe basé sur les paramètres
		# pour que la map soit au moins reproductible si on recharge plusieurs fois
		var seed_hash = hash(str(config.width) + str(config.height) + str(config.style) + str(config.difficulty) + str(config.num_paths))
		config.seed = abs(seed_hash) % 2147483647  # Limiter à la plage d'un int32
		Log.trace(Log.Level.WARN, "MapSaver: Old map without seed, generated deterministic seed=%d from config" % config.seed)
	else:
		config.seed = loaded_seed
	
	Log.trace(Log.Level.INFO, "MapSaver: Loaded config from %s with seed=%d" % [filepath, config.seed])
	return config

## Liste toutes les maps sauvegardées
## Retourne un array de dictionnaires avec "name" et "created_at"
static func list_saved_maps() -> Array[Dictionary]:
	var maps: Array[Dictionary] = []
	var dir = DirAccess.open(SAVED_MAPS_DIR)
	
	if dir == null:
		# Le dossier n'existe pas encore, retourner une liste vide
		return maps
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(CONFIG_FILE_EXT):
			var map_name = file_name.get_basename()
			var filepath = SAVED_MAPS_DIR + file_name
			var file = FileAccess.open(filepath, FileAccess.READ)
			
			if file != null:
				var json_text = file.get_as_text()
				file.close()
				var parsed = JSON.parse_string(json_text)
				
				if parsed != null:
					maps.append({
						"name": map_name,
						"display_name": parsed.get("map_name", map_name),
						"created_at": parsed.get("created_at", 0)
					})
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Trier par date de création (plus récent en premier)
	maps.sort_custom(func(a, b): return a.created_at > b.created_at)
	
	return maps

## Supprime une map sauvegardée
static func delete_saved_map(map_name: String) -> bool:
	var filepath = SAVED_MAPS_DIR + map_name + CONFIG_FILE_EXT
	var dir = DirAccess.open("user://")
	
	if dir == null:
		return false
	
	var error = dir.remove(filepath)
	if error != OK:
		Log.trace(Log.Level.ERROR, "MapSaver: Failed to delete map: %s (error: %d)" % [filepath, error])
		return false
	
	Log.trace(Log.Level.INFO, "MapSaver: Deleted map: %s" % map_name)
	return true

## Sauvegarde aussi la map en .tscn pour un chargement plus rapide
## (optionnel, pour l'instant on sauvegarde juste la config)
static func save_map_scene(map_instance: Node2D, map_name: String) -> bool:
	# Pour l'instant, on ne sauvegarde que la config
	# On pourrait implémenter la sauvegarde en .tscn plus tard si nécessaire
	return true
