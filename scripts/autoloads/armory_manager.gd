## © [2026] A7 Studio. All rights reserved. Trademark.

extends Node
## Loads armory meta nodes, validates [code]armory.json[/code], and applies purchases (unlocks, buffs, upgrade injection).

# Signals
signal armory_updated()

# Constants
const ARMORY_JSON_PATH: String = "res://resources/armory/armory.json"

# Private variables
var _nodes_by_id: Dictionary = {}
var _ordered_node_ids: Array[String] = []
var _upgrade_gates_by_id: Dictionary = {} ## upgrade id -> required armory node id


# Built-in functions
func _ready() -> void:
	_load_and_validate()


# Public functions
## Appends upgrade IDs from purchased [code]append_tower_upgrade[/code] effects.
func append_unlocked_upgrade_ids(tower: ITower) -> void:
	if tower == null or tower.tower_id.is_empty():
		return
	if _legacy_mode():
		return
	for node_id in ProgressionManager.data.armory_purchased:
		var node: Dictionary = _nodes_by_id.get(node_id, {})
		if node.is_empty():
			continue
		for eff in node.get("effects", []):
			if eff.get("type", "") != "append_tower_upgrade":
				continue
			if eff.get("tower_id", "") != tower.tower_id:
				continue
			var appended_upgrade_id: String = str(eff.get("upgrade_id", ""))
			if appended_upgrade_id.is_empty() or not StatsDB.has_upgrade(appended_upgrade_id):
				Log.trace(Log.Level.WARN, "Armory: invalid append_tower_upgrade effect in node %s" % node_id)
				continue
			if appended_upgrade_id in tower.available_upgrade_ids:
				continue
			tower.available_upgrade_ids.append(appended_upgrade_id)


## Applies aggregated [code]core_buff[/code] multipliers after [method ITower.apply_stats_from_db].
func apply_buffs_to_tower(tower: ITower) -> void:
	if tower == null or tower.tower_id.is_empty():
		return
	if _legacy_mode():
		return
	var f: Dictionary = _aggregate_tower_buffs()
	var fr_mult: float = float(f.get("fire_rate_mult", 1.0))
	var sr_mult: float = float(f.get("shoot_range_mult", 1.0))
	var dmg_mult: float = float(f.get("bullet_damage_mult", 1.0))
	if fr_mult != 1.0:
		tower.fire_rate *= fr_mult
	if sr_mult != 1.0:
		tower.shoot_range *= sr_mult
	if dmg_mult != 1.0 and tower.bullet_stats.has("damage"):
		tower.bullet_stats["damage"] = float(tower.bullet_stats["damage"]) * dmg_mult


## True when every prerequisite node id in [code]armory.json[/code] is already purchased.
func are_prerequisites_met(node_id: String) -> bool:
	if node_id.is_empty():
		return false
	var node: Dictionary = _nodes_by_id.get(node_id, {})
	if node.is_empty():
		return false
	for p in node.get("prerequisites", []):
		if not is_node_purchased(str(p)):
			return false
	return true


## Returns true if the player can spend stars on this node.
func can_purchase(node_id: String) -> bool:
	if node_id.is_empty() or _legacy_mode():
		return false
	if is_node_purchased(node_id):
		return false
	var node: Dictionary = _nodes_by_id.get(node_id, {})
	if node.is_empty():
		return false
	for p in node.get("prerequisites", []):
		if not is_node_purchased(str(p)):
			return false
	return int(node.get("cost_stars", 0)) <= get_available_stars()


## Debug / console: same as [method reset_armory_spending].
func debug_clear_purchases() -> void:
	reset_armory_spending()


## Debug: grants a node without star cost (applies unlock effects).
func debug_grant_node(node_id: String) -> bool:
	if not _nodes_by_id.has(node_id):
		return false
	if is_node_purchased(node_id):
		return true
	ProgressionManager.data.armory_purchased.append(node_id)
	_apply_unlock_effects(_nodes_by_id[node_id])
	ProgressionManager.save_game()
	armory_updated.emit()
	return true


