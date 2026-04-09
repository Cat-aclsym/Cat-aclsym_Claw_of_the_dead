## © [2026] A7 Studio. All rights reserved. Trademark.

extends Node
## Manages persistent game progression, settings, and player discoveries.

# Constants
## Tower IDs always buildable without armorer (first tower + kit de départ).
const ARMORY_STARTER_TOWER_IDS: Array[String] = ["bat_01"]
## Trap IDs always buildable without armorer (empty: traps only via armurerie or legacy).
const ARMORY_STARTER_TRAP_IDS: Array[String] = []
const SAVE_PATH: String = "user://progression.dat"
const _TRAP_DATA_SCRIPT: GDScript = preload("res://scripts/progression/trap_data.gd")

# Public variables
var data: ProgressionData = ProgressionData.new()

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


## Checks if there are any enemies that haven't been seen in the encyclopedia.
## Only considers IDs currently known by StatsDB to avoid stale save data entries.
func has_unseen_encyclopedia_enemies() -> bool:
	var known_ids: Array = StatsDB.get_enemy_ids()
	for id in data.enemies:
		if id not in known_ids: continue
		if data.enemies[id].seen and not data.enemies[id].encyclopedia_seen:
			return true
	return false


## Checks if there are any towers that haven't been seen in the encyclopedia.
## Only considers IDs currently known by StatsDB to avoid stale save data entries.
func has_unseen_encyclopedia_towers() -> bool:
	var known_ids: Array = StatsDB.get_tower_ids()
	for id in data.towers:
		if id not in known_ids: continue
		if data.towers[id].unlocked and not data.towers[id].encyclopedia_seen:
			return true
	return false


## Checks if an enemy has been seen in the encyclopedia.
func is_enemy_encyclopedia_seen(enemy_id: String) -> bool:
	if data.enemies.has(enemy_id):
		return data.enemies[enemy_id].encyclopedia_seen
	return false


## Checks if an enemy has been seen.
func is_enemy_seen(enemy_id: String) -> bool:
	if data.enemies.has(enemy_id):
		return data.enemies[enemy_id].seen
	return false


## Checks if a level is unlocked.
func is_level_unlocked(level_id: String) -> bool:
	if data.levels.has(level_id):
		return data.levels[level_id].unlocked
	return false


## Checks if a tower has been seen in the encyclopedia.
func is_tower_encyclopedia_seen(tower_id: String) -> bool:
	if data.towers.has(tower_id):
		return data.towers[tower_id].encyclopedia_seen
	return false


## Checks if a tower is unlocked.
func is_tower_unlocked(tower_id: String) -> bool:
	if data.armory_legacy_mode:
		return true
	if tower_id in ARMORY_STARTER_TOWER_IDS:
		return true
	if data.towers.has(tower_id):
		return data.towers[tower_id].unlocked
	return false


## Checks if a trap is unlocked for the construction menu.
func is_trap_unlocked(trap_id: String) -> bool:
	if data.armory_legacy_mode:
		return true
	if trap_id in ARMORY_STARTER_TRAP_IDS:
		return true
	if data.traps.has(trap_id):
		return data.traps[trap_id].unlocked
	return false


## Returns whether the first-play tutorial has been completed.
func is_tutorial_completed() -> bool:
	return data.parameters.tutorial_completed


## Marks the first-play tutorial as completed and persists it.
func mark_tutorial_completed() -> void:
	if data.parameters.tutorial_completed:
		return
	data.parameters.tutorial_completed = true
	save_game()


## Total stars earned (one per challenge completed, any level).
func get_total_earned_stars() -> int:
	var total: int = 0
	for level_id in data.levels.keys():
		var ld: LevelData = data.levels[level_id]
		total += ld.challenges_completed.size()
	return total


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

	var saw_armory: bool = false
	var had_any_record: bool = false

	while file.get_position() < file.get_length():
		var node_data: Variant = file.get_var()

		if typeof(node_data) != TYPE_DICTIONARY:
			continue

		if not node_data.has("type"):
			continue

		had_any_record = true

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
			"trap":
				var trap_id: String = node_data["id"]
				if not data.traps.has(trap_id):
					data.traps[trap_id] = _TRAP_DATA_SCRIPT.new()
				data.traps[trap_id].from_dictionary(node_data)
			"armory":
				saw_armory = true
				data.armory_purchased.assign(node_data.get("purchased", []))
				data.armory_legacy_mode = node_data.get("legacy_mode", false)

	file.close()

	if had_any_record and not saw_armory:
		data.armory_legacy_mode = true
		_unlock_all_buildings_for_legacy_migration()

	apply_settings()
	Log.trace(Log.Level.DEBUG, "Game loaded from %s (absolute: %s)" % [SAVE_PATH, file.get_path_absolute()])
	Log.trace(Log.Level.DEBUG, "Data: %s" % data.save())


## Marks an enemy as seen in the encyclopedia.
func mark_enemy_encyclopedia_seen(enemy_id: String) -> void:
	if not data.enemies.has(enemy_id):
		data.enemies[enemy_id] = EnemyData.new()

	if not data.enemies[enemy_id].encyclopedia_seen:
		data.enemies[enemy_id].encyclopedia_seen = true
		Log.trace(Log.Level.DEBUG, "Enemy seen in encyclopedia: " + enemy_id)
		save_game()


