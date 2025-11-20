extends Node

const SAVE_PATH: String = "user://progression.json"

var data := ProgressionData.new()

func _ready() -> void:
	load_game()

## Saves the current progression to disk.
func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string := JSON.stringify(data.to_dictionary(), "\t")
		file.store_string(json_string)
		file.close()
		Log.trace(Log.Level.DEBUG, "Game saved to %s (absolute: %s)" % [SAVE_PATH, file.get_path_absolute()])
	else:
		Log.trace(Log.Level.ERROR, "Failed to save game to %s (absolute: %s)" % [SAVE_PATH, file.get_path_absolute()])

## Loads the progression from disk.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		Log.trace(Log.Level.DEBUG, "No save file found. Creating new progression.")
		reset_progression()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json := JSON.new()
		var error := json.parse(json_string)
		if error == OK:
			data.from_dictionary(json.data)
			Log.trace(Log.Level.DEBUG, "Game loaded from %s (absolute: %s)" % [SAVE_PATH, file.get_path_absolute()])
			apply_settings()
		else:
			Log.trace(Log.Level.ERROR, "JSON Parse Error: %s in %s at line %s" % [json.get_error_message(), json_string, str(json.get_error_line())])
			reset_progression()
	else:
		Log.trace(Log.Level.ERROR, "Failed to open save file " + SAVE_PATH)
		reset_progression()

## Resets progression to default state.
func reset_progression() -> void:
	data = ProgressionData.new()

	# Default values
	# Unlock Level 1
	unlock_level("lev.01")

	# Unlock all towers by default
	for tower_type in ITower.TowerType.values():
		unlock_tower(str(tower_type))

	apply_settings()
	save_game()
	Log.trace(Log.Level.DEBUG, "Progression reset to default.")

## Unlocks a level by ID.
func unlock_level(level_id: String) -> void:
	if not data.levels.has(level_id):
		data.levels[level_id] = LevelData.new()

	data.levels[level_id].unlocked = true
	save_game()

## Marks a challenge as completed for a level.
func complete_challenge(level_id: String, challenge_id: String) -> void:
	if not data.levels.has(level_id):
		data.levels[level_id] = LevelData.new()

	var level_data: LevelData = data.levels[level_id]
	if not challenge_id in level_data.challenges_completed:
		level_data.challenges_completed.append(challenge_id)
		save_game()

## Unlocks a tower by ID.
func unlock_tower(tower_id: String) -> void:
	if not data.towers.has(tower_id):
		data.towers[tower_id] = TowerData.new()

	data.towers[tower_id].unlocked = true
	save_game()

## Checks if a level is unlocked.
func is_level_unlocked(level_id: String) -> bool:
	if data.levels.has(level_id):
		return data.levels[level_id].unlocked
	return false

## Applies the current settings to the game.
func apply_settings() -> void:
	# Set language
	TranslationServer.set_locale(data.parameters.language)

	# Set audio volumes
	var music_vol: float = 0.0 if data.parameters.music_volume else -80.0
	var sound_vol: float = 0.0 if data.parameters.sound_volume else -80.0
	SoundManager.change_volume("music", music_vol)
	SoundManager.change_volume("sfx", sound_vol)