## Filters upgrade IDs using [code]upgrade_gates[/code] and legacy mode.
func filter_upgrade_ids(ids: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for upgrade_id in ids:
		if upgrade_id.is_empty():
			continue
		if _legacy_mode() or _is_upgrade_id_allowed(upgrade_id):
			out.append(upgrade_id)
	return out


## Node dictionary from cache (copy).
func get_armory_node(node_id: String) -> Dictionary:
	var n: Variant = _nodes_by_id.get(node_id, {})
	return n.duplicate() if n is Dictionary else {}


## Stars still available after purchases (recalculated from current JSON costs).
func get_available_stars() -> int:
	return get_total_earned_stars() - get_spent_stars()


## Sorted list of armory node IDs for UI.
func get_node_ids_ordered() -> Array[String]:
	return _ordered_node_ids.duplicate()


## Sum of star costs for purchased nodes (unknown IDs skipped).
func get_spent_stars() -> int:
	var spent: int = 0
	for node_id in ProgressionManager.data.armory_purchased:
		var node: Dictionary = _nodes_by_id.get(node_id, {})
		if not node.is_empty():
			spent += int(node.get("cost_stars", 0))
	return spent


## Total stars earned from completed challenges across all levels.
func get_total_earned_stars() -> int:
	var total: int = 0
	for level_id in ProgressionManager.data.levels.keys():
		var ld: LevelData = ProgressionManager.data.levels[level_id]
		total += ld.challenges_completed.size()
	return total


## Prerequisite node IDs from [code]armory.json[/code] that are not purchased yet.
func get_unmet_prerequisite_node_ids(node_id: String) -> Array[String]:
	var out: Array[String] = []
	var node: Dictionary = _nodes_by_id.get(node_id, {})
	if node.is_empty():
		return out
	for p in node.get("prerequisites", []):
		var pid: String = str(p)
		if not is_node_purchased(pid):
			out.append(pid)
	return out


## True if this node was already bought.
func is_node_purchased(node_id: String) -> bool:
	return node_id in ProgressionManager.data.armory_purchased


## Purchases a node if allowed; applies unlock effects and saves.
func purchase_node(node_id: String) -> bool:
	if not can_purchase(node_id):
		return false
	ProgressionManager.data.armory_purchased.append(node_id)
	_apply_unlock_effects(_nodes_by_id[node_id])
	ProgressionManager.save_game()
	armory_updated.emit()
	return true


## Clears all armory purchases, restores spendable stars, and re-locks non-starter buildings (unless legacy save).
func reset_armory_spending() -> void:
	ProgressionManager.reset_armory_spending()
	armory_updated.emit()


# Private functions
func _aggregate_tower_buffs() -> Dictionary:
	var fire_rate_mult: float = 1.0
	var shoot_range_mult: float = 1.0
	var bullet_damage_mult: float = 1.0
	for node_id in ProgressionManager.data.armory_purchased:
		var node: Dictionary = _nodes_by_id.get(node_id, {})
		if node.is_empty():
			continue
		if str(node.get("category", "")) != "core_buff":
			continue
		for eff in node.get("effects", []):
			if eff.get("type", "") != "tower_buff":
				continue
			if eff.has("fire_rate_mult"):
				fire_rate_mult *= float(eff["fire_rate_mult"])
			if eff.has("shoot_range_mult"):
				shoot_range_mult *= float(eff["shoot_range_mult"])
			if eff.has("bullet_damage_mult"):
				bullet_damage_mult *= float(eff["bullet_damage_mult"])
	return {
		"fire_rate_mult": fire_rate_mult,
		"shoot_range_mult": shoot_range_mult,
		"bullet_damage_mult": bullet_damage_mult
	}


func _apply_unlock_effects(node: Dictionary) -> void:
	for eff in node.get("effects", []):
		match eff.get("type", ""):
			"unlock_tower":
				var tid: String = eff.get("tower_id", "")
				if not tid.is_empty():
					ProgressionManager.unlock_tower_no_save(tid)
			"unlock_trap":
				var trap_key: String = eff.get("trap_id", "")
				if not trap_key.is_empty():
					ProgressionManager.unlock_trap_no_save(trap_key)
			_:
				pass


func _has_any_prereq_cycle() -> bool:
	var state: Dictionary = {}
	for id in _nodes_by_id.keys():
		if state.get(id, 0) != 0:
			continue
		if _prereq_visit(str(id), state):
			return true
	return false


func _is_upgrade_id_allowed(upgrade_id: String) -> bool:
	if upgrade_id.is_empty():
		return false
	if not _upgrade_gates_by_id.has(upgrade_id):
		return true
	var req: String = str(_upgrade_gates_by_id[upgrade_id])
	return is_node_purchased(req)


func _legacy_mode() -> bool:
	return ProgressionManager.data.armory_legacy_mode


func _load_and_validate() -> void:
	_nodes_by_id.clear()
	_ordered_node_ids.clear()
	_upgrade_gates_by_id.clear()

	if not FileAccess.file_exists(ARMORY_JSON_PATH):
		Log.trace(Log.Level.ERROR, "Armory: missing %s" % ARMORY_JSON_PATH)
		return

	var raw: String = FileAccess.get_file_as_string(ARMORY_JSON_PATH)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		Log.trace(Log.Level.ERROR, "Armory: invalid JSON root")
		return

	for g in parsed.get("upgrade_gates", []):
		if typeof(g) != TYPE_DICTIONARY:
			continue
		var upg_id: String = g.get("upgrade_id", "")
		var req: String = g.get("requires_node", "")
		if not upg_id.is_empty() and not req.is_empty():
			_upgrade_gates_by_id[upg_id] = req

	var nodes: Array = parsed.get("nodes", [])
	for item in nodes:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var nid: String = item.get("id", "")
		if nid.is_empty():
			Log.trace(Log.Level.WARN, "Armory: skipped node with empty id")
			continue
		_validate_node_effects(item)
		_nodes_by_id[nid] = item
		_ordered_node_ids.append(nid)

	if _has_any_prereq_cycle():
		Log.trace(Log.Level.ERROR, "Armory: prerequisite cycle detected — graph invalid")

	Log.trace(Log.Level.INFO, "Armory: loaded %d nodes" % _nodes_by_id.size())


func _prereq_visit(node_id: String, state: Dictionary) -> bool:
	var st: int = int(state.get(node_id, 0))
	if st == 1:
		return true
	if st == 2:
		return false
	state[node_id] = 1
	var node: Dictionary = _nodes_by_id.get(node_id, {})
	for p in node.get("prerequisites", []):
		var pid: String = str(p)
		if not _nodes_by_id.has(pid):
			Log.trace(Log.Level.WARN, "Armory: missing prerequisite node '%s' for '%s'" % [pid, node_id])
			continue
		if _prereq_visit(pid, state):
			return true
	state[node_id] = 2
	return false


func _validate_node_effects(node: Dictionary) -> void:
	for eff in node.get("effects", []):
		if typeof(eff) != TYPE_DICTIONARY:
			continue
		match eff.get("type", ""):
			"unlock_tower":
				var tid: String = eff.get("tower_id", "")
				if not tid.is_empty() and not StatsDB.has_tower(tid):
					Log.trace(Log.Level.WARN, "Armory: unknown tower_id in node %s" % node.get("id", ""))
			"unlock_trap":
				var trap_key: String = eff.get("trap_id", "")
				if not trap_key.is_empty() and not StatsDB.has_trap(trap_key):
					Log.trace(Log.Level.WARN, "Armory: unknown trap_id in node %s" % node.get("id", ""))
			"append_tower_upgrade":
				var upgrade_id: String = eff.get("upgrade_id", "")
				if upgrade_id.is_empty() or not StatsDB.has_upgrade(upgrade_id):
					Log.trace(Log.Level.WARN, "Armory: invalid upgrade_id in node %s" % node.get("id", ""))
			"tower_buff":
				pass
			_:
				Log.trace(Log.Level.WARN, "Armory: unknown effect type in node %s" % node.get("id", ""))