## Marks an enemy as seen / discovered.
func mark_enemy_seen(enemy_id: String) -> void:
	if not data.enemies.has(enemy_id):
		data.enemies[enemy_id] = EnemyData.new()

	if not data.enemies[enemy_id].seen:
		data.enemies[enemy_id].seen = true
		Log.trace(Log.Level.DEBUG, "New enemy discovered: " + enemy_id)
		save_game()


## Marks a tower as seen in the encyclopedia.
func mark_tower_encyclopedia_seen(tower_id: String) -> void:
	if not data.towers.has(tower_id):
		data.towers[tower_id] = TowerData.new()

	if not data.towers[tower_id].encyclopedia_seen:
		data.towers[tower_id].encyclopedia_seen = true
		Log.trace(Log.Level.DEBUG, "Tower seen in encyclopedia: " + tower_id)
		save_game()


## Resets progression to default state.
func reset_progression() -> void:
	_init_default_data()
	apply_settings()
	save_game()
	Log.trace(Log.Level.DEBUG, "Progression reset to default.")


## Clears armory node purchases so stars become available again. Non-starter buildings are locked unless [member ProgressionData.armory_legacy_mode].
func reset_armory_spending() -> void:
	data.armory_purchased.clear()
	if not data.armory_legacy_mode:
		_apply_starter_only_building_unlocks()
	save_game()
	Log.trace(Log.Level.INFO, "Armory purchases reset; building locks synced to starters (unless legacy save).")


## Saves the current progression to disk.
func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		Log.trace(Log.Level.ERROR, "Failed to save game to %s" % SAVE_PATH)
		return

	# Save Enemies
	for id in data.enemies:
		var enemy_obj: EnemyData = data.enemies[id]
		var enemy_data: Dictionary = enemy_obj.save()
		enemy_data["type"] = "enemy"
		enemy_data["id"] = id
		file.store_var(enemy_data)

	# Save Levels
	for id in data.levels:
		var level_obj: LevelData = data.levels[id]
		var level_data: Dictionary = level_obj.save()
		level_data["type"] = "level"
		level_data["id"] = id
		file.store_var(level_data)

	# Save Parameters
	var params_data: Dictionary = data.parameters.save()
	params_data["type"] = "parameters"
	file.store_var(params_data)

	# Save Towers
	for id in data.towers:
		var tower_obj: TowerData = data.towers[id]
		var tower_data: Dictionary = tower_obj.save()
		tower_data["type"] = "tower"
		tower_data["id"] = id
		file.store_var(tower_data)

	# Save Traps
	for id in data.traps:
		var trap_obj: Object = data.traps[id]
		var trap_data: Dictionary = trap_obj.save()
		trap_data["type"] = "trap"
		trap_data["id"] = id
		file.store_var(trap_data)

	var armory_blob: Dictionary = {
		"type": "armory",
		"purchased": data.armory_purchased.duplicate(),
		"legacy_mode": data.armory_legacy_mode
	}
	file.store_var(armory_blob)

	file.close()
	Log.trace(Log.Level.DEBUG, "Game saved to %s (absolute: %s)" % [SAVE_PATH, file.get_path_absolute()])


## Unlocks a level by ID.
func unlock_level(level_id: String) -> void:
	if not data.levels.has(level_id):
		data.levels[level_id] = LevelData.new()

	data.levels[level_id].unlocked = true
	save_game()


## Unlocks a tower by ID.
func unlock_tower(tower_id: String) -> void:
	unlock_tower_no_save(tower_id)
	save_game()


## Unlocks a tower without writing the save file (batch with [method save_game]).
func unlock_tower_no_save(tower_id: String) -> void:
	if not data.towers.has(tower_id):
		data.towers[tower_id] = TowerData.new()

	data.towers[tower_id].unlocked = true


## Unlocks a trap by ID for the construction menu.
func unlock_trap(trap_id: String) -> void:
	unlock_trap_no_save(trap_id)
	save_game()


## Unlocks a trap without writing the save file.
func unlock_trap_no_save(trap_id: String) -> void:
	if not data.traps.has(trap_id):
		data.traps[trap_id] = _TRAP_DATA_SCRIPT.new()

	data.traps[trap_id].unlocked = true


# Private functions
func _init_default_data() -> void:
	data = ProgressionData.new()

	# Default values
	# Unlock Level 1
	if not data.levels.has("lev.01"):
		data.levels["lev.01"] = LevelData.new()
	data.levels["lev.01"].unlocked = true

	data.armory_purchased.clear()
	data.armory_legacy_mode = false

	_apply_starter_only_building_unlocks()


func _apply_starter_only_building_unlocks() -> void:
	for tid in StatsDB.get_tower_ids():
		if not data.towers.has(tid):
			data.towers[tid] = TowerData.new()
		data.towers[tid].unlocked = tid in ARMORY_STARTER_TOWER_IDS

	for trap_key in StatsDB.get_trap_ids():
		if not data.traps.has(trap_key):
			data.traps[trap_key] = _TRAP_DATA_SCRIPT.new()
		data.traps[trap_key].unlocked = trap_key in ARMORY_STARTER_TRAP_IDS


func _unlock_all_buildings_for_legacy_migration() -> void:
	for tid in StatsDB.get_tower_ids():
		unlock_tower_no_save(tid)
	for trap_key in StatsDB.get_trap_ids():
		unlock_trap_no_save(trap_key)
	save_game()
	Log.trace(Log.Level.INFO, "Armory: legacy save migrated — all buildings unlocked, armory_legacy_mode on")
