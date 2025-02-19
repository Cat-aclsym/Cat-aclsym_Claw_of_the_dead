## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages a wave of enemies in the game.
## Handles spawning of enemy groups with configurable delays and modifiers.
class_name Wave
extends Node

## Emitted when wave starts spawning enemies
signal wave_start

## Emitted when all enemies in wave are defeated
## [param delay] Time to wait before next wave
signal wave_end(delay: float)

## Emitted when all waves are completed
## [param last_wave] True if it is the final wave
signal wave_complete(last_wave: bool)

## Modifiers applied globally to all enemies in this wave
## e.g : {"damage": +15}
## @experimental
@export var global_modifiers: Dictionary = {}

## WinConditionEntity with State Machine
@export var win_condition: WinConditionEntity = null

## Export of wave class
@export var wave: Wave = null

## Delay in seconds before next wave starts
@export_range(0.1, 10.0) var delay: float = 0.1

## ActuelLevel
var level: ILevel = null

## Index of current enemy being spawned
var current_enemy: int = -1

## Index of current group being spawned
var current_group: int = -1

## Count of defeated enemies in this wave
var dead_enemies: int = 0

## List of enemies to spawn in current group
var enemies_to_spawn: Array[IEnemy.EnemyType] = []

## Total number of enemies in this wave
var enemies_total_count: int = 0

## List of enemy groups in this wave
var groups: Array[EnemyGroup] = []

## Whether wave is ready to start
var is_ready: bool = false

## Available paths for enemy movement
var paths: Array[Path2D] = []

## If all the waves are finished
var all_waves_completed: bool = false

## Timer to spawn enemies
@onready var timer: Timer = $Timer

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: timer, SignalUtil.WHAT: "timeout", SignalUtil.TO: _on_timer_timeout},
]

# core
func _ready() -> void:
	_load_groups()
	SignalUtil.connects(signals)
	Log.trace(Log.Level.INFO, "Wave instance added to level")

func _process(_delta: float) -> void:
	timer.set_paused(Global.paused)

# public
## Starts spawning enemies in the wave
func start_wave() -> void:
	Log.trace(Log.Level.INFO, "{0} start".format([name]))
	if not is_ready: return
	current_enemy = -1
	dead_enemies = 0
	enemies_total_count = 0

	for group in groups:
		enemies_total_count += group.enemies.size()

	wave_start.emit()
	_start_next_group()

func set_paths(in_paths: Array[Path2D]) -> void:
	paths = in_paths
	is_ready = true

# private
## Starts spawning the next group of enemies
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

# signals
## Called when timer expires to spawn next enemy
func _on_timer_timeout() -> void:
	if not is_ready:
		return
	current_enemy += 1
	if current_enemy >= enemies_to_spawn.size():
		timer.stop()
		await get_tree().create_timer(groups[current_group].out_delay).timeout
		_start_next_group()
		return

	var enemy: IEnemy = ScenesLoader.get_enemy_scene(enemies_to_spawn[current_enemy]).instantiate()
	EnemySpawner.spawn_enemy(paths.pick_random(), enemy)
	SignalUtil.connects([ {SignalUtil.WHO: enemy, SignalUtil.WHAT: "die", SignalUtil.TO: _on_ienemy_die}])

## Called when an enemy is defeated
func _on_ienemy_die() -> void:
	dead_enemies += 1
	Log.trace(Log.Level.DEBUG, "Total: {0}/{1}".format([dead_enemies, enemies_total_count]))
	if dead_enemies == enemies_total_count:
		Log.trace(Log.Level.INFO, "%s end" % name)
		wave_end.emit(delay)
