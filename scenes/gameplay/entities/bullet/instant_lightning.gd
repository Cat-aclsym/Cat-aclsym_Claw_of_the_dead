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

@onready var line_core: Line2D = $LineCore
@onready var line_glow: Line2D = $LineGlow

func _ready() -> void:
	assert(line_core != null, "Missing required node: LineCore")
	assert(line_glow != null, "Missing required node: LineGlow")
	_apply_visual_modifiers()
	_build_arc()

	if is_instance_valid(enemy_target):
		_hit_enemy(enemy_target)
		await _apply_chain_damage(enemy_target)

	var flicker: Tween = create_tween().set_parallel(true)
	flicker.tween_property(line_core, "modulate:a", 0.0, ARC_LIFETIME)
	flicker.tween_property(line_glow, "modulate:a", 0.0, ARC_LIFETIME)
	flicker.tween_property(line_core, "width", 0.0, ARC_LIFETIME)
	flicker.tween_property(line_glow, "width", 0.0, ARC_LIFETIME)
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

## Applies chained hits one-by-one, with a short delay so each bounce is readable.
func _apply_chain_damage(first_enemy: IEnemy) -> void:
	if chain_bounces <= 0 or chain_range <= 0.0:
		return

	var already_hit: Array[IEnemy] = [first_enemy]
	var source_enemy: IEnemy = first_enemy

	for _i in range(chain_bounces):
		var next_enemy: IEnemy = _find_next_chain_target(source_enemy, already_hit)
		if not is_instance_valid(next_enemy):
			return

		_spawn_chain_arc(source_enemy.global_position, next_enemy.global_position)
		await get_tree().create_timer(CHAIN_BOUNCE_DELAY).timeout

		# Falloff is fixed per bounce from base damage (non-cumulative between bounces).
		var bounce_multiplier: float = maxf(0.0, 1.0 - chain_damage_falloff)
		var bounce_damage: float = float(damage) * bounce_multiplier
		_hit_enemy(next_enemy, bounce_damage)
		already_hit.append(next_enemy)
		source_enemy = next_enemy

func _find_next_chain_target(source_enemy: IEnemy, excluded_enemies: Array[IEnemy]) -> IEnemy:
	if not is_instance_valid(source_enemy):
		return null

	var nearest_enemy: IEnemy = null
	var nearest_distance: float = INF
	var source_position: Vector2 = source_enemy.global_position
	var candidate_nodes: Array[Node] = get_tree().get_nodes_in_group("enemies")

	for candidate_node in candidate_nodes:
		if not (candidate_node is IEnemy):
			continue
		var candidate_enemy: IEnemy = candidate_node as IEnemy
		if not is_instance_valid(candidate_enemy) or excluded_enemies.has(candidate_enemy):
			continue

		if candidate_enemy.path != source_enemy.path:
			continue

		var distance: float = source_position.distance_to(candidate_enemy.global_position)
		if distance > chain_range:
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = candidate_enemy

	return nearest_enemy

func _hit_enemy(enemy: IEnemy, damage_override: float = -1.0) -> void:
	if not is_instance_valid(enemy):
		return

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

func _spawn_chain_arc(from_global: Vector2, target_global: Vector2) -> void:
	var chain_line_core: Line2D = Line2D.new()
	chain_line_core.default_color = line_core.default_color
	chain_line_core.width = line_core.width
	chain_line_core.z_index = line_core.z_index

	var chain_line_glow: Line2D = Line2D.new()
	chain_line_glow.default_color = line_glow.default_color
	chain_line_glow.width = line_glow.width
	chain_line_glow.z_index = line_glow.z_index

	add_child(chain_line_core)
	add_child(chain_line_glow)

	var chain_points: PackedVector2Array = _build_arc_points(from_global, target_global)
	await _animate_chain_reveal(chain_line_core, chain_line_glow, chain_points)

	var chain_flicker: Tween = create_tween().set_parallel(true)
	chain_flicker.tween_property(chain_line_core, "modulate:a", 0.0, ARC_LIFETIME)
	chain_flicker.tween_property(chain_line_glow, "modulate:a", 0.0, ARC_LIFETIME)
	chain_flicker.tween_property(chain_line_core, "width", 0.0, ARC_LIFETIME)
	chain_flicker.tween_property(chain_line_glow, "width", 0.0, ARC_LIFETIME)
	chain_flicker.finished.connect(func() -> void:
		if is_instance_valid(chain_line_core):
			chain_line_core.queue_free()
		if is_instance_valid(chain_line_glow):
			chain_line_glow.queue_free()
	)

## Reveals the chain arc progressively (point by point) to improve readability.
func _animate_chain_reveal(chain_line_core: Line2D, chain_line_glow: Line2D, full_points: PackedVector2Array) -> void:
	if full_points.size() <= 1:
		chain_line_core.points = full_points
		chain_line_glow.points = full_points
		return

	for visible_count in range(2, full_points.size() + 1):
		var partial_points: PackedVector2Array = PackedVector2Array()
		for i in range(visible_count):
			partial_points.append(full_points[i])
		chain_line_core.points = partial_points
		chain_line_glow.points = partial_points
		await get_tree().create_timer(CHAIN_REVEAL_STEP_DELAY).timeout

func _build_arc_points(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
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

	return points

func _apply_visual_modifiers() -> void:
	line_core.width *= maxf(0.1, lightning_width_scale)
	line_glow.width *= maxf(0.1, lightning_width_scale)

	var tint_strength: float = clampf(lightning_blue_tint_strength, 0.0, 1.0)
	if tint_strength <= 0.0:
		return

	line_core.default_color = line_core.default_color.lerp(BLUE_TINT_CORE, tint_strength)
	line_glow.default_color = line_glow.default_color.lerp(BLUE_TINT_GLOW, tint_strength)
