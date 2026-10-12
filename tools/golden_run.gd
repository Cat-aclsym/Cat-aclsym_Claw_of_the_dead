## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Plays one level with a fixed set of buildings and prints one JSON digest line (prefix [code]GOLDEN_DIGEST[/code]).
## [br]The run is seeded and uses a fixed frame rate, so two runs of the same code print the same digest. A refactor keeps it unchanged.
## [br]Arguments after [code]--[/code]: [code]--level=lev.02[/code] (a level without tutorial, lev.02 to lev.08) and [code]--frames=6000[/code].
## [br]Usage: [code]godot --headless --path . --fixed-fps 60 --quit-after 7200 res://tools/golden_run.tscn -- --level=lev.02[/code]
extends Node


## Frames after which the digest is printed even if the level did not end.
const DEFAULT_FRAMES: int = 6000
const DEFAULT_LEVEL_ID: String = "lev.02"
## Frames the run goes on once the level ended, to catch what still happens after the end screen.
const END_GRACE_FRAMES: int = 20
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const RNG_SEED: int = 1234
## Tower id, then the upgrades applied in order. Covers every projectile (arrow, aoe, fire, pierce, lightning, beam).
const TOWERS: Array[Dictionary] = [
	{"id": "bat_01", "upgrades": []},
	{"id": "bat_01", "upgrades": ["bat_01_02", "bat_01_03", "bat_01_a_04"]},
	{"id": "bat_02", "upgrades": []},
	{"id": "bat_02", "upgrades": ["bat_02_02", "bat_02_03", "bat_02_a_04"]},
	{"id": "bat_08", "upgrades": ["bat_08_02", "bat_08_03", "bat_08_a_04"]},
	{"id": "bat_08", "upgrades": ["bat_08_02", "bat_08_03", "bat_08_b_04"]},
	{"id": "bat_09", "upgrades": []},
	{"id": "bat_09", "upgrades": ["bat_09_02", "bat_09_03", "bat_09_b_04"]},
	{"id": "bat_09", "upgrades": ["bat_09_02", "bat_09_03", "bat_09_a_04"]},
]
const TRAPS: PackedStringArray = ["bat_03", "bat_04", "bat_05", "bat_06", "bat_07"]
## Frames between two samples of the enemy positions that feed the trace hash.
const TRACE_INTERVAL_FRAMES: int = 30

var _end_frames: int = 0
var _escapes: Dictionary[String, int] = {}
var _frame: int = 0
var _kills: Dictionary[String, int] = {}
var _level: ILevel = null
var _max_frames: int = DEFAULT_FRAMES
var _running: bool = false
var _spawned: Dictionary[String, int] = {}
var _trace_hash: int = 0


func _ready() -> void:
	# The end of a level pauses the tree for its dialogues, the run goes on to print the digest
	process_mode = Node.PROCESS_MODE_ALWAYS
	ProgressionManager.persistence_enabled = false
	ProgressionManager.data.parameters.tutorial_completed = true
	for enemy_id: String in StatsDB.get_enemy_ids():
		ProgressionManager.mark_enemy_seen(enemy_id)
	var args: Dictionary[String, String] = ToolBuildings.parse_user_args()
	_max_frames = int(args.get("frames", DEFAULT_FRAMES))
	# The scene tree root is still busy adding this scene during _ready.
	await get_tree().process_frame

	# The main scene becomes the current scene, so that a scene change at the end of the level doesn't free this node
	var main: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await get_tree().process_frame
	SignalUtil.connects([{SignalUtil.WHO: get_tree(), SignalUtil.WHAT: "node_added", SignalUtil.TO: _on_node_added}])

	seed(RNG_SEED)
	Engine.time_scale = 1.0
	_level = await ScenesLoader.start_level(args.get("level", DEFAULT_LEVEL_ID))
	if _level == null:
		printerr("golden_run: the level failed to load.")
		get_tree().quit(1)
		return
	_place_buildings(_level.map)
	_running = true


func _process(_delta: float) -> void:
	if not _running:
		return

	_frame += 1
	if _frame % TRACE_INTERVAL_FRAMES == 0:
		_record_trace()
	if Global.paused:
		_end_frames += 1
	if _frame >= _max_frames or _end_frames >= END_GRACE_FRAMES:
		_running = false
		print("GOLDEN_DIGEST %s" % JSON.stringify(_build_digest(), "", true, true))
		get_tree().quit()


func _build_digest() -> Dictionary[String, Variant]:
	var challenges: Dictionary[String, String] = {}
	for challenge: Challenge in ChallengeManager.active_challenges:
		challenges[challenge.id] = "completed" if challenge.is_completed else ("failed" if challenge.is_failed else "pending")
	return {
		"challenges": challenges,
		"coins": _level.coins,
		"elapsed_time": _level.elapsed_time,
		"enemies_alive": _level.get_enemies_alive(),
		"enemies_in_tree": get_tree().get_node_count_in_group("enemies"),
		"ended": Global.paused,
		"escapes": _escapes,
		"frames": _frame,
		"health": _level.health,
		"kills": _kills,
		"level": _level.level_id,
		"spawned": _spawned,
		"trace_hash": _trace_hash,
		"traps_left": _level.map.get_children().filter(func(node: Node) -> bool: return node is ITrap and not node.is_queued_for_deletion()).size(),
		"wave": _level.current_wave,
	}


func _count(counter: Dictionary[String, int], enemy: IEnemy) -> void:
	counter[enemy.enemy_id] = counter.get(enemy.enemy_id, 0) + 1


func _on_node_added(node: Node) -> void:
	var enemy: IEnemy = node as IEnemy
	if enemy == null:
		return
	_count(_spawned, enemy)
	SignalUtil.connects([
		{SignalUtil.WHO: enemy, SignalUtil.WHAT: "died", SignalUtil.TO: _count.bind(_kills, enemy)},
		{SignalUtil.WHO: enemy, SignalUtil.WHAT: "escaped", SignalUtil.TO: _count.bind(_escapes, enemy)},
	])


## Towers on the cells nearest to the path, traps spread over the path cells.
func _place_buildings(map: IMap) -> void:
	var buildable_cells: Array[Vector2i] = ToolBuildings.get_buildable_cells(map)
	var tower_cells: Array[Vector2i] = []
	for cell: Vector2i in buildable_cells:
		# One free cell between two towers so that they do not hide each other
		if tower_cells.all(func(other: Vector2i) -> bool: return cell.distance_to(other) >= 2.0):
			tower_cells.append(cell)
		if tower_cells.size() == TOWERS.size():
			break
	for i: int in tower_cells.size():
		ToolBuildings.place_tower(map, TOWERS[i]["id"], tower_cells[i], PackedStringArray(TOWERS[i]["upgrades"]))

	var path_cells: Array[Vector2i] = ToolBuildings.get_path_cells(map)
	for i: int in TRAPS.size():
		if path_cells.is_empty():
			break
		ToolBuildings.place_trap(map, TRAPS[i], path_cells[(2 * i + 1) * path_cells.size() / (2 * TRAPS.size())])
	print("golden_run: %d buildable cells, %d towers, %d path cells." % [buildable_cells.size(), tower_cells.size(), path_cells.size()])


## Folds the state of every enemy into the trace hash, a drift of one frame changes it.
func _record_trace() -> void:
	var parts: PackedStringArray = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: IEnemy = node as IEnemy
		parts.append("%s:%.2f:%.2f" % [enemy.enemy_id, enemy.health, enemy.path_follow.progress])
	_trace_hash = ("%d|%s" % [_trace_hash, ",".join(parts)]).hash()
