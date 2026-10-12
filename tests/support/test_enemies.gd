## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Puts enemies on a straight path for the tests, without a level.
class_name TestEnemies
extends RefCounted

const PATH_END: Vector2 = Vector2(1000.0, 0.0)


## Spawns the enemy [param id] under [param host] on its own path and waits for the frame its [method IEnemy._ready] ends on.
## [br]The path is freed with [param host]'s children: give it to [method GdUnitTestSuite.auto_free] or free [param host].
static func spawn(host: Node, id: String) -> IEnemy:
	var path: Path2D = Path2D.new()
	path.curve = Curve2D.new()
	path.curve.add_point(Vector2.ZERO)
	path.curve.add_point(PATH_END)
	var path_follow: PathFollow2D = PathFollow2D.new()
	path.add_child(path_follow)

	var enemy: IEnemy = StatsDB.get_enemy_scene(id).instantiate()
	enemy.path = path
	enemy.path_follow = path_follow
	path_follow.add_child(enemy)
	host.add_child(path)
	await host.get_tree().process_frame
	return enemy
