class_name Wave extends Node
signal wave_start
signal wave_end(delay: float)

## Modifiers applied to all enemies in group [br]
## e.g : [code]{"damage": +15}[/code]
## @experimental
@export var global_modifiers: Dictionary = {}

## Delay in second before next wave
@export_range(0.1, 10.0) var delay: float = 0.1

var is_ready: bool = false

var paths: Array[Path2D] = []

var groups_count: int = -1
var current_group: int = -1
var groups: Array[EnemyGroup] = []

var current_enemy: int = -1
var enemies_to_spawn: Array[ScenesLoader.EnemyID]

var enemies_total_count: int = 0
var dead_enemies: int = 0

@onready var timer: Timer = $Timer


# core
func _ready() -> void:
	_load_groups()


# functionnal
func start_wave() -> void:
	Log.debug("{0} wave start".format([name]))
	if (!is_ready):
		return
	
	wave_start.emit()
	_start_next_group()
	

func set_paths(in_paths: Array[Path2D]) -> void:
	paths = in_paths
	is_ready = true


# internal
func _start_next_group() -> void:
	current_group += 1
	Log.debug("{0} group {1} start".format([name, current_group]))
	
	if (current_group == groups_count):
		# wait for last enemy to dies
		return
	
	current_enemy = -1
	enemies_to_spawn = groups[current_group].enemies
	
	timer.wait_time = groups[current_group].in_delay
	timer.start()
	

func _load_groups() -> void:
	var children: Array = get_children()
	
	for child in children:
		if (child is EnemyGroup):
			groups.append(child as EnemyGroup)
			enemies_total_count += child.enemies.size()
	
	groups_count = groups.size()
	Log.info("{0} has {1} enemies to spawn".format([name, enemies_total_count]))
	
	if (groups_count == 0):
		Log.warning("{0} don't have group to spawn".format([name]))


# signals
func _enemy_dies() -> void:
	dead_enemies += 1
	
	if (dead_enemies == enemies_total_count):
		Log.info("{0} end".format([name]))
		wave_end.emit(delay)
		

func _on_timer_timeout() -> void:
	if (!is_ready):
		return
		
	current_enemy += 1
	
	if (current_enemy == enemies_to_spawn.size()):
		# TODO : wait group.out_delay seconds before start next group
		timer.stop()
		_start_next_group()
		return
	
	var enemy: IEnemy = ScenesLoader.get_enemy_scene(enemies_to_spawn[current_enemy]).instantiate()
	enemy.connect("die", _enemy_dies)
	IEnemySpawner.spawn_enemy(paths[randi() % paths.size()], enemy)
