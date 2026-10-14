## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [SpritePreview]: reading a live node gives the same preview as reading its scene.
extends GdUnitTestSuite

const SCENE_PATHS: Array[String] = [
	"res://game/buildings/towers/bat_01.tscn",
	"res://game/buildings/towers/bat_09.tscn",
	"res://game/buildings/traps/bat_05.tscn",
]


func test_from_node_reads_the_same_preview_as_from_scene() -> void:
	for path: String in SCENE_PATHS:
		var scene: PackedScene = load(path)
		var node: Node = auto_free(scene.instantiate())

		var from_node: SpritePreview = SpritePreview.from_node(node)
		var from_scene: SpritePreview = SpritePreview.from_scene(scene)

		assert_object(from_node.texture).override_failure_message("%s: no texture" % path).is_not_null()
		assert_object(from_node.texture).override_failure_message(path).is_same(from_scene.texture)
		assert_that(from_node.modulate).override_failure_message(path).is_equal(from_scene.modulate)
		assert_vector(from_node.scale).override_failure_message(path).is_equal(from_scene.scale)
		assert_str(from_node.animation).override_failure_message(path).is_equal(from_scene.animation)
		assert_object(from_node.frames).override_failure_message(path).is_same(from_scene.frames)


func test_from_node_leaves_the_node_alive() -> void:
	var node: Node = auto_free(load(SCENE_PATHS[0]).instantiate())

	SpritePreview.from_node(node)

	assert_bool(is_instance_valid(node)).is_true()
	assert_bool(node.is_queued_for_deletion()).is_false()


func test_the_tint_of_a_sprite_is_read() -> void:
	var node: Node = auto_free(load("res://game/buildings/traps/bat_05.tscn").instantiate())

	assert_that(SpritePreview.from_node(node).modulate).is_equal(Color(1.0, 0.2, 0.2, 1.0))


func test_a_node_without_sprite_gives_an_empty_preview() -> void:
	var node: Node = auto_free(Node.new())

	var preview: SpritePreview = SpritePreview.from_node(node)

	assert_object(preview.texture).is_null()
	assert_that(preview.modulate).is_equal(Color.WHITE)


func test_from_scene_of_null_gives_an_empty_preview() -> void:
	assert_object(SpritePreview.from_scene(null).texture).is_null()
