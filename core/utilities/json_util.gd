## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Static helpers to read JSON files with consistent error logging.
class_name JsonUtil
extends RefCounted


## Returns the Dictionary stored at the root of the JSON file at [param path].
## [br]Returns an empty Dictionary and logs an ERROR when the file is missing, cannot be opened, is not valid JSON or its root is not an object.
static func load_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		Log.trace(Log.Level.ERROR, "JsonUtil: missing file %s" % path)
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		Log.trace(Log.Level.ERROR, "JsonUtil: cannot open %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return {}

	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		Log.trace(Log.Level.ERROR, "JsonUtil: invalid JSON in %s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}

	if not json.data is Dictionary:
		Log.trace(Log.Level.ERROR, "JsonUtil: root of %s is not an object" % path)
		return {}

	return json.data
