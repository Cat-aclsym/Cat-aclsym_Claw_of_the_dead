## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The characters and portraits the Dialogic timelines of [code]res://assets/narrative[/code] refer to.
## [br]A character is found through [code]dialogic/directories/dch_directory[/code] of [code]project.godot[/code]: a first import of a fresh checkout
## empties it, the Dialogic text event then builds a bare character and the portraits are lost.
extends GdUnitTestSuite

const NARRATIVE_DIR: String = "res://assets/narrative"
## Matches [code]join character1 (Amazed) center[/code] and [code]character1 (Neutral): Hello[/code].
const PORTRAIT_USE_PATTERN: String = "^(?:join\\s+)?(\\S+)\\s+\\((\\w+)\\)"


func test_every_character_file_is_registered_in_the_dialogic_directory() -> void:
	var paths: Array[String] = _paths_with_extension("dch")
	var problems: Array[String] = []
	for path: String in paths:
		if not DialogicResourceUtil.get_character_directory().values().has(path):
			problems.append("%s is missing from dialogic/directories/dch_directory" % path)

	assert_array(paths).is_not_empty()
	assert_array(problems).is_empty()


func test_every_portrait_of_a_timeline_resolves_to_an_existing_image() -> void:
	var regex: RegEx = RegEx.create_from_string(PORTRAIT_USE_PATTERN)
	var problems: Array[String] = []
	var uses: int = 0
	for path: String in _paths_with_extension("dtl"):
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var found: RegExMatch = regex.search(line)
			if found == null:
				continue
			uses += 1
			problems.append_array(_portrait_problems(path.get_file(), found.get_string(1), found.get_string(2)))

	assert_int(uses).is_greater(0)
	assert_array(problems).is_empty()


func test_the_default_portrait_of_every_character_exists() -> void:
	var problems: Array[String] = []
	for path: String in _paths_with_extension("dch"):
		var character: DialogicCharacter = load(path) as DialogicCharacter
		if character == null or not character.portraits.has(character.default_portrait):
			problems.append("%s: no portrait '%s'" % [path.get_file(), character.default_portrait if character else ""])

	assert_array(problems).is_empty()


func _paths_with_extension(extension: String) -> Array[String]:
	var paths: Array[String] = []
	for file: String in DirAccess.get_files_at(NARRATIVE_DIR):
		if file.get_extension() == extension:
			paths.append("%s/%s" % [NARRATIVE_DIR, file])
	return paths


func _portrait_problems(timeline: String, character_id: String, portrait: String) -> Array[String]:
	var character: DialogicCharacter = DialogicResourceUtil.get_character_resource(character_id)
	if character == null:
		return ["%s: unknown character '%s'" % [timeline, character_id]]
	if not character.portraits.has(portrait):
		return ["%s: character '%s' has no portrait '%s'" % [timeline, character_id, portrait]]

	var overrides: Dictionary = character.portraits[portrait].get("export_overrides", {})
	var image_path: String = str(overrides.get("image", "")).trim_prefix("\"").trim_suffix("\"")
	if not ResourceLoader.exists(image_path) or not load(image_path) is Texture2D:
		return ["%s: portrait '%s' of '%s' has no image at '%s'" % [timeline, portrait, character_id, image_path]]
	return []
