## © [2026] A7 Studio. All rights reserved. Trademark.
## Compiles every project script outside addons/ and exits with the failure count.
## Usage: godot --headless --path . res://tools/check_scripts.tscn
extends Node


const EXCLUDED_DIRS: PackedStringArray = ["res://addons", "res://.godot", "res://android", "res://exports"]


func _ready() -> void:
	var failures: PackedStringArray = []
	var paths: PackedStringArray = _collect("res://")
	for path: String in paths:
		var script: GDScript = load(path) as GDScript
		if script == null or (not script.can_instantiate() and not script.is_abstract()):
			failures.append(path)
	for path: String in failures:
		printerr("FAILED: %s" % path)
	print("Checked %d scripts, %d failed." % [paths.size(), failures.size()])
	get_tree().quit(failures.size())


func _collect(dir_path: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for sub: String in DirAccess.get_directories_at(dir_path):
		var sub_path: String = dir_path.path_join(sub)
		if sub_path not in EXCLUDED_DIRS:
			result.append_array(_collect(sub_path))
	for file: String in DirAccess.get_files_at(dir_path):
		if file.get_extension() == "gd":
			result.append(dir_path.path_join(file))
	return result
