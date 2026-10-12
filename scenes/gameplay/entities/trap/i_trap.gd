## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Interface for a trap.
class_name ITrap
extends IBuilding

## Enum for the state of the trap
enum TrapState {
	BUILDING, ## The trap is being built
	ACTIVE, ## The trap is placed and active
}

## Enum for the type of trap behavior
enum TrapType {
	PASSIVE, ## Effect is continuously applied while enemy is on trap
	LIMITED ## Effect is triggered per enemy until durability runs out
}

## Per-enemy effect duration for LIMITED type (seconds)
@export var effect_duration: float = 2.0

## Maximum durability for LIMITED type
@export var max_durability: int = 3

## [StatsDB] key under [code]traps[/code] in [code]stats.json[/code]. Empty keeps scene defaults only.
@export var trap_id: String = ""

## The type of trap behavior
@export var trap_type: TrapType = TrapType.PASSIVE

## Remaining effect duration of each enemy affected by a LIMITED trap
var active_affected_enemies: Dictionary[IEnemy, float] = {}

## Current durability for LIMITED type
var current_durability: int

## List of enemies currently in the trap area
var enemies_in_area: Array[IEnemy] = []

## True while a LIMITED trap plays a charge-up or explosion sequence it ends by itself, the generic cleanup waits for it.
var is_activating: bool = false
## Whether the trap is temporarily disabled by an external effect.
var is_temporarily_disabled: bool = false

## Whether the trap can still trigger (LIMITED type)
var is_usable: bool = true

## The state of the trap
var state: TrapState = TrapState.ACTIVE

var _is_registered_in_placement_system: bool = false

## Longest effect duration left on the enemies that died or escaped while affected (LIMITED type), the trap stays until it is over.
var _linger_remaining: float = 0.0

## Seconds left before a spent LIMITED trap may be freed, started by the last trigger.
var _post_trigger_remaining: float = 0.0

## The area 2D node for the trap to detect enemies
@onready var area_2d: Area2D = $Area2D

## Signal connections to be established in _ready
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "area_entered", SignalUtil.TO: _on_area_2d_area_entered},
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "area_exited", SignalUtil.TO: _on_area_2d_area_exited}
]

func _ready() -> void:
	assert(area_2d != null, "area_2d node not found")
	apply_stats_from_db()
	_update_z_index()
	SignalUtil.connects(signals)
	current_durability = max_durability
	# Only the traps that count something down and the preview that follows the cursor need a frame callback
	set_process(trap_type == TrapType.LIMITED or state == TrapState.BUILDING)
	if state == TrapState.ACTIVE:
		_is_registered_in_placement_system = _register_with_cursor()

func _process(delta: float) -> void:
	if Global.paused:
		return

	if state == TrapState.BUILDING:
		_update_z_index()
		return

	if is_temporarily_disabled or trap_type != TrapType.LIMITED:
		return

	if not is_usable:
		_post_trigger_remaining -= delta

	# For traps with a charge-up or special activation sequence (like Bat07),
	# we don't want the generic cleanup logic to interfere.
	if is_activating:
		return

	var to_remove: Array[IEnemy] = []
	for enemy: IEnemy in active_affected_enemies:
		active_affected_enemies[enemy] -= delta
		if active_affected_enemies[enemy] <= 0:
			if enemy in enemies_in_area and is_usable:
				active_affected_enemies[enemy] = effect_duration
			else:
				remove_effect(enemy)
				to_remove.append(enemy)

	_linger_remaining = maxf(0.0, _linger_remaining - delta)

	for enemy in to_remove:
		active_affected_enemies.erase(enemy)

	if not is_usable and _post_trigger_remaining <= 0.0 and active_affected_enemies.is_empty() and _linger_remaining <= 0.0:
		queue_free()

func _exit_tree() -> void:
	if not _is_registered_in_placement_system:
		return
	var placement_system: BuildPlacement = Global.cursor
	if is_instance_valid(placement_system):
		placement_system.remove_invalid_cell(tile_pos)
	_is_registered_in_placement_system = false

## Override these methods in specific trap implementations.
func apply_effect(_enemy: IEnemy) -> void:
	pass

## Applies the [code]base[/code] keys of the [code]stats.json[/code] [code]traps[/code] entry when [member trap_id] is set, each key writes the property of the same name.
## [br]Uses the [StatsDB] autoload so it works on orphan instances (e.g. build menu preview).
func apply_stats_from_db() -> void:
	if trap_id.is_empty():
		return
	if not StatsDB.has_trap(trap_id):
		Log.trace(Log.Level.WARN, "StatsDB missing trap id: %s" % trap_id)
		return
	StatsDB.apply_fields(self, StatsDB.get_trap(trap_id).get("base", {}))

func cancel_build_preview() -> void:
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

	var disable_tween: Tween = create_tween()
	disable_tween.tween_interval(duration)
	disable_tween.tween_callback(_end_temporary_disable)

func enter_build_preview() -> void:
	state = TrapState.BUILDING
	set_process(true)

func get_building_kind() -> IBuilding.BuildingKind:
	return IBuilding.BuildingKind.TRAP

func get_placement_vertical_offset() -> float:
	return 0.0

## Returns challenge id string for [Challenge] scripts ([code]passive[/code] / [code]limited[/code]).
func get_trap_type() -> String:
	match trap_type:
		TrapType.PASSIVE:
			return "passive"
		TrapType.LIMITED:
			return "limited"
		_:
			return ""

