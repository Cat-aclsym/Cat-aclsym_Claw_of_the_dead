## © [2026] A7 Studio. All rights reserved. Trademark.
## Loads the main scene, then starts every level scene for a few seconds of accelerated play.
## Exits with 0 when the engine logged no error, otherwise with the error count (capped at 255).
## Usage: godot --headless --path . --quit-after 6000 res://tools/smoke_test.tscn
extends Node


const LEVELS_DIR: String = "res://scenes/gameplay/world/level/levels"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
## Process frames the main scene idles before the levels start.
const MAIN_SCENE_FRAMES: int = 120
## Process frames each level runs (the frame rate is capped, so this is a fixed real duration).
const LEVEL_FRAMES: int = 240
const LEVEL_TIME_SCALE: float = 8.0
const FRAME_RATE: int = 60
## Process frames after which the run aborts, kept below the `--quit-after` of the CI call (which would exit with 0).
const FRAME_BUDGET: int = 5500
const MAX_REPORTED_ERRORS: int = 20
## Logged for every shader under `--headless` (dummy renderer), not a project error.
const HEADLESS_ONLY_ERROR: String = "not supported in Dummy renderer"


## Counts every error the engine logs (push_error, failed loads, script errors, shader errors). Warnings are ignored.
class ErrorCounter extends Logger:
	var count: int = 0
	var messages: PackedStringArray = []
	var _mutex: Mutex = Mutex.new()

	func _log_error(
		function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		_editor_notify: bool,
		error_type: int,
		_script_backtraces: Array[ScriptBacktrace]
	) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING or (code + rationale).contains(HEADLESS_ONLY_ERROR):
			return
		_mutex.lock()
		count += 1
		if messages.size() < MAX_REPORTED_ERRORS:
			messages.append("%s:%d @ %s: %s %s" % [file, line, function, code, rationale])
		_mutex.unlock()


var _counter: ErrorCounter = ErrorCounter.new()
var _finished: bool = false


func _init() -> void:
	OS.add_logger(_counter)


## Watchdog: a script error inside the coroutine below aborts it silently, which would idle until `--quit-after` (exit 0).
func _process(_delta: float) -> void:
	if Engine.get_process_frames() > FRAME_BUDGET:
		push_error("Smoke test: frame budget of %d exceeded." % FRAME_BUDGET)
		_finish(0)


func _ready() -> void:
	ProgressionManager.persistence_enabled = false
	ProgressionManager.data.parameters.tutorial_completed = true
	Engine.max_fps = FRAME_RATE
	# The scene tree root is still busy adding this scene during _ready.
	await get_tree().process_frame

	var main_scene: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
	if main_scene == null:
		push_error("Smoke test: %s failed to load." % MAIN_SCENE_PATH)
		_finish(0)
		return
	var main: Node = main_scene.instantiate()
	get_tree().root.add_child(main)
	if not await _wait_frames(MAIN_SCENE_FRAMES):
		return

	var level_paths: PackedStringArray = _collect_level_paths()
	for path: String in level_paths:
		if not await _run_level(path):
			return

	main.queue_free()
	_finish(level_paths.size())


func _exit_tree() -> void:
	OS.remove_logger(_counter)


func _collect_level_paths() -> PackedStringArray:
	var paths: PackedStringArray = []
	for file: String in DirAccess.get_files_at(LEVELS_DIR):
		if file.begins_with("lev.") and file.get_extension() == "tscn":
			paths.append(LEVELS_DIR.path_join(file))
	paths.sort()
	return paths


## Returns false when the frame budget ran out (the run is already finished in that case).
func _run_level(path: String) -> bool:
	var scene: PackedScene = load(path) as PackedScene
	var level: ILevel = scene.instantiate() as ILevel if scene != null else null
	if level == null:
		push_error("Smoke test: %s is not a loadable ILevel scene." % path)
		return true

	# Same sequence as the level selection menu and the `load_level` console command.
	get_tree().root.add_child(level)
	level.start_level()
	Global.ui.start_level()
	var physics_start: int = Engine.get_physics_frames()
	for i: int in LEVEL_FRAMES:
		# ILevel resets the time scale when the wave flow starts, so it is re-applied every frame.
		Engine.time_scale = LEVEL_TIME_SCALE
		await get_tree().process_frame
		if _finished:
			return false
	print("Smoke test: %s ran %d physics frames, wave %d." % [path.get_file(), Engine.get_physics_frames() - physics_start, level.current_wave + 1])

	Engine.time_scale = 1.0
	Global.ui.end_level()
	for child: Node in Global.ui.get_children():
		if child is EndGame:
			child.queue_free()
	level.queue_free()
	await level.tree_exited
	ILevel.current_level = null
	Global.clear_pauses()
	return await _wait_frames(2)


## Returns false and ends the run when the frame budget is exceeded.
func _wait_frames(frames: int) -> bool:
	for i: int in frames:
		await get_tree().process_frame
		if _finished:
			return false
	return true


func _finish(level_count: int) -> void:
	if _finished:
		return
	_finished = true
	for message: String in _counter.messages:
		printerr("ERROR: %s" % message)
	print("Smoke test: %d levels, %d errors." % [level_count, _counter.count])
	get_tree().quit(mini(_counter.count, 255))
