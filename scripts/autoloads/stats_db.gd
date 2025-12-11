## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Charge et expose les stats centralisées (tours, upgrades, ennemis) depuis un JSON.
extends Node

const STATS_PATH: String = "res://assets/resources/configs/stats.json"

var _data: Dictionary = {}
var _upgrade_by_scene: Dictionary = {}


func _ready() -> void:
	_data = _load_json(STATS_PATH)
	_index_upgrades_by_scene()


func get_tower(id: String) -> Dictionary:
	return _data.get("towers", {}).get(id, {})


func get_upgrade(id: String) -> Dictionary:
	return _data.get("upgrades", {}).get(id, {})


func get_enemy(id: String) -> Dictionary:
	return _data.get("enemies", {}).get(id, {})


func get_upgrade_ids_for_tower(id: String) -> Array:
	return get_tower(id).get("upgrades", []) if has_tower(id) else []


func has_tower(id: String) -> bool:
	return _data.get("towers", {}).has(id)


func has_upgrade(id: String) -> bool:
	return _data.get("upgrades", {}).has(id)


func upgrade_id_from_scene(path: String) -> String:
	if path.is_empty():
		return ""
	return _upgrade_by_scene.get(path, "")


func has_enemy(id: String) -> bool:
	return _data.get("enemies", {}).has(id)


func load_packed_scene(path: String) -> PackedScene:
	if path.is_empty():
		return null
	var res: Resource = load(path)
	return res if res is PackedScene else null


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


func _index_upgrades_by_scene() -> void:
	_upgrade_by_scene.clear()
	var upgrades: Dictionary = _data.get("upgrades", {})
	for id in upgrades.keys():
		var upgrade: Dictionary = upgrades.get(id, {})
		if upgrade.has("scene"):
			_upgrade_by_scene[upgrade["scene"]] = id
