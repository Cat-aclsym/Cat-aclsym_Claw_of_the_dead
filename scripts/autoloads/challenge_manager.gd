## © [2024] A7 Studio. All rights reserved. Trademark.

extends Node
## Manages active level challenges and coordinates event notifications.
##
## This autoload loads specific challenge logic for the current level and
## relays gameplay events (damage, tower placement) to monitoring challenges.

# Signals
signal challenge_status_updated(challenge_id: String, status: bool)
signal challenges_loaded()

# Public variables
var active_challenges: Array[Challenge] = []
var active_level_id: String = ""


# Public functions
## Initializes challenges for a specific level.
func start_level_challenges(level_id: String) -> void:
	active_level_id = level_id
	active_challenges.clear()

	# Load level config to find challenges
	var level_path := "res://resources/levels/%s.json" % level_id
	if not FileAccess.file_exists(level_path):
		return

	var file := FileAccess.open(level_path, FileAccess.READ)
	assert(file != null, "Failed to open level file: %s" % level_path)

	var content := file.get_as_text()
	var json: Variant = JSON.parse_string(content)

	if not json or not json.has("challenges"):
		return

	for c_id in json["challenges"]:
		_load_challenge(c_id)

	for c in active_challenges:
		c.start_monitoring()

	challenges_loaded.emit()


## Checks and completes all valid challenges at the end of a level.
func check_victory_conditions() -> void:
	for c in active_challenges:
		if c.check_completion():
			c.complete()


## Notifies challenges about damage taken.
func notify_damage(amount: int, _source: Variant = null) -> void:
	for c in active_challenges:
		if c.has_method("on_damage_taken"):
			c.on_damage_taken(amount)


## Notifies challenges about a tower placement.
func notify_tower_placed(tower: ITower) -> void:
	for c in active_challenges:
		if c.has_method("on_tower_placed"):
			c.on_tower_placed(tower)


## Notifies challenges about a trap placement.
func notify_trap_placed(trap: Variant) -> void:
	for c in active_challenges:
		if c.has_method("on_trap_placed"):
			c.on_trap_placed(trap)


## Notifies challenges about an enemy being hit.
func notify_enemy_hit(enemy: IEnemy, source: Variant) -> void:
	for c in active_challenges:
		if c.has_method("on_enemy_hit"):
			c.on_enemy_hit(enemy, source)


## Notifies challenges about an enemy death.
func notify_enemy_died(enemy: IEnemy, damage_type: IEnemy.DamageType) -> void:
	for c in active_challenges:
		if c.has_method("on_enemy_died"):
			c.on_enemy_died(enemy, damage_type)


## Returns currently active challenges.
func get_active_challenges() -> Array[Challenge]:
	return active_challenges


# Private functions
func _load_challenge(c_id: String) -> void:
	var path := "res://resources/challenges/%s.json" % c_id
	if not FileAccess.file_exists(path):
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	var data: Variant = JSON.parse_string(content)

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

	challenge_instance.completed.connect(_on_challenge_completed)
	challenge_instance.failed.connect(_on_challenge_failed)

	active_challenges.append(challenge_instance)


func _on_challenge_completed(c_id: String) -> void:
	challenge_status_updated.emit(c_id, true)


func _on_challenge_failed(c_id: String) -> void:
	challenge_status_updated.emit(c_id, false)
