## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A tower connects its own signals once, also when it is a duplicate of a duplicate like the buildings of the build placement.
extends GdUnitTestSuite

## Method of the tower that handles each signal, by emitter node path then signal name.
const EXPECTED_HANDLERS: Dictionary[String, Dictionary] = {
	"Area2D": {"area_exited": "_on_area_2d_area_exited", "body_entered": "_on_area_2d_body_entered", "body_exited": "_on_area_2d_body_exited"},
	"Button": {"pressed": "_on_tower_pressed"},
	"TowerHoverBox": {"mouse_entered": "_on_hover_changed", "mouse_exited": "_on_hover_changed"},
}


func test_every_tower_has_one_connection_per_signal(tower_id: String, test_parameters: Array = [["bat_01"], ["bat_02"], ["bat_08"], ["bat_09"]]) -> void:
	var template: ITower = _add_tower(load(StatsDB.get_tower(tower_id)["scene"]).instantiate())
	await get_tree().process_frame
	var preview: ITower = _add_tower(template.duplicate())
	await get_tree().process_frame
	var placed: ITower = _add_tower(preview.duplicate())
	await get_tree().process_frame

	for tower: ITower in [template, preview, placed]:
		assert_array(_connection_problems(tower)).is_empty()


## Lists the signals of [param tower] that are not connected exactly once to their handler of the tower.
func _connection_problems(tower: ITower) -> Array[String]:
	var problems: Array[String] = []
	for node_path: String in EXPECTED_HANDLERS:
		var emitter: Node = tower.get_node(node_path)
		var handlers: Dictionary = EXPECTED_HANDLERS[node_path]
		for signal_name: String in handlers:
			var own_connections: Array[Dictionary] = emitter.get_signal_connection_list(signal_name).filter(func(connection: Dictionary) -> bool: return (connection["callable"] as Callable).get_object() == tower)
			if own_connections.size() != 1 or (own_connections[0]["callable"] as Callable).get_method() != handlers[signal_name]:
				problems.append("%s.%s: %d connections to the tower" % [node_path, signal_name, own_connections.size()])
	return problems


func _add_tower(tower: Node) -> ITower:
	auto_free(tower)
	add_child(tower)
	return tower as ITower
