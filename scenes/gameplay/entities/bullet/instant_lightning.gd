## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Instant-hit projectile used by Tesla-like towers.
class_name InstantLightning
extends IBullet

const ARC_SEGMENTS: int = 8
const ARC_LIFETIME: float = 0.08
const ARC_JITTER: float = 10.0

## Enemy resolved by the tower at fire time.
var enemy_target: IEnemy = null

@onready var line_core: Line2D = $LineCore
@onready var line_glow: Line2D = $LineGlow

func _ready() -> void:
	assert(line_core != null, "Missing required node: LineCore")
	assert(line_glow != null, "Missing required node: LineGlow")
	_build_arc()

	if is_instance_valid(enemy_target):
		enemy_target.take_damage(damage, IEnemy.DamageType.DEFAULT, self)

	var flicker: Tween = create_tween().set_parallel(true)
	flicker.tween_property(line_core, "modulate:a", 0.0, ARC_LIFETIME)
	flicker.tween_property(line_glow, "modulate:a", 0.0, ARC_LIFETIME)
	flicker.tween_property(line_core, "width", 1.0, ARC_LIFETIME)
	flicker.tween_property(line_glow, "width", 3.0, ARC_LIFETIME)
	await flicker.finished
	queue_free()


func _build_arc() -> void:
	if not is_instance_valid(enemy_target):
		return

	var from_pos: Vector2 = global_position
	var to_pos: Vector2 = enemy_target.global_position
	var arc_direction: Vector2 = from_pos.direction_to(to_pos)
	var normal: Vector2 = Vector2(-arc_direction.y, arc_direction.x)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var points: PackedVector2Array = PackedVector2Array()
	for i in range(ARC_SEGMENTS + 1):
		var t: float = float(i) / float(ARC_SEGMENTS)
		var p: Vector2 = from_pos.lerp(to_pos, t)
		if i != 0 and i != ARC_SEGMENTS:
			p += normal * rng.randf_range(-ARC_JITTER, ARC_JITTER)
		points.append(to_local(p))

	line_core.points = points
	line_glow.points = points
