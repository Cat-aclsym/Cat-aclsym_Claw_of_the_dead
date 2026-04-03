## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Interface for a trap.
class_name ITrap
extends Node2D

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

## The cost of the trap
@export var cost: int

## The type of trap behavior
@export var trap_type: TrapType = TrapType.PASSIVE

## Per-enemy effect duration for LIMITED type (seconds)
@export var effect_duration: float = 2.0

## Maximum durability for LIMITED type
@export var max_durability: int = 3

## The state of the trap
var state: TrapState = TrapState.ACTIVE

## Current durability for LIMITED type
var current_durability: int

## Whether the trap can still trigger (LIMITED type)
var is_usable: bool = true

## List of enemies currently in the trap area
var enemies_in_area: Array[IEnemy] = []

## Dictionary to track enemies affected by LIMITED type with their remaining effect duration
var active_affected_enemies: Dictionary

## Dictionary to track remaining effect duration for dead enemies (LIMITED type)
var remaining_effects: Array[float] = []

## The area 2D node for the trap to detect enemies
@onready var area_2d: Area2D = $Area2D

## Signal connections to be established in _ready
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_area_2d_body_entered},
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "body_exited", SignalUtil.TO: _on_area_2d_body_exited},
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "area_entered", SignalUtil.TO: _on_area_2d_body_entered},
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "area_exited", SignalUtil.TO: _on_area_2d_body_exited}
]

# core
func _ready():
	_update_z_index()
	SignalUtil.connects(signals)
	current_durability = max_durability
	active_affected_enemies = {}

func _process(delta: float) -> void:
	if Global.paused:
		return

	if state == TrapState.BUILDING:
		_update_z_index()
		return

	if trap_type == TrapType.LIMITED:
		var opacity := (0.8 * (float(current_durability) / float(max_durability))) + 0.2
		modulate.a = opacity

		var to_remove := []
		for enemy in active_affected_enemies:
			active_affected_enemies[enemy] -= delta
			if active_affected_enemies[enemy] <= 0:
				if enemy in enemies_in_area and is_usable:
					active_affected_enemies[enemy] = effect_duration
				else:
					remove_effect(enemy)
					to_remove.append(enemy)

		var remaining_to_remove := []
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

## Returns challenge id string for [Challenge] scripts ([code]passive[/code] / [code]limited[/code]).
func get_trap_type() -> String:
	match trap_type:
		TrapType.PASSIVE:
			return "passive"
		TrapType.LIMITED:
			return "limited"
		_:
			return ""

# private
func _handle_trap_activation(enemy: IEnemy) -> void:
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

func _on_enemy_die(enemy: IEnemy) -> void:
	if trap_type == TrapType.LIMITED and enemy in active_affected_enemies:
		remaining_effects.append(active_affected_enemies[enemy])
		active_affected_enemies.erase(enemy)

func _update_z_index() -> void:
	var y_position := int(global_position.y)
	z_index = (y_position / 2) - 10

func _get_enemy_from_overlap(overlap) -> IEnemy:
	# We want traps to trigger based on the zombie "feet" zone only.
	# This avoids head/body overlaps triggering the effect on slopes.
	if overlap is IEnemy:
		return null

	if overlap is Area2D and overlap.name == "FeetArea":
		var parent: Node = overlap.get_parent()
		if parent is IEnemy:
			return parent as IEnemy

	return null

# signal
func _on_area_2d_body_entered(body) -> void:
	if state != TrapState.ACTIVE:
		return

	var enemy := _get_enemy_from_overlap(body)
	if enemy == null:
		return

	if enemy in enemies_in_area:
		return

	enemies_in_area.append(enemy)
	_handle_trap_activation(enemy)

func _on_area_2d_body_exited(body) -> void:
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

## Override these methods in specific trap implementations
func apply_effect(_enemy: IEnemy) -> void:
	pass

func remove_effect(_enemy: IEnemy) -> void:
	pass
