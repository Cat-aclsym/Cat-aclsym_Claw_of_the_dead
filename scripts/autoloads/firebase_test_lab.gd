## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Handles Firebase Test Lab Game Loop scenarios.
extends Node

const RESULT_DIR  := "/sdcard/Android/data/fr.a7studio.cataclysm/files/GameLoopsResults"
const SCENARIO_TIMEOUT := 30.0

var _scenario: int = 0
var _timer: float = 0.0
var _running: bool = false

func _ready() -> void:
	print("FirebaseTestLab: _ready called, OS=", OS.get_name())
	if not _is_test_lab():
		print("FirebaseTestLab: not a test lab launch, skipping")
		return
	_scenario = _get_scenario()
	print("FirebaseTestLab: running scenario ", _scenario)
	_running = true
	await get_tree().process_frame
	_run_scenario(_scenario)

func _process(delta: float) -> void:
	if not _running:
		return
	_timer += delta
	if _timer >= SCENARIO_TIMEOUT:
		print("FirebaseTestLab: timeout reached")
		_finish_scenario(_scenario, true)

func _is_test_lab() -> bool:
	if OS.get_name() != "Android":
		return false
	var runtime = Engine.get_singleton("AndroidRuntime")
	if not runtime:
		print("FirebaseTestLab: AndroidRuntime not available")
		return false
	var activity = runtime.getActivity()
	if not activity:
		print("FirebaseTestLab: activity is null")
		return false
	var intent = activity.getIntent()
	if not intent:
		print("FirebaseTestLab: intent is null")
		return false
	var action = str(intent.getAction())
	print("FirebaseTestLab: intent action = [", action, "]")
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
	var scenario = intent.getIntExtra("scenario", 1)
	print("FirebaseTestLab: scenario = ", scenario)
	return int(scenario)

func _run_scenario(scenario: int) -> void:
	match scenario:
		1:
			_run_scenario_home()
		2:
			_run_scenario_gameplay()
		_:
			print("FirebaseTestLab: unknown scenario ", scenario)
			_finish_scenario(scenario, false)

func _run_scenario_home() -> void:
	print("FirebaseTestLab: scenario 1 start")
	await get_tree().create_timer(5.0).timeout
	print("FirebaseTestLab: scenario 1 done")
	_finish_scenario(1, true)

func _run_scenario_gameplay() -> void:
	print("FirebaseTestLab: scenario 2 start")
	get_tree().change_scene_to_file("res://scenes/gameplay/world/level/levels/lev.01.tscn")
	await get_tree().create_timer(20.0).timeout
	print("FirebaseTestLab: scenario 2 done")
	_finish_scenario(2, true)

func _finish_scenario(scenario: int, success: bool) -> void:
	_running = false
	_write_results(scenario, success)
	get_tree().quit()

func _write_results(scenario: int, success: bool) -> void:
	var json_str := JSON.stringify({
		"scenario": scenario,
		"status": "success" if success else "failure",
	})
	DirAccess.make_dir_recursive_absolute(RESULT_DIR)
	var path := RESULT_DIR + "/results" + str(scenario) + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		print("FirebaseTestLab: results written to ", path)
	else:
		print("FirebaseTestLab: failed to write results, error=", FileAccess.get_open_error())