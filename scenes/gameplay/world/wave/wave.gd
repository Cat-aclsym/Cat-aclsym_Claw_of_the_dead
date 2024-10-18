## © [2024] A7 Studio. All rights reserved. Trademark.
class_name Wave
extends Node

signal wave_start
signal wave_end(delay: float)

## Modifiers applied to all enemies in group [br]
## e.g : [code]{"damage": +15}[/code]
## @experimental
@export var global_modifiers: Dictionary = {}

## Delay in second before next wave
@export_range(0.1, 10.0) var delay: float = 0.1


var current_enemy: int = -1
var current_group: int = -1
var dead_enemies: int = 0
var enemies_to_spawn: Array[ScenesLoader.EnemyID] = []
var enemies_total_count: int = 0
var groups: Array[EnemyGroup] = []
var is_ready: bool = false
var paths: Array[Path2D] = []

@onready var timer: Timer = $Timer


# core
func _ready() -> void:
	_load_groups()


func _process(_delta: float) -> void:
	timer.set_paused(Global.paused)


# public
func start_wave() -> void:
	Log.trace(Log.Level.INFO, "{0} start".format([name]))
	if not is_ready: return

	wave_start.emit()
	_start_next_group()


func set_paths(in_paths: Array[Path2D]) -> void:
	paths = in_paths
	is_ready = true


# private
func _start_next_group() -> void:
	current_group += 1

	if current_group >= groups.size():
		# wait for last enemy to dies
		return

	current_enemy = -1
	enemies_to_spawn = groups[current_group].enemies

	timer.wait_time = groups[current_group].in_delay
	timer.start()


func _load_groups() -> void:
	var children: Array[Node] = get_children()

	for child in children:
		if child is EnemyGroup:
			groups.append(child as EnemyGroup)
			enemies_total_count += child.enemies.size()

	if groups.is_empty():
		Log.trace(Log.Level.WARN, "%s don't have group to spawn" % name)


# signal
func _enemy_dies() -> void:
	dead_enemies += 1

	if dead_enemies == enemies_total_count:
		Log.trace(Log.Level.INFO, "%s end" % name)
		wave_end.emit(delay)


func _on_timer_timeout() -> void:
	if not is_ready: return

	current_enemy += 1

	if current_enemy >= enemies_to_spawn.size():
		timer.stop()
		await get_tree().create_timer(groups[current_group].out_delay).timeout
		_start_next_group()
		return

	var enemy: IEnemy = ScenesLoader.get_enemy_scene(enemies_to_spawn[current_enemy]).instantiate()
	enemy.die.connect(_enemy_dies)
	EnemySpawner.spawn_enemy(paths[randi() % paths.size()], enemy)


# event


# setget
