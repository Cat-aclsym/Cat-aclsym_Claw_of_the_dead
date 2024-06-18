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

var groups_count: int = -1:
	get:
		return groups.size()

@onready var timer: Timer = $Timer


# core
func _ready() -> void:
	_load_groups()

	wave_end.connect(Global.hud.in_game_menu.NewWaveCountLabel.start)


func _process(_delta: float) -> void:
	timer.set_paused(Global.paused)


# functionnal
func start_wave() -> void:
	Log.info("{0} start".format([name]))
	if !is_ready: return

	wave_start.emit()
	_start_next_group()


func set_paths(in_paths: Array[Path2D]) -> void:
	paths = in_paths
	is_ready = true


# internal
func _start_next_group() -> void:
	current_group += 1

	if current_group == groups_count:
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

	if groups_count == 0:
		Log.warning("{0} don't have group to spawn".format([name]))


# signals
func _enemy_dies() -> void:
	dead_enemies += 1

	if dead_enemies == enemies_total_count:
		Log.info("{0} end".format([name]))
		wave_end.emit(delay)


func _on_timer_timeout() -> void:
	if !is_ready: return

	current_enemy += 1

	if current_enemy == enemies_to_spawn.size():
		await get_tree().create_timer(groups[current_group].out_delay).timeout
		timer.stop()
		_start_next_group()
		return

	var enemy: IEnemy = ScenesLoader.get_enemy_scene(enemies_to_spawn[current_enemy]).instantiate()
	enemy.die.connect(_enemy_dies)
	EnemySpawner.spawn_enemy(paths[randi() % paths.size()], enemy)
