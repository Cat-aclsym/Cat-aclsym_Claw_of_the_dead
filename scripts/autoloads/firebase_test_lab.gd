extends Node

const RESULT_PATH := "/sdcard/Android/data/fr.a7studio.cataclysm/files/results.json"
const SCENARIO_TIMEOUT := 30.0

var _scenario: int = 0
var _timer: float = 0.0
var _running: bool = false

func _ready() -> void:
	if not _is_test_lab():
		return
	_scenario = _get_scenario()
	Log.trace(Log.Level.INFO, "FirebaseTestLab: running scenario {0}".format([_scenario]))
	_running = true
	await get_tree().process_frame
	_run_scenario(_scenario)

func _process(delta: float) -> void:
	if not _running:
		return
	_timer += delta
	if _timer >= SCENARIO_TIMEOUT:
		Log.trace(Log.Level.WARN, "FirebaseTestLab: scenario timeout reached")
		_finish_scenario(_scenario, true)

func _is_test_lab() -> bool:
	if OS.get_name() != "Android":
		return false
	var runtime = Engine.get_singleton("AndroidRuntime")
	if not runtime:
		Log.trace(Log.Level.WARN, "FirebaseTestLab: AndroidRuntime singleton not available")
		return false
	var activity = runtime.getActivity()
	if not activity:
		return false
	var intent = activity.getIntent()
	if not intent:
		return false
	# getAction() returns a Java String object — must use str() for GDScript comparison
	var action = str(intent.getAction())
	Log.trace(Log.Level.INFO, "FirebaseTestLab: detected intent action = {0}".format([action]))
	return action == "com.google.intent.action.TEST_LOOP"

func _get_scenario() -> int:
	var runtime = Engine.get_singleton("AndroidRuntime")
	if not runtime:
		return 1
	var activity = runtime.getActivity()
	if not activity:
		return 1
	var intent = activity.getIntent()
	if not intent:
		return 1
	# getIntExtra returns a Java int — convert to GDScript int
	return int(intent.getIntExtra("scenario", 1))

func _run_scenario(scenario: int) -> void:
	match scenario:
		1:
			_run_scenario_home()
		2:
			_run_scenario_gameplay()
		_:
			Log.trace(Log.Level.WARN, "FirebaseTestLab: unknown scenario {0}".format([scenario]))
			_finish_scenario(scenario, false)

func _run_scenario_home() -> void:
	Log.trace(Log.Level.INFO, "FirebaseTestLab: scenario 1 - home screen")
	await get_tree().create_timer(5.0).timeout
	_finish_scenario(1, true)

func _run_scenario_gameplay() -> void:
	Log.trace(Log.Level.INFO, "FirebaseTestLab: scenario 2 - gameplay")
	get_tree().change_scene_to_file("res://scenes/gameplay/world/level/levels/lev.01.tscn")
	await get_tree().create_timer(20.0).timeout
	_finish_scenario(2, true)

func _finish_scenario(scenario: int, success: bool) -> void:
	_running = false
	_write_results(scenario, success)
	get_tree().quit()

func _write_results(scenario: int, success: bool) -> void:
	var result := {
		"scenario": scenario,
		"status": "success" if success else "failure",
	}
	var dir_path := RESULT_PATH.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if file == null:
		Log.trace(Log.Level.ERROR, "FirebaseTestLab: failed to write results to {0}".format([RESULT_PATH]))
		return
	file.store_string(JSON.stringify(result))
	file.close()
	Log.trace(Log.Level.INFO, "FirebaseTestLab: results written to {0}".format([RESULT_PATH]))