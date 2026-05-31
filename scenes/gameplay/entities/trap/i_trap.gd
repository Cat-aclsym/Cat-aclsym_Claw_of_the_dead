## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Interface for a trap.
class_name ITrap
extends IBuilding

## Enum for the type of trap behavior
enum TrapType {
	PASSIVE, ## Effect is continuously applied while enemy is on trap
	LIMITED ## Effect is triggered per enemy until durability runs out
}

## Enum for the state of the trap
enum TrapState {
	BUILDING, ## The trap is being built
	ACTIVE, ## The trap is placed and active
}

const MINESWEEPER_DISABLE_DURATION_SECONDS: float = 5.0

## The type of trap behavior
@export var trap_type: TrapType = TrapType.PASSIVE

## Per-enemy effect duration for LIMITED type (seconds)
@export var effect_duration: float = 2.0

## Maximum durability for LIMITED type
@export var max_durability: int = 3

## [StatsDB] key under [code]traps[/code] in [code]stats.json[/code]. Empty keeps scene defaults only.
@export var trap_id: String = ""

## The state of the trap
var state: TrapState = TrapState.ACTIVE

## Current durability for LIMITED type
var current_durability: int

## Whether the trap can still trigger (LIMITED type)
var is_usable: bool = true
## Whether the trap is temporarily disabled by an external effect.
var is_temporarily_disabled: bool = false

## List of enemies currently in the trap area
var enemies_in_area: Array[IEnemy] = []

## Dictionary to track enemies affected by LIMITED type with their remaining effect duration
var active_affected_enemies: Dictionary

## Dictionary to track remaining effect duration for dead enemies (LIMITED type)
var remaining_effects: Array[float] = []

## Tile position used by the placement system occupancy checks.
var tile_pos: Vector2i = Vector2i.ZERO

var _is_registered_in_placement_system: bool = false

## The area 2D node for the trap to detect enemies
@onready var area_2d: Area2D = $Area2D

## Signal connections to be established in _ready
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_area_2d_body_entered},
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "body_exited", SignalUtil.TO: _on_area_2d_body_exited},
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "area_entered", SignalUtil.TO: _on_area_2d_body_entered},
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "area_exited", SignalUtil.TO: _on_area_2d_body_exited}
]

func _ready() -> void:
	assert(area_2d != null, "area_2d node not found")
	apply_stats_from_db()
	_update_z_index()
	SignalUtil.connects(signals)
	current_durability = max_durability
	active_affected_enemies = {}
	if state == TrapState.ACTIVE:
		_register_with_cursor()

func _exit_tree() -> void:
	if not _is_registered_in_placement_system:
		return
	var placement_system: BuildPlacement = Global.get("cursor") as BuildPlacement
	if placement_system:
		placement_system.remove_invalid_cell(tile_pos)
	_is_registered_in_placement_system = false

func _process(delta: float) -> void:
	if Global.paused:
		return

	if state == TrapState.BUILDING:
		_update_z_index()
		return

	if is_temporarily_disabled:
		return

	if trap_type == TrapType.LIMITED:
		# For traps with a charge-up or special activation sequence (like Bat07),
		# we don't want the generic opacity/cleanup logic to interfere.
		if "is_activating" in self and self.is_activating:
			return

		var opacity := (0.8 * (float(current_durability) / float(max_durability))) + 0.2
		modulate.a = opacity

		var to_remove: Array[IEnemy] = []
		for enemy: IEnemy in active_affected_enemies:
			active_affected_enemies[enemy] -= delta
			if active_affected_enemies[enemy] <= 0:
				if enemy in enemies_in_area and is_usable:
					active_affected_enemies[enemy] = effect_duration
				else:
					remove_effect(enemy)
					to_remove.append(enemy)

		var remaining_to_remove: Array[int] = []
		for i in range(remaining_effects.size()):
			remaining_effects[i] -= delta
			if remaining_effects[i] <= 0:
				remaining_to_remove.append(i)

		for i in range(remaining_to_remove.size() - 1, -1, -1):
			remaining_effects.remove_at(remaining_to_remove[i])

		for enemy in to_remove:
			active_affected_enemies.erase(enemy)

		if not is_usable and active_affected_enemies.is_empty() and remaining_effects.is_empty():
			queue_free()

func cancel_build_preview() -> void:
	pass

func enter_build_preview() -> void:
	state = TrapState.BUILDING

func get_building_kind() -> IBuilding.BuildingKind:
	return IBuilding.BuildingKind.TRAP

func get_placement_vertical_offset() -> float:
	return 0.0

## Applies [code]stats.json[/code] [code]traps[/code] entry when [member trap_id] is set. Uses the [StatsDB] autoload so it works on orphan instances (e.g. build menu preview).
func apply_stats_from_db() -> void:
	if trap_id.is_empty():
		return
	if not StatsDB.has_trap(trap_id):
		Log.trace(Log.Level.WARN, "StatsDB missing trap id: %s" % trap_id)
		return
	var data: Dictionary = StatsDB.get_trap(trap_id)
	var base: Dictionary = data.get("base", {})
	Log.trace(Log.Level.INFO, "Applying trap stats from StatsDB for %s: %s" % [trap_id, base])
	if base.has("cost"):
		cost = int(base["cost"])
	if base.has("trap_type"):
		trap_type = int(base["trap_type"]) as TrapType
	if base.has("effect_duration"):
		effect_duration = float(base["effect_duration"])
	if base.has("max_durability"):
		max_durability = int(base["max_durability"])
	_apply_trap_stats_extension(base)

