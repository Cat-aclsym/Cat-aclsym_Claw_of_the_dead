## © [2026] A7 Studio. All rights reserved. Trademark.

extends Node
## Manages persistent game progression, settings, and player discoveries.

# Constants
const SAVE_PATH: String = "user://progression.dat"

# Public variables
var data := ProgressionData.new()

# Built-in functions
func _ready() -> void:
	load_game()

# Public functions
## Applies the current settings to the game.
func apply_settings() -> void:
	# Set language
	TranslationServer.set_locale(data.parameters.language)

	# Set audio volumes
	var music_vol: float = 0.0 if data.parameters.music_enabled else -80.0
	var sound_vol: float = 0.0 if data.parameters.sound_enabled else -80.0
	SoundManager.change_volume("music", music_vol)
	SoundManager.change_volume("sfx", sound_vol)


## Marks a challenge as completed for a level.
func complete_challenge(level_id: String, challenge_id: String) -> void:
	if not data.levels.has(level_id):
		data.levels[level_id] = LevelData.new()

	var level_data: LevelData = data.levels[level_id]
	if not challenge_id in level_data.challenges_completed:
		level_data.challenges_completed.append(challenge_id)
		save_game()


## Marks a level as completed and unlocks the next one.
func complete_level(level_id: String) -> void:
	# Unlock the next level
	var next_level_id := get_next_level_id(level_id)
	if not next_level_id.is_empty():
		if not data.levels.has(next_level_id):
			data.levels[next_level_id] = LevelData.new()
		data.levels[next_level_id].unlocked = true
		Log.trace(Log.Level.DEBUG, "Unlocked next level: " + next_level_id)

	save_game()


## Returns the ID of the next level based on the given current level ID.
## If the current ID does not match the expected format (e.g., "lev.01"), returns an empty string.
func get_next_level_id(current_id: String) -> String:
	var regex := RegEx.new()
	regex.compile("lev\\.(\\d+)")
	var result: RegExMatch = regex.search(current_id)
	if result:
		var num := int(result.get_string(1))
		var next_num := num + 1
		return "lev.%02d" % next_num
	return ""


## Checks if a level is unlocked.
func is_level_unlocked(level_id: String) -> bool:
	if data.levels.has(level_id):
		return data.levels[level_id].unlocked
	return false


## Loads the progression from disk.
func load_game() -> void:
	_init_default_data()

	if not FileAccess.file_exists(SAVE_PATH):
		Log.trace(Log.Level.DEBUG, "No save file found. Using defaults.")
		save_game() # Save the defaults
		# Apply default settings immediately so UI shows the correct state on first launch.
		apply_settings()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		Log.trace(Log.Level.ERROR, "Failed to open save file " + SAVE_PATH)
		return

	while file.get_position() < file.get_length():
		var node_data: Variant = file.get_var()

		if typeof(node_data) != TYPE_DICTIONARY:
			continue

		if not node_data.has("type"):
			continue

		match node_data["type"]:
			"enemy":
				var id: String = node_data["id"]
				if not data.enemies.has(id):
					data.enemies[id] = EnemyData.new()
				data.enemies[id].from_dictionary(node_data)
			"level":
				var id: String = node_data["id"]
				if not data.levels.has(id):
					data.levels[id] = LevelData.new()
				data.levels[id].from_dictionary(node_data)
			"parameters":
				data.parameters.from_dictionary(node_data)
			"tower":
				var id: String = node_data["id"]
				if not data.towers.has(id):
					data.towers[id] = TowerData.new()
				data.towers[id].from_dictionary(node_data)

	file.close()
	apply_settings()
	Log.trace(Log.Level.DEBUG, "Game loaded from %s (absolute: %s)" % [SAVE_PATH, file.get_path_absolute()])


## Marks an enemy as seen / discovered.
func mark_enemy_seen(enemy_id: String) -> void:
	if not data.enemies.has(enemy_id):
		data.enemies[enemy_id] = EnemyData.new()

	if not data.enemies[enemy_id].seen:
		data.enemies[enemy_id].seen = true
		Log.trace(Log.Level.DEBUG, "New enemy discovered: " + enemy_id)
		save_game()


## Resets progression to default state.
func reset_progression() -> void:
	_init_default_data()
	apply_settings()
	save_game()
	Log.trace(Log.Level.DEBUG, "Progression reset to default.")


## Saves the current progression to disk.
func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		Log.trace(Log.Level.ERROR, "Failed to save game to %s" % SAVE_PATH)
		return

	# Save Parameters
	var params_data: Dictionary = data.parameters.save()
	params_data["type"] = "parameters"
	file.store_var(params_data)

	# Save Levels
	for id in data.levels:
		var level_obj: LevelData = data.levels[id]
		var level_data: Dictionary = level_obj.save()
		level_data["type"] = "level"
		level_data["id"] = id
		file.store_var(level_data)

	# Save Towers
	for id in data.towers:
		var tower_obj: TowerData = data.towers[id]
		var tower_data: Dictionary = tower_obj.save()
		tower_data["type"] = "tower"
		tower_data["id"] = id
		file.store_var(tower_data)

	# Save Enemies
	for id in data.enemies:
		var enemy_obj: EnemyData = data.enemies[id]
		var enemy_data: Dictionary = enemy_obj.save()
		enemy_data["type"] = "enemy"
		enemy_data["id"] = id
		file.store_var(enemy_data)

	file.close()
	Log.trace(Log.Level.DEBUG, "Game saved to %s (absolute: %s)" % [SAVE_PATH, file.get_path_absolute()])


## Unlocks a tower by ID.
func unlock_tower(tower_id: String) -> void:
	if not data.towers.has(tower_id):
		data.towers[tower_id] = TowerData.new()

	data.towers[tower_id].unlocked = true
	save_game()

# Private functions
func _init_default_data() -> void:
	data = ProgressionData.new()

	# Default values
	# Unlock Level 1
	if not data.levels.has("lev.01"):
		data.levels["lev.01"] = LevelData.new()
	data.levels["lev.01"].unlocked = true

	# Unlock all towers by default
	for tower_type in ITower.TowerType.values():
		var tid := str(tower_type)
		if not data.towers.has(tid):
			data.towers[tid] = TowerData.new()
		data.towers[tid].unlocked = true