func remove_effect(_enemy: IEnemy) -> void:
	pass

## Private API
func _clear_active_effects() -> void:
	for enemy_item in enemies_in_area:
		if is_instance_valid(enemy_item):
			remove_effect(enemy_item)
	active_affected_enemies.clear()

func _end_temporary_disable() -> void:
	if state != TrapState.ACTIVE:
		return
	is_temporarily_disabled = false
	modulate.a = 1.0
	_refresh_opacity()
	_reapply_effects_to_present_enemies()

## Returns the enemies standing within [param radius] pixels of the trap.
func _enemies_within(radius: float) -> Array[IEnemy]:
	var enemies: Array[IEnemy] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: IEnemy = node as IEnemy
		if enemy != null and global_position.distance_to(enemy.global_position) <= radius:
			enemies.append(enemy)
	return enemies

## Returns the enemy whose feet area is [param area], null for any other area.
## [br]Traps trigger on the zombie "feet" zone only, the head and body overlaps of slopes would trigger them too early.
func _get_enemy_from_area(area: Area2D) -> IEnemy:
	if area.name != "FeetArea":
		return null
	return area.get_parent() as IEnemy

## Seconds a LIMITED trap stays alive after its last trigger, so the effect it started can finish.
## [br]Subclasses with a delayed or long effect override it, the default is [member effect_duration].
func _get_post_trigger_lifetime() -> float:
	return effect_duration

func _handle_trap_activation(enemy: IEnemy) -> void:
	# The level end pauses the gameplay without pausing the tree: a trap re-enabled after it must not trigger
	if is_temporarily_disabled or Global.paused:
		return

	match trap_type:
		TrapType.PASSIVE:
			apply_effect(enemy)
			_notify_challenge_if_boss(enemy)
		TrapType.LIMITED:
			if not enemy in active_affected_enemies:
				if is_usable:
					var on_removed: Callable = _on_enemy_removed.bind(enemy)
					if not enemy.died.is_connected(on_removed):
						SignalUtil.connects([
							{SignalUtil.WHO: enemy, SignalUtil.WHAT: "died", SignalUtil.TO: on_removed},
							{SignalUtil.WHO: enemy, SignalUtil.WHAT: "escaped", SignalUtil.TO: on_removed},
						])

					apply_effect(enemy)
					active_affected_enemies[enemy] = effect_duration
					current_durability -= 1
					_refresh_opacity()
					if current_durability <= 0:
						is_usable = false
					if not is_usable:
						_post_trigger_remaining = _get_post_trigger_lifetime()

func _notify_challenge_if_boss(enemy: IEnemy) -> void:
	if enemy.type != IEnemy.EnemyType.BIG_DADDY:
		return
	ChallengeManager.notify_enemy_hit(enemy, self)

## Signal handlers
func _on_area_2d_area_entered(area: Area2D) -> void:
	if state != TrapState.ACTIVE:
		return

	var enemy: IEnemy = _get_enemy_from_area(area)
	if enemy == null:
		return

	# Enemies that defuse traps (the minesweeper) declare for how long in their stats
	if enemy.trap_disable_duration > 0.0:
		disable_temporarily(enemy.trap_disable_duration)
		return

	if enemy in enemies_in_area:
		return

	enemies_in_area.append(enemy)
	_handle_trap_activation(enemy)

func _on_area_2d_area_exited(area: Area2D) -> void:
	if state != TrapState.ACTIVE:
		return

	var enemy: IEnemy = _get_enemy_from_area(area)
	if enemy == null:
		return

	enemies_in_area.erase(enemy)
	if trap_type == TrapType.PASSIVE:
		remove_effect(enemy)
	elif trap_type == TrapType.LIMITED:
		if enemy in active_affected_enemies:
			remove_effect(enemy)
			active_affected_enemies.erase(enemy)

## An enemy that dies or escapes while a LIMITED effect is on it leaves the effect to run out without it.
func _on_enemy_removed(enemy: IEnemy) -> void:
	if trap_type == TrapType.LIMITED and enemy in active_affected_enemies:
		_linger_remaining = maxf(_linger_remaining, active_affected_enemies[enemy])
		active_affected_enemies.erase(enemy)

func _reapply_effects_to_present_enemies() -> void:
	for enemy_item in enemies_in_area:
		if not is_instance_valid(enemy_item):
			continue
		_handle_trap_activation(enemy_item)

## Fades a LIMITED trap with its durability. A trap that runs its own sequence (see [member is_activating]) keeps the opacity it fades itself.
func _refresh_opacity() -> void:
	if trap_type == TrapType.LIMITED and not is_activating:
		modulate.a = 0.8 * float(current_durability) / float(max_durability) + 0.2

## Adds an isometric circle of [param radius] pixels under the trap, it shows the area of the trap effect.
func _spawn_range_circle(radius: float, color: Color) -> Polygon2D:
	var circle: Polygon2D = Polygon2D.new()
	add_child(circle)
	circle.z_index = -1
	circle.color = color

	var points: PackedVector2Array = []
	var segments: int = 32
	for i: int in range(segments + 1):
		var angle: float = i * PI * 2 / segments
		points.append(Vector2(cos(angle) * radius, sin(angle) * (radius / 2.0)))
	circle.polygon = points
	return circle

func _update_z_index() -> void:
	# Traps lie on the ground, so they sort below the enemies standing at the same height.
	z_index = DepthSort.z_from_y(global_position.y / 2.0) - 10
