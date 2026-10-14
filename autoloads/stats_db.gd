## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Loads and exposes the centralized stats (towers, traps, upgrades, enemies) from a JSON file.
extends Node

# Constants
const STATS_PATH: String = "res://data/stats.json"

# Private variables
var _data: Dictionary = {}
var _enemy_scenes: Dictionary[String, PackedScene] = {}
## Script variables of each script given to [method apply_fields], see [method _get_script_fields].
var _script_fields: Dictionary[Script, Dictionary] = {}


# Built-in functions
func _ready() -> void:
	_data = JsonUtil.load_dict(STATS_PATH)
	var towers_count: int = _data.get("towers", {}).size()
	var traps_count: int = _data.get("traps", {}).size()
	var enemies_count: int = _data.get("enemies", {}).size()
	var upgrades_count: int = _data.get("upgrades", {}).size()
	Log.trace(Log.Level.INFO, "StatsDB loaded: towers=%s, traps=%s, enemies=%s, upgrades=%s" % [towers_count, traps_count, enemies_count, upgrades_count])


# Public functions
## Writes each entry of [param values] to the script variable of [param target] with the same name, converted to the type of that variable.
## [br]Only the typed variables of the script of [param target] and of its base scripts are written: built-in properties (position, scale...),
## untyped variables, numeric variables given a non-numeric text and the [code]speed[/code] of an [IEnemy] (derived from [code]base_speed[/code]) are refused.
## Each refused entry is logged as an error and skipped.
## [br]Example: [code]StatsDB.apply_fields(trap, StatsDB.get_trap("bat_04")["base"])[/code] sets [code]trap.slow_amount[/code] from the [code]slow_amount[/code] key.
func apply_fields(target: Object, values: Dictionary) -> void:
	var fields: Dictionary = _get_script_fields(target)
	for key: String in values:
		var value: Variant = values[key]
		var field_type: int = fields.get(key, TYPE_MAX)
		if target is IEnemy and key == "speed":
			Log.trace(Log.Level.ERROR, "StatsDB: the speed of %s is derived from its base speed, use the top-level 'speed' stat." % target)
		elif field_type == TYPE_MAX:
			Log.trace(Log.Level.ERROR, "StatsDB: %s has no script variable '%s'." % [target, key])
		elif field_type == TYPE_NIL:
			Log.trace(Log.Level.ERROR, "StatsDB: the variable '%s' of %s has no type to convert to." % [key, target])
		elif field_type in [TYPE_INT, TYPE_FLOAT] and value is String and not (value as String).is_valid_float():
			Log.trace(Log.Level.ERROR, "StatsDB: '%s' of %s is a number, '%s' is not." % [key, target, value])
		else:
			target.set(key, type_convert(value, field_type))


## Returns the gameplay constants of the bullet [param id] (a key of the [code]bullets[/code] section).
func get_bullet(id: String) -> Dictionary:
	return _data.get("bullets", {}).get(id, {})


func get_enemy(id: String) -> Dictionary:
	return _data.get("enemies", {}).get(id, {})


func get_enemy_ids() -> Array:
	return _data.get("enemies", {}).keys()


## Returns the scene of the enemy [param id] (a key of the [code]enemies[/code] section), loaded on first use.
## [br]Logs an error and returns [code]null[/code] when the id is unknown or its scene cannot be loaded.
func get_enemy_scene(id: String) -> PackedScene:
	if _enemy_scenes.has(id):
		return _enemy_scenes[id]

	var scene_path: String = get_enemy(id).get("scene", "")
	var scene: PackedScene = load_packed_scene(scene_path)
	if scene == null:
		Log.trace(Log.Level.ERROR, "No enemy scene for enemy id '%s' (scene path: '%s')" % [id, scene_path])
		return null

	_enemy_scenes[id] = scene
	return scene


## Returns the map tile modifiers of [param kind] ("bonus" or "malus") in their declared order,
## each as [code]{"stat": String, "multiplier": float}[/code].
func get_tile_modifiers(kind: String) -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	modifiers.assign(_data.get("tile_modifiers", {}).get(kind, []))
	return modifiers


func get_tower(id: String) -> Dictionary:
	return _data.get("towers", {}).get(id, {})


func get_tower_ids() -> Array:
	return _data.get("towers", {}).keys()


func get_tower_level(id: String) -> int:
	return int(get_tower(id).get("level", 1))


func get_trap(id: String) -> Dictionary:
	return _data.get("traps", {}).get(id, {})


func get_trap_ids() -> Array:
	return _data.get("traps", {}).keys()


func get_upgrade(id: String) -> Dictionary:
	return _data.get("upgrades", {}).get(id, {})


func get_upgrade_bullet_scene(id: String) -> PackedScene:
	return load_packed_scene(str(get_upgrade(id).get("bullet_scene_path", "")))


func get_upgrade_bullet_stats(id: String) -> Dictionary:
	return get_upgrade(id).get("bullet_stats", {})


func get_upgrade_changes(id: String) -> Dictionary:
	return get_upgrade(id).get("changes", {})


func get_upgrade_ids_for_tower(id: String) -> Array[String]:
	var upgrade_ids: Array[String] = []
	upgrade_ids.assign(get_tower(id).get("upgrades", []))
	return upgrade_ids


func get_upgrade_next_ids(id: String) -> Array[String]:
	var next_ids: Array[String] = []
	next_ids.assign(get_upgrade(id).get("next", []))
	return next_ids


func get_upgrade_price(id: String) -> int:
	return int(get_upgrade(id).get("price", 0))


func get_upgrade_tower_stats(id: String) -> Dictionary:
	return get_upgrade(id).get("tower_stats", {})


func has_enemy(id: String) -> bool:
	return _data.get("enemies", {}).has(id)


func has_tower(id: String) -> bool:
	return _data.get("towers", {}).has(id)


func has_trap(id: String) -> bool:
	return _data.get("traps", {}).has(id)


func has_upgrade(id: String) -> bool:
	return _data.get("upgrades", {}).has(id)


func load_packed_scene(path: String) -> PackedScene:
	if path.is_empty():
		return null
	var res: Resource = load(path)
	return res if res is PackedScene else null


## Returns the translation key of the name of an entry, e.g. [code]name_key("TOWER", "bat_01")[/code] is [code]TOWER.BAT_01.NAME[/code].
## [br][param category] is [code]"TOWER"[/code], [code]"TRAP"[/code] or [code]"ENEMY"[/code].
func name_key(category: String, id: String) -> String:
	return "%s.%s.NAME" % [category, id.to_upper()]


# Private functions
## Returns the script variables of [param target] (its script and its base scripts) by name, each with its [enum Variant.Type] ([code]TYPE_NIL[/code] when untyped).
## [br]Computed once per script.
func _get_script_fields(target: Object) -> Dictionary:
	var script: Script = target.get_script()
	if script == null:
		return {}
	if not _script_fields.has(script):
		var fields: Dictionary[String, int] = {}
		for property: Dictionary in script.get_script_property_list():
			if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
				fields[property["name"]] = property["type"]
		_script_fields[script] = fields
	return _script_fields[script]
