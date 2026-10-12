## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Measures the script time of a crowded fight and prints one JSON line (prefix [code]BENCH_RESULT[/code]).
## [br]Enemies with unlimited health walk along the first path and are respawned when they escape, towers or traps fire at them.
## [br]Samples [constant Performance.TIME_PHYSICS_PROCESS] and [constant Performance.TIME_PROCESS] (milliseconds per frame).
## [br]Headless doesn't measure rendering. Arguments after [code]--[/code]: [code]--enemies=300 --towers=40 --scenario=arrows[/code],
## scenarios: arrows, aoe, fire, tesla, inferno, traps.
## [br]Usage: [code]godot --headless --path . --fixed-fps 60 --quit-after 5000 res://tools/bench_combat.tscn -- --scenario=inferno[/code]
extends Node


const ENEMY_ID: String = "default_zombie"
const ENEMY_HEALTH: float = 1.0e9
const LEVEL_ID: String = "lev.02"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const RNG_SEED: int = 4321
const SAMPLE_FRAMES: int = 600
## Towers by scenario: tower id, then the upgrades applied in order.
const SCENARIOS: Dictionary[String, Dictionary] = {
	"aoe": {"id": "bat_02", "upgrades": []},
	"arrows": {"id": "bat_01", "upgrades": []},
	"fire": {"id": "bat_02", "upgrades": ["bat_02_02", "bat_02_03", "bat_02_a_04"]},
	"inferno": {"id": "bat_09", "upgrades": []},
	"tesla": {"id": "bat_08", "upgrades": ["bat_08_02", "bat_08_03", "bat_08_a_04"]},
}
const TRAPS: PackedStringArray = ["bat_03", "bat_04", "bat_05", "bat_06", "bat_07"]
const WARMUP_FRAMES: int = 60

var _enemies: int = 300
var _frame: int = 0
var _level: ILevel = null
var _physics_ms: PackedFloat64Array = []
var _process_ms: PackedFloat64Array = []
var _running: bool = false
var _scenario: String = "arrows"


func _ready() -> void:
	ProgressionManager.persistence_enabled = false
	ProgressionManager.data.parameters.tutorial_completed = true
	for enemy_id: String in StatsDB.get_enemy_ids():
		ProgressionManager.mark_enemy_seen(enemy_id)
	var args: Dictionary[String, String] = ToolBuildings.parse_user_args()
	_enemies = int(args.get("enemies", _enemies))
	_scenario = args.get("scenario", _scenario)
	var buildings: int = int(args.get("towers", 40))
	# The scene tree root is still busy adding this scene during _ready.
	await get_tree().process_frame

	var main: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame

	seed(RNG_SEED)
	_level = await ScenesLoader.start_level(LEVEL_ID)
	# One endless wait instead of the waves, and enough health to survive every escape
	_level.waves = [Wave.new([{"wait_s": 1.0e9}])]
	_level.max_health = 1000000000
	_level.health = _level.max_health
	_place_buildings(_level.map, buildings)
	_running = true


func _process(_delta: float) -> void:
	if not _running:
		return

	_frame += 1
	_refill_enemies()
	if _frame > WARMUP_FRAMES:
		_physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		_process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	if _physics_ms.size() >= SAMPLE_FRAMES:
		_running = false
		var result: Dictionary[String, Variant] = {
			"enemies": _enemies,
			"physics_ms": _summarize(_physics_ms),
			"process_ms": _summarize(_process_ms),
			"scenario": _scenario,
		}
		print("BENCH_RESULT %s" % JSON.stringify(result, "", true, true))
		get_tree().quit()


func _place_buildings(map: IMap, count: int) -> void:
	if _scenario == "traps":
		var path_cells: Array[Vector2i] = ToolBuildings.get_path_cells(map)
		for i: int in count:
			ToolBuildings.place_trap(map, TRAPS[i % TRAPS.size()], path_cells[i % path_cells.size()])
		return

	var scenario: Dictionary = SCENARIOS[_scenario]
	var cells: Array[Vector2i] = ToolBuildings.get_buildable_cells(map)
	for i: int in count:
		ToolBuildings.place_tower(map, scenario["id"], cells[i % cells.size()], PackedStringArray(scenario["upgrades"]))


## Spawns enemies at the start of the first path until [member _enemies] are alive, the first batch is spread along the path.
func _refill_enemies() -> void:
	var path: Path2D = _level.map.paths[0]
	var scene: PackedScene = StatsDB.get_enemy_scene(ENEMY_ID)
	var alive: int = get_tree().get_node_count_in_group("enemies")
	for i: int in maxi(_enemies - alive, 0):
		var enemy: IEnemy = scene.instantiate()
		EnemySpawner.spawn_enemy(path, enemy)
		enemy.max_health = ENEMY_HEALTH
		enemy.health = ENEMY_HEALTH
		if _frame == 1:
			enemy.path_follow.progress = path.curve.get_baked_length() * 0.9 * i / _enemies


func _summarize(samples: PackedFloat64Array) -> Dictionary[String, float]:
	var sorted: PackedFloat64Array = samples.duplicate()
	sorted.sort()
	var mean: float = 0.0
	for sample: float in samples:
		mean += sample
	mean /= samples.size()
	var variance: float = 0.0
	for sample: float in samples:
		variance += (sample - mean) ** 2
	return {
		"mean": mean,
		"median": sorted[sorted.size() / 2],
		"stddev": sqrt(variance / samples.size()),
	}
