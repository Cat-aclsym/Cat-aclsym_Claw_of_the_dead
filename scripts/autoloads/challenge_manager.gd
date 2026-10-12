## © [2026] A7 Studio. All rights reserved. Trademark.

extends Node
## Manages active level challenges and coordinates event notifications.
##
## This autoload loads specific challenge logic for the current level and
## relays gameplay events (damage, building placement) to monitoring challenges.

# Signals
signal challenge_status_updated(challenge_id: String, is_completed: bool, is_failed: bool)
signal challenges_loaded()

# Public variables
var active_challenges: Array[Challenge] = []
var active_level_id: String = ""

## Last status sent for each challenge id, bit 0 is completed and bit 1 is failed.
var _last_statuses: Dictionary[String, int] = {}


# Public functions
## Checks and completes all valid challenges at the end of a level.
func check_victory_conditions() -> void:
	for c in active_challenges:
		if c.check_completion():
			c.complete()


## Emits the status of every active challenge, for listeners that need the current state (new HUD, level start).
func emit_runtime_status() -> void:
	for c in active_challenges:
		_last_statuses[c.id] = _status_bits(c)
		challenge_status_updated.emit(c.id, c.is_completed, c.is_failed)


## Returns currently active challenges.
func get_active_challenges() -> Array[Challenge]:
	return active_challenges


## Dispatches placement to [method notify_tower_placed] or [method notify_trap_placed] by [method IBuilding.get_building_kind].
func notify_building_placed(building: IBuilding) -> void:
	match building.get_building_kind():
		IBuilding.BuildingKind.TOWER:
			notify_tower_placed(building as ITower)
		IBuilding.BuildingKind.TRAP:
			notify_trap_placed(building as ITrap)


## Notifies challenges about damage taken.
func notify_damage(amount: int, _source: Variant = null) -> void:
	for c in active_challenges:
		c.on_damage_taken(amount)
	_emit_changed_status()


## Notifies challenges about an enemy death. [param source] is the tower that dealt the killing damage, or the trap that did.
func notify_enemy_died(enemy: IEnemy, damage_type: IEnemy.DamageType, source: Variant = null) -> void:
	for c in active_challenges:
		c.on_enemy_died(enemy, damage_type, source)
	_emit_changed_status()


## Notifies challenges that an enemy reached the end of its path alive. An escape is not a death.
func notify_enemy_escaped(enemy: IEnemy) -> void:
	for c in active_challenges:
		c.on_enemy_escaped(enemy)
	_emit_changed_status()


## Notifies challenges about an enemy being hit.
func notify_enemy_hit(enemy: IEnemy, source: Variant) -> void:
	for c in active_challenges:
		c.on_enemy_hit(enemy, source)
	_emit_changed_status()


## Notifies challenges that an [ITower] was placed (not traps).
func notify_tower_placed(tower: ITower) -> void:
	for c in active_challenges:
		c.on_tower_placed(tower)
	_emit_changed_status()


## Notifies challenges about a trap placement.
func notify_trap_placed(trap: ITrap) -> void:
	for c in active_challenges:
		c.on_trap_placed(trap)
	_emit_changed_status()


## Initializes challenges for a specific level.
func start_level_challenges(level_id: String) -> void:
	active_level_id = level_id
	for c in active_challenges:
		if is_instance_valid(c):
			c.queue_free()
	active_challenges.clear()
	_last_statuses.clear()

	# Load level config to find challenges
	var level_path := "res://resources/levels/%s.json" % level_id
	if not FileAccess.file_exists(level_path):
		return

	var level_data: Dictionary = JsonUtil.load_dict(level_path)
	if not level_data.has("challenges"):
		return

	for c_id: String in level_data["challenges"]:
		_load_challenge(c_id)

	for c in active_challenges:
		c.start_monitoring()

	challenges_loaded.emit()
	emit_runtime_status()


# Private functions
## Emits the status of the challenges whose completed or failed state changed since their last emission.
func _emit_changed_status() -> void:
	for c in active_challenges:
		var bits: int = _status_bits(c)
		if _last_statuses.get(c.id, -1) == bits:
			continue
		_last_statuses[c.id] = bits
		challenge_status_updated.emit(c.id, c.is_completed, c.is_failed)


func _load_challenge(c_id: String) -> void:
	var path := "res://resources/challenges/%s.json" % c_id
	if not FileAccess.file_exists(path):
		Log.trace(Log.Level.WARN, "Challenge file missing for %s: %s" % [c_id, path])
		return

	var data: Dictionary = JsonUtil.load_dict(path)
	if data.is_empty():
		return

	var script_path: String = data.get("script", "res://scripts/challenges/challenge.gd")
	var script: GDScript = load(script_path)
	if not script:
		return

	var challenge_instance: Challenge = script.new(
		data.get("id"),
		data.get("name"),
		data.get("description"),
		data.get("difficulty")
	)
	SignalUtil.connects([
		{SignalUtil.WHO: challenge_instance, SignalUtil.WHAT: "completed", SignalUtil.TO: _on_challenge_state_changed},
		{SignalUtil.WHO: challenge_instance, SignalUtil.WHAT: "failed", SignalUtil.TO: _on_challenge_state_changed},
	])

	add_child(challenge_instance)
	active_challenges.append(challenge_instance)


func _on_challenge_state_changed(_challenge_id: String) -> void:
	_emit_changed_status()


func _status_bits(challenge: Challenge) -> int:
	return int(challenge.is_completed) | (int(challenge.is_failed) << 1)
