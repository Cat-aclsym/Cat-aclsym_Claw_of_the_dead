## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The Big Daddy connects its range area once, in code.
extends GdUnitTestSuite

const BIG_DADDY_ID: String = "big_daddy"


func test_the_range_area_signals_are_connected_once_to_the_enemy() -> void:
	var enemy: IEnemy = await TestEnemies.spawn(self, BIG_DADDY_ID)
	auto_free(enemy.path)
	var big_daddy: BigDaddy = enemy as BigDaddy

	for signal_name: String in ["body_entered", "body_exited"]:
		var own_connections: Array[Dictionary] = []
		own_connections.assign(big_daddy.range_area.get_signal_connection_list(signal_name).filter(func(connection: Dictionary) -> bool: return (connection["callable"] as Callable).get_object() == big_daddy))
		assert_int(own_connections.size()).is_equal(1)
		assert_str((own_connections[0]["callable"] as Callable).get_method()).is_equal("_on_range_area_" + signal_name)
