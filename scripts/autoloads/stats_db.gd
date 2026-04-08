## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Charge et expose les stats centralisées (tours, pièges, upgrades, ennemis) depuis un JSON.
extends Node

# Constants
const STATS_PATH: String = "res://assets/resources/configs/stats.json"

# Private variables
var _data: Dictionary = {}


# Built-in functions
func _ready() -> void:
	_data = _load_json(STATS_PATH)
	var towers_count: int = _data.get("towers", {}).size()
	var traps_count: int = _data.get("traps", {}).size()
	var enemies_count: int = _data.get("enemies", {}).size()
	var upgrades_count: int = _data.get("upgrades", {}).size()
	Log.trace(Log.Level.INFO, "StatsDB loaded: towers=%s, traps=%s, enemies=%s, upgrades=%s" % [towers_count, traps_count, enemies_count, upgrades_count])


# Public functions
func get_tower(id: String) -> Dictionary:
	return _data.get("towers", {}).get(id, {})


func get_tower_name(id: String) -> String:
	var tower: Dictionary = get_tower(id)
	return tower.get("name", "") if not tower.is_empty() else ""


func get_tower_level(id: String) -> int:
	var tower: Dictionary = get_tower(id)
	return tower.get("level", 1) if not tower.is_empty() else 1


func get_upgrade(id: String) -> Dictionary:
	return _data.get("upgrades", {}).get(id, {})


func get_upgrade_price(id: String) -> int:
	var upgrade: Dictionary = get_upgrade(id)
	return int(upgrade.get("price", 0)) if not upgrade.is_empty() else 0


func get_upgrade_tower_stats(id: String) -> Dictionary:
	var upgrade: Dictionary = get_upgrade(id)
	if upgrade.is_empty():
		return {}
	return upgrade.get("tower_stats", {})


func get_upgrade_bullet_stats(id: String) -> Dictionary:
	var upgrade: Dictionary = get_upgrade(id)
	if upgrade.is_empty():
		return {}
	return upgrade.get("bullet_stats", {})


func get_upgrade_next_ids(id: String) -> Array[String]:
	var upgrade: Dictionary = get_upgrade(id)
	if upgrade.is_empty():
		return []
	var raw_next: Variant = upgrade.get("next", [])
	var next_ids: Array[String] = []
	if raw_next is Array:
		for next_id in raw_next:
			next_ids.append(str(next_id))
	return next_ids


func get_upgrade_bullet_scene_path(id: String) -> String:
	var upgrade: Dictionary = get_upgrade(id)
	if upgrade.is_empty():
		return ""
	if upgrade.has("bullet_scene_path"):
		return str(upgrade.get("bullet_scene_path", ""))
	# Backward compatibility for old key.
	if upgrade.has("bullet"):
		return str(upgrade.get("bullet", ""))
	return ""


func get_upgrade_bullet_scene(id: String) -> PackedScene:
	var path: String = get_upgrade_bullet_scene_path(id)
	return load_packed_scene(path)


func get_upgrade_changes(id: String) -> Dictionary:
	var upgrade: Dictionary = get_upgrade(id)
	if upgrade.is_empty():
		return {}
	return upgrade.get("changes", {})


func get_enemy(id: String) -> Dictionary:
	return _data.get("enemies", {}).get(id, {})


func get_trap(id: String) -> Dictionary:
	return _data.get("traps", {}).get(id, {})


func get_trap_name(id: String) -> String:
	var trap: Dictionary = get_trap(id)
	return trap.get("name", "") if not trap.is_empty() else ""


func get_tower_ids() -> Array:
	return _data.get("towers", {}).keys()


func get_enemy_ids() -> Array:
	return _data.get("enemies", {}).keys()


func get_trap_ids() -> Array:
	return _data.get("traps", {}).keys()


func get_upgrade_ids_for_tower(id: String) -> Array[String]:
	if not has_tower(id):
		return []
	var raw_upgrade_ids: Variant = get_tower(id).get("upgrades", [])
	var upgrade_ids: Array[String] = []
	if raw_upgrade_ids is Array:
		for upgrade_id in raw_upgrade_ids:
			upgrade_ids.append(str(upgrade_id))
	return upgrade_ids


func has_tower(id: String) -> bool:
	return _data.get("towers", {}).has(id)


func has_upgrade(id: String) -> bool:
	return _data.get("upgrades", {}).has(id)


func has_enemy(id: String) -> bool:
	return _data.get("enemies", {}).has(id)


func has_trap(id: String) -> bool:
	return _data.get("traps", {}).has(id)


func load_packed_scene(path: String) -> PackedScene:
	if path.is_empty():
		return null
	var res: Resource = load(path)
	return res if res is PackedScene else null


# Private functions
func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("StatsDB: fichier introuvable %s" % path)
		return {}
	var content: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("StatsDB: format JSON inattendu pour %s" % path)
		return {}
	return parsed


