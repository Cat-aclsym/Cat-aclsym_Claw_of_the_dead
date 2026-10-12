## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Instant-hit projectile used by Tesla-like towers.
class_name InstantLightning
extends IBullet

## Number of points used to draw the lightning polyline.
const ARC_SEGMENTS: int = 8
## Fade-out duration for each lightning arc (seconds).
const ARC_LIFETIME: float = 0.08
## Max random offset per intermediate segment for jagged arc look.
const ARC_JITTER: float = 10.0
## Delay between two chained hits to keep bounce progression readable.
const CHAIN_BOUNCE_DELAY: float = 0.03
## Delay between each revealed point when drawing a chain arc.
const CHAIN_REVEAL_STEP_DELAY: float = 0.012
## Extra seconds a chain arc lives past its animation before it is freed.
const CHAIN_ARC_FREE_MARGIN: float = 0.05
## Target core color used when blue tint is enabled.
const BLUE_TINT_CORE: Color = Color(0.6, 0.9, 1.0, 1.0)
## Target glow color used when blue tint is enabled.
const BLUE_TINT_GLOW: Color = Color(0.45, 0.75, 1.0, 0.75)

## Number of additional enemies hit after the first target.
@export var chain_bounces: int = 0
## Flat falloff applied to each chained hit based on base damage.
@export var chain_damage_falloff: float = 0.0
## Maximum distance (in pixels) to find the next chain target.
@export var chain_range: float = 0.0
## Branch B: electrified debuff duration.
@export var electrify_duration: float = 0.0
## Branch B: movement slow applied while electrified.
@export var electrify_slow_amount: float = 0.0
## Branch B: periodic damage dealt while electrified.
@export var electrify_tick_damage: float = 0.0
## Branch B: time between electrified damage ticks.
@export var electrify_tick_interval: float = 0.5
## Visual blend toward blue lightning palette.
@export var lightning_blue_tint_strength: float = 0.0
## Visual width multiplier for the initial lightning arc.
@export var lightning_width_scale: float = 1.0

## Enemy resolved by the tower at fire time.
var enemy_target: IEnemy = null

## Random generator shared by every arc for the jagged look.
static var _rng: RandomNumberGenerator = _create_rng()

## Enemies hit by the chain, in bounce order (the first one is [member enemy_target]).
var _chain: Array[IEnemy] = []
## Position of each chained enemy when the chain was built, used when an enemy is gone before its arc.
var _chain_positions: PackedVector2Array = PackedVector2Array()

@onready var line_core: Line2D = $LineCore
@onready var line_glow: Line2D = $LineGlow

func _ready() -> void:
	assert(line_core != null, "Missing required node: LineCore")
	assert(line_glow != null, "Missing required node: LineGlow")
	_apply_visual_modifiers()

	# One tween drives the chained hits then the final fade, it dies with the bullet
	var tween: Tween = create_tween()
	if is_instance_valid(enemy_target):
		var points: PackedVector2Array = _build_arc_points(global_position, enemy_target.global_position, self)
		line_core.points = points
		line_glow.points = points

		_hit_enemy(enemy_target)
		_schedule_chain(tween)

	_add_flicker(tween, line_core, line_glow)
	SignalUtil.connects([{SignalUtil.WHO: tween, SignalUtil.WHAT: "finished", SignalUtil.TO: queue_free}])


static func _create_rng() -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng


## Reveals the first [param count] points of [param points] on both lines.
static func _reveal_arc(core: Line2D, glow: Line2D, points: PackedVector2Array, count: int) -> void:
	var partial_points: PackedVector2Array = points.slice(0, count)
	core.points = partial_points
	glow.points = partial_points


## Appends the lightning fade (alpha and width to zero, all at once) after the steps already in [param tween].
func _add_flicker(tween: Tween, core: Line2D, glow: Line2D) -> void:
	tween.tween_property(core, "modulate:a", 0.0, ARC_LIFETIME)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, ARC_LIFETIME)
	tween.parallel().tween_property(core, "width", 0.0, ARC_LIFETIME)
	tween.parallel().tween_property(glow, "width", 0.0, ARC_LIFETIME)


## Builds a jagged polyline between two global positions, in the local space of [param space].
func _build_arc_points(from_pos: Vector2, to_pos: Vector2, space: Node2D) -> PackedVector2Array:
	var arc_direction: Vector2 = from_pos.direction_to(to_pos)
	var normal: Vector2 = Vector2(-arc_direction.y, arc_direction.x)
	var points: PackedVector2Array = PackedVector2Array()

	for i in range(ARC_SEGMENTS + 1):
		var t: float = float(i) / float(ARC_SEGMENTS)
		var p: Vector2 = from_pos.lerp(to_pos, t)
		if i != 0 and i != ARC_SEGMENTS:
			p += normal * _rng.randf_range(-ARC_JITTER, ARC_JITTER)
		points.append(space.to_local(p))

	return points