## Returns challenge id string for [Challenge] scripts ([code]passive[/code] / [code]limited[/code]).
func get_trap_type() -> String:
	match trap_type:
		TrapType.PASSIVE:
			return "passive"
		TrapType.LIMITED:
			return "limited"
		_:
			return ""

## Override these methods in specific trap implementations.
func apply_effect(_enemy: IEnemy) -> void:
	pass

func remove_effect(_enemy: IEnemy) -> void:
	pass

## Temporarily disables the trap interactions for [param duration] seconds.
func disable_temporarily(duration: float) -> void:
	if duration <= 0.0:
		return
	if state != TrapState.ACTIVE:
		return

	is_temporarily_disabled = true
	modulate.a = 0.35
	_clear_active_effects()

	var timer: SceneTreeTimer = get_tree().create_timer(duration)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		if state != TrapState.ACTIVE:
			return
		is_temporarily_disabled = false
		modulate.a = 1.0
		_reapply_effects_to_present_enemies()
	)

## Private API
## Subclasses read extra [code]base[/code] keys (e.g. [code]damage[/code], [code]slow_amount[/code]).
func _apply_trap_stats_extension(_base: Dictionary) -> void:
	pass

func _handle_trap_activation(enemy: IEnemy) -> void:
	if is_temporarily_disabled:
		return

	match trap_type:
		TrapType.PASSIVE:
			apply_effect(enemy)
			_notify_challenge_if_boss(enemy)
		TrapType.LIMITED:
			if not enemy in active_affected_enemies:
				if is_usable:
					enemy.die.connect(_on_enemy_die.bind(enemy))

					apply_effect(enemy)
					active_affected_enemies[enemy] = effect_duration
					current_durability -= 1
					if current_durability <= 0:
						is_usable = false

func _notify_challenge_if_boss(enemy: IEnemy) -> void:
	if enemy.type != IEnemy.EnemyType.BIG_DADDY:
		return
	ChallengeManager.notify_enemy_hit(enemy, self)

func _clear_active_effects() -> void:
	for enemy_item in enemies_in_area:
		if is_instance_valid(enemy_item):
			remove_effect(enemy_item)
	active_affected_enemies.clear()

func _reapply_effects_to_present_enemies() -> void:
	for enemy_item in enemies_in_area:
		if not is_instance_valid(enemy_item):
			continue
		_handle_trap_activation(enemy_item)

func _on_enemy_die(enemy: IEnemy) -> void:
	if trap_type == TrapType.LIMITED and enemy in active_affected_enemies:
		remaining_effects.append(active_affected_enemies[enemy])
		active_affected_enemies.erase(enemy)

func _update_z_index() -> void:
	var y_position := int(global_position.y)
	z_index = int(y_position / 2.0) - 10

func _register_with_cursor() -> void:
	if not is_inside_tree():
		return
	var placement_system: BuildPlacement = Global.get("cursor") as BuildPlacement
	if not placement_system:
		return
	if tile_pos == Vector2i.ZERO and placement_system.tm_ref:
		tile_pos = placement_system.tm_ref.local_to_map(placement_system.tm_ref.to_local(global_position))
	placement_system.add_invalid_cell(tile_pos)
	_is_registered_in_placement_system = true

func _get_enemy_from_overlap(overlap: Node2D) -> IEnemy:
	# We want traps to trigger based on the zombie "feet" zone only.
	# This avoids head/body overlaps triggering the effect on slopes.
	if overlap is IEnemy:
		return null

	if overlap is Area2D and overlap.name == "FeetArea":
		var parent: Node = overlap.get_parent()
		if parent is IEnemy:
			return parent as IEnemy

	return null

## Signal handlers
func _on_area_2d_body_entered(body: Node2D) -> void:
	if state != TrapState.ACTIVE:
		return

	var enemy := _get_enemy_from_overlap(body)
	if enemy == null:
		return

	if enemy.enemy_id == "minesweeper":
		disable_temporarily(MINESWEEPER_DISABLE_DURATION_SECONDS)
		return

	if enemy in enemies_in_area:
		return

	enemies_in_area.append(enemy)
	_handle_trap_activation(enemy)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if state != TrapState.ACTIVE:
		return

	var enemy := _get_enemy_from_overlap(body)
	if enemy == null:
		return

	enemies_in_area.erase(enemy)
	if trap_type == TrapType.PASSIVE:
		remove_effect(enemy)
	elif trap_type == TrapType.LIMITED:
		if enemy in active_affected_enemies:
			remove_effect(enemy)
			active_affected_enemies.erase(enemy)
