## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The translation keys of the names built by [method StatsDB.name_key] exist in English and French.
extends GdUnitTestSuite

const CSV_PATH: String = "res://assets/translations/translations.csv"

## Translation key to its [code][en, fr][/code] texts.
var _rows: Dictionary[String, PackedStringArray] = {}


func before() -> void:
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_object(file).is_not_null()
	var header: PackedStringArray = file.get_csv_line()
	assert_array(header).is_equal(PackedStringArray(["keys", "en", "fr"]))
	while not file.eof_reached():
		var columns: PackedStringArray = file.get_csv_line()
		if columns.size() == header.size():
			_rows[columns[0]] = columns.slice(1)


func test_every_enemy_name_is_translated() -> void:
	assert_array(_missing_names("ENEMY", StatsDB.get_enemy_ids())).is_empty()


func test_every_tower_name_is_translated() -> void:
	assert_array(_missing_names("TOWER", StatsDB.get_tower_ids())).is_empty()


func test_every_trap_name_is_translated() -> void:
	assert_array(_missing_names("TRAP", StatsDB.get_trap_ids())).is_empty()


func test_every_button_glyph_has_a_tooltip() -> void:
	var keys: Array[String] = []
	keys.assign(GameIcon.Id.values().slice(1).map(func(id: GameIcon.Id) -> String: return "BUTTON." + GameIcon.key(id)))

	assert_array(_missing(keys)).is_empty()


## Returns the name keys of [param ids] that lack a non-empty English or French text.
func _missing_names(category: String, ids: Array) -> Array[String]:
	var keys: Array[String] = []
	keys.assign(ids.map(func(id: String) -> String: return StatsDB.name_key(category, id)))
	return _missing(keys)


## Returns the [param keys] that lack a non-empty English or French text.
func _missing(keys: Array[String]) -> Array[String]:
	return keys.filter(func(key: String) -> bool:
		var texts: PackedStringArray = _rows.get(key, PackedStringArray(["", ""]))
		return texts[0].strip_edges().is_empty() or texts[1].strip_edges().is_empty())
