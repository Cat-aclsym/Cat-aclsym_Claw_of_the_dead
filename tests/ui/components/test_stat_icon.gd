## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [StatIcon] atlas: one distinct, drawn cell per id, and the stat keys resolve to their icon.
extends GdUnitTestSuite

var _atlas_image: Image


func before() -> void:
	_atlas_image = StatIcon.ATLAS.get_image()


func test_the_atlas_is_one_row_with_a_cell_per_icon() -> void:
	assert_vector(StatIcon.ATLAS.get_size()).is_equal(Vector2((StatIcon.Id.size() - 1) * StatIcon.CELL_SIZE, StatIcon.CELL_SIZE))
	assert_int(StatIcon.COLUMNS).is_equal(StatIcon.Id.size() - 1)


func test_every_icon_has_a_region_inside_the_atlas() -> void:
	var atlas_rect: Rect2 = Rect2(Vector2.ZERO, StatIcon.ATLAS.get_size())

	for id: StatIcon.Id in _icons():
		assert_bool(atlas_rect.encloses(StatIcon.region(id))).override_failure_message("%s is outside the atlas" % StatIcon.key(id)).is_true()
		assert_vector(StatIcon.region(id).size).is_equal(Vector2.ONE * StatIcon.CELL_SIZE)


func test_every_icon_is_drawn_and_distinct() -> void:
	var seen: Dictionary[int, String] = {}

	for id: StatIcon.Id in _icons():
		var cell: Image = _atlas_image.get_region(Rect2i(StatIcon.region(id)))
		assert_bool(cell.is_invisible()).override_failure_message("%s is empty" % StatIcon.key(id)).is_false()
		var cell_hash: int = hash(cell.get_data())
		assert_bool(seen.has(cell_hash)).override_failure_message("%s equals %s" % [StatIcon.key(id), seen.get(cell_hash)]).is_false()
		seen[cell_hash] = StatIcon.key(id)


func test_icons_fill_the_atlas_cells_in_order() -> void:
	assert_vector(StatIcon.region(StatIcon.Id.AOE_RANGE).position).is_equal(Vector2.ZERO)
	assert_vector(StatIcon.region(StatIcon.Id.ATTACK).position).is_equal(Vector2(StatIcon.CELL_SIZE, 0.0))
	assert_vector(StatIcon.region(StatIcon.Id.ZOMBIE_SPEED).position).is_equal(Vector2(19.0 * StatIcon.CELL_SIZE, 0.0))


func test_none_has_no_texture() -> void:
	assert_object(StatIcon.texture(StatIcon.Id.NONE)).is_null()


func test_texture_is_cached_and_cut_from_the_atlas() -> void:
	var first: AtlasTexture = StatIcon.texture(StatIcon.Id.ATTACK)

	assert_object(StatIcon.texture(StatIcon.Id.ATTACK)).is_same(first)
	assert_object(StatIcon.texture(StatIcon.Id.RANGE)).is_not_same(first)
	assert_object(first.atlas).is_same(StatIcon.ATLAS)
	assert_object(first.region).is_equal(StatIcon.region(StatIcon.Id.ATTACK))


func test_every_stat_key_resolves_to_its_icon() -> void:
	for stat_name: String in StatIcon.BY_STAT:
		assert_object(StatIcon.for_stat(stat_name)).override_failure_message(stat_name).is_same(StatIcon.texture(StatIcon.BY_STAT[stat_name]))


func test_an_unknown_stat_has_no_icon() -> void:
	assert_object(StatIcon.for_stat("unknown")).is_null()


func test_every_icon_but_the_zombie_speed_belongs_to_a_stat_key() -> void:
	var mapped: Array[StatIcon.Id] = []
	mapped.assign(StatIcon.BY_STAT.values())

	for id: StatIcon.Id in _icons():
		assert_bool(id in mapped).override_failure_message("%s has no stat key" % StatIcon.key(id)).is_equal(id != StatIcon.Id.ZOMBIE_SPEED)


func test_key_is_the_name_of_the_id() -> void:
	assert_str(StatIcon.key(StatIcon.Id.ELECTRICITY_CHAIN_FALLOFF)).is_equal("ELECTRICITY_CHAIN_FALLOFF")


## Returns every id but [constant StatIcon.Id.NONE].
func _icons() -> Array[StatIcon.Id]:
	var icons: Array[StatIcon.Id] = []
	icons.assign(StatIcon.Id.values().slice(1))
	return icons