## Picks the chained enemies once and queues their arcs and hits one-by-one on [param tween], so each bounce is readable.
func _schedule_chain(tween: Tween) -> void:
	if chain_bounces <= 0 or chain_range <= 0.0:
		return

	_chain = [enemy_target]
	_chain_positions = PackedVector2Array([enemy_target.global_position])
	var candidates: Array[IEnemy] = _get_chain_candidates(enemy_target)

	# Falloff is fixed per bounce from base damage (non-cumulative between bounces).
	var bounce_damage: float = float(damage) * maxf(0.0, 1.0 - chain_damage_falloff)

	for bounce in range(1, chain_bounces + 1):
		var next_enemy: IEnemy = _find_next_chain_target(_chain[bounce - 1], candidates)
		if next_enemy == null:
			return

		_chain.append(next_enemy)
		_chain_positions.append(next_enemy.global_position)
		tween.tween_callback(_spawn_chain_arc.bind(bounce))
		tween.tween_interval(CHAIN_BOUNCE_DELAY)
		tween.tween_callback(_hit_chained_enemy.bind(bounce, bounce_damage))


## Enemies on the path of [param first_enemy], fetched once per shot.
func _get_chain_candidates(first_enemy: IEnemy) -> Array[IEnemy]:
	var candidates: Array[IEnemy] = []
	for candidate_node: Node in get_tree().get_nodes_in_group("enemies"):
		var candidate: IEnemy = candidate_node as IEnemy
		if candidate != null and candidate != first_enemy and candidate.path == first_enemy.path:
			candidates.append(candidate)
	return candidates


## Nearest candidate within [member chain_range] of [param source_enemy] that is not in the chain yet.
func _find_next_chain_target(source_enemy: IEnemy, candidates: Array[IEnemy]) -> IEnemy:
	var nearest_enemy: IEnemy = null
	var nearest_distance: float = INF
	var max_distance: float = chain_range * chain_range
	var source_position: Vector2 = source_enemy.global_position

	for candidate_enemy in candidates:
		if _chain.has(candidate_enemy):
			continue

		var distance: float = source_position.distance_squared_to(candidate_enemy.global_position)
		if distance <= max_distance and distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = candidate_enemy

	return nearest_enemy


## Position of the enemy [param index] of the chain, its last known one when the enemy is gone.
func _get_chain_position(index: int) -> Vector2:
	return _chain[index].global_position if is_instance_valid(_chain[index]) else _chain_positions[index]


func _hit_chained_enemy(index: int, bounce_damage: float) -> void:
	if is_instance_valid(_chain[index]):
		_hit_enemy(_chain[index], bounce_damage)


func _hit_enemy(enemy: IEnemy, damage_override: float = -1.0) -> void:
	var final_damage: float = float(damage) if damage_override < 0.0 else damage_override
	enemy.take_damage(final_damage, IEnemy.DamageType.DEFAULT, self)

	if electrify_duration <= 0.0 or electrify_tick_damage <= 0.0:
		return
	if not enemy.has_method("apply_electrify_effect"):
		return

	enemy.apply_electrify_effect(
		electrify_duration,
		electrify_slow_amount,
		electrify_tick_damage,
		electrify_tick_interval,
		self
	)


## Draws the arc between chained enemies [param bounce] - 1 and [param bounce] under the bullet's parent, so it outlives the bullet.
func _spawn_chain_arc(bounce: int) -> void:
	var host: Node2D = get_parent() as Node2D
	if host == null:
		return

	var arc: Node2D = Node2D.new()
	var chain_line_core: Line2D = _duplicate_line(line_core)
	var chain_line_glow: Line2D = _duplicate_line(line_glow)
	arc.add_child(chain_line_core)
	arc.add_child(chain_line_glow)
	host.add_child(arc)

	var chain_points: PackedVector2Array = _build_arc_points(_get_chain_position(bounce - 1), _get_chain_position(bounce), arc)

	# Reveal the arc point by point, then fade it. The tween dies with the arc.
	var arc_tween: Tween = arc.create_tween()
	for visible_count in range(2, chain_points.size() + 1):
		arc_tween.tween_callback(_reveal_arc.bind(chain_line_core, chain_line_glow, chain_points, visible_count))
		arc_tween.tween_interval(CHAIN_REVEAL_STEP_DELAY)
	_add_flicker(arc_tween, chain_line_core, chain_line_glow)

	var reveal_duration: float = (chain_points.size() - 1) * CHAIN_REVEAL_STEP_DELAY
	VfxUtil.free_after(arc, reveal_duration + ARC_LIFETIME + CHAIN_ARC_FREE_MARGIN)


## Empty line with the look of [param source], used for the chain arcs.
func _duplicate_line(source: Line2D) -> Line2D:
	var line: Line2D = Line2D.new()
	line.default_color = source.default_color
	line.width = source.width
	line.z_index = source.z_index
	return line


func _apply_visual_modifiers() -> void:
	line_core.width *= maxf(0.1, lightning_width_scale)
	line_glow.width *= maxf(0.1, lightning_width_scale)

	var tint_strength: float = clampf(lightning_blue_tint_strength, 0.0, 1.0)
	if tint_strength <= 0.0:
		return

	line_core.default_color = line_core.default_color.lerp(BLUE_TINT_CORE, tint_strength)
	line_glow.default_color = line_glow.default_color.lerp(BLUE_TINT_GLOW, tint_strength)
