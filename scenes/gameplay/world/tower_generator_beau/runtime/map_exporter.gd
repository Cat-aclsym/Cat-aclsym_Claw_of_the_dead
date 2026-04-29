## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Système d'export/import de maps.
## Permet de partager des maps avec un code ou un fichier.

class_name MapExporter
extends RefCounted

## Exporte une config en code de partage (base64)
static func export_to_code(config: GenConfig) -> String:
	var config_dict = {
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
	
	var json_string = JSON.stringify(config_dict)
	var base64 = Marshalls.utf8_to_base64(json_string)
	return base64

## Importe une config depuis un code de partage
static func import_from_code(code: String) -> GenConfig:
	var json_string = Marshalls.base64_to_utf8(code)
	var parsed = JSON.parse_string(json_string)
	
	if parsed == null:
		Log.trace(Log.Level.ERROR, "MapExporter: Invalid code format")
		return null
	
	var config = GenConfig.new()
	config.width = parsed.get("width", config.width)
	config.height = parsed.get("height", config.height)
	config.difficulty = parsed.get("difficulty", config.difficulty)
	config.style = parsed.get("style", config.style)
	config.num_paths = parsed.get("num_paths", config.num_paths)
	config.decoration_density = parsed.get("decoration_density", config.decoration_density)
	config.buildable_density = parsed.get("buildable_density", config.buildable_density)
	config.min_path_length = parsed.get("min_path_length", config.min_path_length)
	config.max_path_length = parsed.get("max_path_length", config.max_path_length)
	config.min_buildable_zones = parsed.get("min_buildable_zones", config.min_buildable_zones)
	config.max_buildable_zones = parsed.get("max_buildable_zones", config.max_buildable_zones)
	config.force_chokepoints = parsed.get("force_chokepoints", config.force_chokepoints)
	config.obstacle_density = parsed.get("obstacle_density", config.obstacle_density)
	config.theme = parsed.get("theme", config.theme)
	config.enemy_types = Array(parsed.get("enemy_types", []))
	config.player_level = parsed.get("player_level", config.player_level)
	config.seed = parsed.get("seed", config.seed)
	
	return config

## Exporte une config vers un fichier JSON
static func export_to_file(config: GenConfig, filepath: String) -> bool:
	var config_dict = {
		"version": 2,
		"exported_at": Time.get_unix_time_from_system(),
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
	
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		Log.trace(Log.Level.ERROR, "MapExporter: Failed to open file for writing: %s" % filepath)
		return false
	
	file.store_string(JSON.stringify(config_dict, "\t"))
	file.close()
	
	Log.trace(Log.Level.INFO, "MapExporter: Exported config to %s" % filepath)
	return true

## Importe une config depuis un fichier JSON
static func import_from_file(filepath: String) -> GenConfig:
	var file = FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		Log.trace(Log.Level.ERROR, "MapExporter: Failed to open file for reading: %s" % filepath)
		return null
	
	var json_text = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not parsed.has("config"):
		Log.trace(Log.Level.ERROR, "MapExporter: Invalid file format")
		return null
	
	var config_data = parsed["config"]
	var config = GenConfig.new()
	config.width = config_data.get("width", config.width)
	config.height = config_data.get("height", config.height)
	config.difficulty = config_data.get("difficulty", config.difficulty)
	config.style = config_data.get("style", config.style)
	config.num_paths = config_data.get("num_paths", config.num_paths)
	config.decoration_density = config_data.get("decoration_density", config.decoration_density)
	config.buildable_density = config_data.get("buildable_density", config.buildable_density)
	config.min_path_length = config_data.get("min_path_length", config.min_path_length)
	config.max_path_length = config_data.get("max_path_length", config.max_path_length)
	config.min_buildable_zones = config_data.get("min_buildable_zones", config.min_buildable_zones)
	config.max_buildable_zones = config_data.get("max_buildable_zones", config.max_buildable_zones)
	config.force_chokepoints = config_data.get("force_chokepoints", config.force_chokepoints)
	config.obstacle_density = config_data.get("obstacle_density", config.obstacle_density)
	config.theme = config_data.get("theme", config.theme)
	config.enemy_types = Array(config_data.get("enemy_types", []))
	config.player_level = config_data.get("player_level", config.player_level)
	config.seed = config_data.get("seed", config.seed)
	
	Log.trace(Log.Level.INFO, "MapExporter: Imported config from %s" % filepath)
	return config
