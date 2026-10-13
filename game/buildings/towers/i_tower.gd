## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Interface for a tower.
class_name ITower
extends IBuilding

## Enum for the type of target the tower will shoot at
enum TargetType {
	FIRST,    ## Shoots at the first enemy that enters the range
	LAST,     ## Shoots at the last enemy that enters the range
	STRONGEST, ## Shoots at the enemy with the most health
	WEAKEST,   ## Shoots at the enemy with the least health
	RANDOM    ## Shoots at a random enemy
}

## Enum for the state of the tower
enum TowerState {
	BUILDING,  ## The tower is being built
	UPGRADING, ## The tower is being upgraded
	ACTIVE,    ## The tower is placed and active
	DISABLED,  ## The tower is disabled by an enemy
}

## Extra pixels past the range where an enemy still counts as a target, and where a locked target is lost (hysteresis, no flicker).
const ACQUIRE_RANGE_MARGIN: float = 5.0
const LOSE_RANGE_MARGIN: float = 10.0

## Stats a map tile modifier multiplies on the tower.
const MODIFIER_STATS: Array[String] = ["damage", "fire_rate", "reward_multiplier", "shoot_range"]

## Gameplay keys applied from [member bullet_stats] onto each projectile at fire time (scenes keep VFX only).
const PROJECTILE_GAMEPLAY_KEYS: Array[String] = [
	"aoe_duration",
	"aoe_range",
	"aoe_tick",
	"burn_damage_base",
	"burn_duration",
	"chain_bounces",
	"chain_damage_falloff",
	"chain_range",
	"charge_speed",
	"damage",
	"damage_multiplier",
	"electrify_duration",
	"electrify_slow_amount",
	"electrify_tick_damage",
	"electrify_tick_interval",
	"is_charging",
	"lightning_blue_tint_strength",
	"lightning_width_scale",
	"max_damage_multiplier",
	"pierce_count",
	"pierce_reduction",
	"speed",
]

const RADIAL_UPGRADE_MENU: PackedScene = preload("res://ui/menus/tower_upgrade/radial_menu_tower_upgrade.tscn")
## Color of the range polygon.
const RANGE_COLOR: Color = Color.WHITE

# Exported variables
## The bullet scene to be instantiated by the tower
@export var bullet_scene: PackedScene = null
@export var tower_id: String = ""

## If true, damage popups from this tower will accumulate into a single number that updates.
## Recommended for continuous beams or extremely high-fire-rate towers.
@export var use_accumulative_popups: bool = false

## If true, enemies hit by this tower will use a shorter, more subtle damage flash effect.
## Recommended for continuous or high-fire-rate towers.
@export var use_short_damage_flash: bool = false

## Data-driven upgrade IDs available for this tower
var available_upgrade_ids: Array[String] = []
## The bullet stats to be applied to the bullet (overridden at runtime from StatsDB)
var bullet_stats: Dictionary = {}
## The enemy array to store enemies in the range of the tower
var enemy_array: Array[IEnemy]
## The fire rate of the tower (overridden at runtime)
var fire_rate: float = 0.0
## The level of the tower (overridden at runtime)
var level: int = 0
## The pending upgrade to be applied
var pending_upgrade_id: String = ""
## Prioritize enemies that are not electrified
var prefer_non_electrified_targets: bool = false
## The number of projectiles to fire simultaneously (overridden at runtime)
var projectile_count: int = 0
## Multiplier for gold rewards when this tower kills an enemy
var reward_multiplier: float = 1.0
## Is the tower is selected
var selected: bool = false
## The sell price of the tower (computed)
var sell_price: int = 0
## The shooting range of the tower (overridden at runtime)
var shoot_range: float = 0.0
## The angle spread between multiple projectiles (in degrees) (overridden at runtime)
var spread_angle: float = 0.0
## The state of the tower
var state: TowerState = TowerState.ACTIVE
## The target of the tower
var target: IEnemy
## Active time the tower has been locked on the current target
var target_lock_time: float = 0.0
## The type of target the tower will shoot at
var target_type: TargetType

## Ids of the upgrades applied to this tower, in order. Stats are recomputed from them whenever something changes.
var _applied_upgrade_ids: Array[String] = []
## Enemies in range, rebuilt by every target search
var _candidates: Array[IEnemy] = []
## Looping tween that pulses the range polygon while the range is shown
var _color_tween: Tween = null
## Flag to ignore hover interactions when menu is open
var _menu_open: bool = false
## Enemies of [member _candidates] that are not electrified, rebuilt by every target search
var _non_electrified_candidates: Array[IEnemy] = []
var _pulse_tween: Tween = null
var _range_tween: Tween = null
var _scale_tween: Tween = null
## Multipliers applied by the map tile the tower stands on (stat_name -> multiplier)
var _special_modifiers: Dictionary[String, float] = {}

# Onready variables
## The area 2D node for the tower to detect enemies in range
@onready var area_2d: Area2D = $Area2D
## The button node for the tower to interact with
@onready var button: Button = $Button
## The collision shape 2D node for the tower
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
## The timer for the fire rate of the tower to shoot bullets
@onready var fire_rate_timer: Timer = $FireRateTimer
## The area 2D node that detects the mouse hovering the tower
@onready var hover_area: Area2D = $TowerHoverBox
## The collision shape 2D node for the tower hover box
@onready var hover_box: CollisionShape2D = $TowerHoverBox/CollisionShape2D
## The line 2D node for the outline of the range polygon
@onready var outline: Line2D = $Polygon2D/Line2D
## The polygon 2D node for the range of the tower to detect enemies
@onready var polygon_2d: Polygon2D = $Polygon2D

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "area_exited", SignalUtil.TO: _on_area_2d_area_exited},
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_area_2d_body_entered},
	{SignalUtil.WHO: area_2d, SignalUtil.WHAT: "body_exited", SignalUtil.TO: _on_area_2d_body_exited},
	{SignalUtil.WHO: button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_tower_pressed},
	{SignalUtil.WHO: hover_area, SignalUtil.WHAT: "mouse_entered", SignalUtil.TO: _on_hover_changed.bind(true)},
	{SignalUtil.WHO: hover_area, SignalUtil.WHAT: "mouse_exited", SignalUtil.TO: _on_hover_changed.bind(false)},
]
## The sprite node for the tower to display the tower model
@onready var sprite: AnimatedSprite2D = %Sprite

# Core methods
func _ready() -> void:
	target_type = TargetType.FIRST
	assert(sprite != null)
	if bullet_scene == null:
		Log.trace(Log.Level.ERROR, "Tower %s has no bullet scene" % name)
	_apply_base_stats_override()
	_resolve_initial_upgrade_ids()
	ArmoryManager.append_unlocked_upgrade_ids(self)
	available_upgrade_ids = ArmoryManager.filter_upgrade_ids(available_upgrade_ids)
	sell_price = int(ceil(cost / 2.0))
	hover_box.z_index = 3
	update_dependent_properties()
	# Sync range visibility with selected state (especially for duplicated towers)
	show_range(selected, false)

	if state == TowerState.ACTIVE:
		call_deferred("_register_with_cursor")

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	SignalUtil.connects(signals)

func _process(delta: float) -> void:
	if Global.paused or state == TowerState.DISABLED:
		return

	if state == TowerState.BUILDING:
		_update_z_index()
		# Allow range display even during building
		return

	if is_instance_valid(target):
		# Verify if target is still valid (alive and in range, with a margin to avoid flickering)
		if not _is_valid_candidate(target, LOSE_RANGE_MARGIN):
			target = null
			target_lock_time = 0.0
			_on_target_lost()
		else:
			_on_target_locked(delta)

	if fire_rate_timer.is_stopped():
		fire()

# Public methods
## Applies special modifiers from a map tile, the applied upgrades are kept
func apply_special_modifier(modifiers: Dictionary) -> void:
	if modifiers.is_empty():
		_special_modifiers.clear()
	else:
		for stat: String in MODIFIER_STATS:
			if modifiers.has(stat):
				_special_modifiers[stat] = float(modifiers[stat])

	_recompute_stats()
	_apply_special_visual_effect(modifiers)

## Applies [code]stats.json[/code] [code]towers[/code] entry when [member tower_id] is set. Uses the [StatsDB] autoload so it works on orphan instances (e.g. build menu preview).
func apply_stats_from_db() -> void:
	if tower_id.is_empty():
		return
	if not StatsDB.has_tower(tower_id):
		Log.trace(Log.Level.ERROR, "StatsDB missing tower id: %s" % tower_id)
		return
	var data: Dictionary = StatsDB.get_tower(tower_id)
	var base: Dictionary = data.get("base", {})
	level = StatsDB.get_tower_level(tower_id)
	if base.has("cost"):
		cost = int(base["cost"])
	if base.has("fire_rate"):
		fire_rate = float(base["fire_rate"])
	if base.has("shoot_range"):
		shoot_range = float(base["shoot_range"])
	if base.has("projectile_count"):
		projectile_count = int(base["projectile_count"])
	if base.has("spread_angle"):
		spread_angle = float(base["spread_angle"])
	if base.has("bullet_stats"):
		var bs: Dictionary = base["bullet_stats"]
		for k: String in bs.keys():
			bullet_stats[k] = bs[k]

## Applies the pending upgrade to the tower
func apply_upgrade() -> void:
	if pending_upgrade_id.is_empty() or not StatsDB.has_upgrade(pending_upgrade_id):
		Log.trace(Log.Level.ERROR, "No pending upgrade id to apply")
		return
	var upgrade_id: String = pending_upgrade_id
	_applied_upgrade_ids.append(upgrade_id)
	_recompute_stats()
	_on_upgrade_applied()

	available_upgrade_ids = ArmoryManager.filter_upgrade_ids(StatsDB.get_upgrade_next_ids(upgrade_id))
	sell_price += ceili(StatsDB.get_upgrade_price(upgrade_id) / 2.0)
	pending_upgrade_id = ""
	state = TowerState.ACTIVE

func cancel_build_preview() -> void:
	show_range(false, true)

## Disables the tower functionality
func disable_tower() -> void:
	if state == TowerState.DISABLED:
		return
	state = TowerState.DISABLED
	if is_instance_valid(fire_rate_timer):
		fire_rate_timer.stop()

## Disables the tower for [param duration] seconds and dims its sprite meanwhile. The timer dies with the tower.
func disable_tower_for(duration: float) -> void:
	if state == TowerState.DISABLED:
		return
	disable_tower()

	if not is_instance_valid(sprite):
		return
	var original_modulate: Color = sprite.modulate
	sprite.modulate = Color(original_modulate.r, original_modulate.g, original_modulate.b, 0.5)

	var restore_tween: Tween = create_tween()
	restore_tween.tween_interval(duration)
	restore_tween.tween_callback(_end_timed_disable.bind(original_modulate))

## Enables the tower functionality back
func enable_tower() -> void:
	if state != TowerState.DISABLED:
		return
	state = TowerState.ACTIVE
	if is_instance_valid(fire_rate_timer) and fire_rate_timer.is_stopped():
		fire_rate_timer.start()

func enter_build_preview() -> void:
	state = TowerState.BUILDING
	show_range(true, false)

## Fires a bullet at the current target if conditions are met
func fire() -> void:
	if state != TowerState.ACTIVE or bullet_scene == null or enemy_array.is_empty():
		return

	_choose_target()

	if not target:
		return

	if _handle_custom_fire():
		return

	var enemy_position: Vector2 = target.global_position
	var base_direction: Vector2 = global_position.direction_to(enemy_position)

	# Calculate total spread angle for all projectiles
	var total_angle: float = spread_angle * (projectile_count - 1)
	var start_angle: float = -total_angle / 2

	# Spawn each projectile
	for i in range(projectile_count):
		var bullet_instance: IBullet = bullet_scene.instantiate()

		# Calculate angle for this projectile
		var current_angle: float = start_angle + (spread_angle * i)
		var rotated_direction: Vector2 = base_direction.rotated(deg_to_rad(current_angle))

		bullet_instance.direction = rotated_direction
		bullet_instance.rotation = rotated_direction.angle()
		bullet_instance.target = enemy_position
		bullet_instance.enemy_target = target

		# Set tower owner to allow reward multiplier logic
		bullet_instance.tower_owner = self

		_on_projectile_instantiated(bullet_instance, target)

		# If the specialized script handled the instance (e.g. by freeing it and reusing another), skip adding it
		if not is_instance_valid(bullet_instance):
			continue

		_apply_projectile_config(bullet_instance)
		add_child(bullet_instance)

	fire_rate_timer.start()

func get_building_kind() -> IBuilding.BuildingKind:
	return IBuilding.BuildingKind.TOWER

## Returns a copy of [member bullet_stats] for UI and tooling (single source for projectile numbers).
func get_display_bullet_stats() -> Dictionary:
	return bullet_stats.duplicate()

func get_placement_vertical_offset() -> float:
	return 16.0

## Sells the tower
func sell_tower() -> void:
	ILevel.current_level.coins += sell_price
	var placement_system: BuildPlacement = Global.cursor
	if placement_system:
		placement_system.remove_invalid_cell(tile_pos)
	queue_free()

## Animates the range display
func show_range(p_show: bool, smooth: bool = true) -> void:
	selected = p_show

	# If not in tree yet, the @onready variables aren't initialized.
	# We just set the state and return; visuals will be handled by the scene's default state
	# or subsequent calls once ready.
	if not is_node_ready() or polygon_2d == null or outline == null:
		return

	if _range_tween:
		_range_tween.kill()

	if p_show:
		polygon_2d.visible = true
		outline.visible = true
		if smooth:
			_range_tween = create_tween().set_parallel(true)
			_range_tween.tween_property(polygon_2d, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_range_tween.tween_property(outline, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			polygon_2d.scale = Vector2(1, 1)
			outline.scale = Vector2(1, 1)
		_color_variation()
	else:
		_stop_color_variation()
		if smooth:
			_range_tween = create_tween().set_parallel(true)
			_range_tween.tween_property(polygon_2d, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_range_tween.tween_property(outline, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_range_tween.set_parallel(false)
			_range_tween.tween_callback(func() -> void:
				polygon_2d.visible = false
				outline.visible = false
			)
		else:
			polygon_2d.scale = Vector2(0, 0)
			outline.scale = Vector2(0, 0)
			polygon_2d.visible = false
			outline.visible = false


## Starts the upgrade process with the given upgrade id, an upgrade already running blocks any other one
func start_upgrade(upgrade_id: String) -> void:
	if state != TowerState.ACTIVE:
		Log.trace(Log.Level.WARN, "Cannot start upgrade: tower is not active")
		return
	if upgrade_id.is_empty() or not StatsDB.has_upgrade(upgrade_id):
		Log.trace(Log.Level.ERROR, "Invalid upgrade id: %s" % upgrade_id)
		return
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Cannot start upgrade: current level is null")
		return
	var upgrade_price: int = StatsDB.get_upgrade_price(upgrade_id)
	if ILevel.current_level.coins < upgrade_price:
		Log.trace(Log.Level.ERROR, "Not enough coins to upgrade")
		return
	ILevel.current_level.coins -= upgrade_price
	pending_upgrade_id = upgrade_id
	state = TowerState.UPGRADING
	$ProgressBar.value = 0
	$ProgressBar.visible = true
	$Timer.start()

## Updates properties that depend on tower stats
func update_dependent_properties() -> void:
	if collision_shape_2d.shape is CircleShape2D:
		collision_shape_2d.shape.radius = shoot_range

	_create_range_polygon(shoot_range, 50)

	if fire_rate_timer != null:
		fire_rate_timer.wait_time = 1.0 / max(fire_rate, 0.001)
		if fire_rate_timer.is_stopped():
			fire_rate_timer.start()

	_update_z_index()

# Private methods
func _apply_base_stats_override() -> void:
	apply_stats_from_db()
	ArmoryManager.apply_buffs_to_tower(self)

func _apply_bullet_stat_changes(bullet_stats_delta: Dictionary) -> void:
	for stat: String in bullet_stats_delta.keys():
		var delta: Variant = bullet_stats_delta[stat]
		if bullet_stats.has(stat):
			var current_value: Variant = bullet_stats[stat]
			if typeof(current_value) == TYPE_BOOL:
				bullet_stats[stat] = bool(delta)
			else:
				bullet_stats[stat] += delta
		else:
			bullet_stats[stat] = delta


## Overwrites gameplay fields on the projectile from [member bullet_stats] (tower-owned balance; scenes are VFX-only).
func _apply_projectile_config(bullet_instance: IBullet) -> void:
	if bullet_instance == null:
		return
	for key in PROJECTILE_GAMEPLAY_KEYS:
		if not bullet_stats.has(key):
			continue
		if not (key in bullet_instance):
			continue
		var v: Variant = bullet_stats[key]
		match key:
			"speed", "pierce_count", "burn_damage_base", "aoe_range", "pierce_reduction":
				bullet_instance.set(key, int(round(float(v))))
			"damage", "burn_duration", "aoe_duration", "aoe_tick", "damage_multiplier", "charge_speed", "max_damage_multiplier":
				bullet_instance.set(key, float(v))
			"is_charging":
				bullet_instance.set(key, bool(v))
			_:
				bullet_instance.set(key, v)


## Applies a visual effect to the tower based on the modifier
func _apply_special_visual_effect(modifier: Dictionary) -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if _scale_tween:
		_scale_tween.kill()
		_scale_tween = null

	var target: Node2D = sprite if sprite else self

	# Reset visual state if no modifier or no color
	if not modifier.has("color"):
		target.modulate = Color.WHITE
		target.scale = Vector2(1, 1)
		return

	# Keep the tower visuals neutral; the bonus tile scene owns the color tint.
	target.modulate = Color.WHITE

	# Add a small scale effect only to the tower sprite
	var target_scale: float = 0.85 if modifier.get("is_malus", false) else 1.15
	_scale_tween = create_tween()
	_scale_tween.tween_property(target, "scale", Vector2(target_scale, target_scale), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _apply_tower_stat_changes(tower_stats: Dictionary) -> void:
	for stat: String in tower_stats.keys():
		if stat == "level":
			continue
		if stat in self:
			var current_value: Variant = self.get(stat)
			var delta_value: Variant = tower_stats[stat]
			if typeof(current_value) == TYPE_BOOL:
				self.set(stat, bool(delta_value))
			elif typeof(current_value) == TYPE_INT and typeof(delta_value) == TYPE_INT:
				self.set(stat, current_value + delta_value)
			elif typeof(current_value) == TYPE_FLOAT or typeof(delta_value) == TYPE_FLOAT:
				self.set(stat, float(current_value) + float(delta_value))
			else:
				self.set(stat, delta_value)
		elif stat in bullet_stats:
			# If the stat is not in the tower but in bullet_stats, apply it there
			_apply_bullet_stat_changes({stat: tower_stats[stat]})

## Applies the tower and bullet changes of one upgrade, plus its bullet scene override.
func _apply_upgrade_stats(upgrade_id: String) -> void:
	var changes: Dictionary = StatsDB.get_upgrade_changes(upgrade_id)
	var tower_stats: Dictionary = StatsDB.get_upgrade_tower_stats(upgrade_id)

	if changes.get("tower_stat", false):
		_apply_tower_stat_changes(tower_stats)

	if changes.get("bullet_stat", false):
		_apply_bullet_stat_changes(StatsDB.get_upgrade_bullet_stats(upgrade_id))

	if changes.get("bullet_model", false):
		var bullet_override: PackedScene = StatsDB.get_upgrade_bullet_scene(upgrade_id)
		if bullet_override != null:
			bullet_scene = bullet_override

	level += int(tower_stats.get("level", 1))

func _choose_target() -> void:
	var old_target: IEnemy = target

	# Keep only the enemies actually in range (with a small margin), the buffers are reused between searches
	_candidates.clear()
	_non_electrified_candidates.clear()
	for e in enemy_array:
		if is_instance_valid(e) and _is_valid_candidate(e, ACQUIRE_RANGE_MARGIN):
			_candidates.append(e)
			if prefer_non_electrified_targets and not e.is_electrified():
				_non_electrified_candidates.append(e)

	if _non_electrified_candidates.is_empty():
		target = _pick_target(_candidates)
	else:
		target = _pick_target(_non_electrified_candidates)

	if target != old_target:
		target_lock_time = 0.0
		_on_target_lost()

## Pulses the range polygon between visible and transparent while the range is shown.
func _color_variation() -> void:
	if not selected or polygon_2d == null:
		return
	_stop_color_variation()

	var visible_color: Color = Color(RANGE_COLOR, 0.3)
	var transparent_color: Color = Color(RANGE_COLOR, 0.0)
	_color_tween = create_tween().set_loops()
	_color_tween.tween_property(polygon_2d, "color", transparent_color, 0.4).from(visible_color)
	_color_tween.tween_property(polygon_2d, "color", visible_color, 0.4).from(transparent_color)

## Function to create the range polygon for the tower when the tower is selected.
## [param radius] - The radius of the range polygon.
## [param precision] - The number of points in the range polygon.
func _create_range_polygon(radius: float, precision: int) -> void:
	## Create an array of Vector2 points for the range polygon
	var points: Array[Vector2] = []
	for i in range(precision):
		var angle: float = 2 * PI * i / precision
		var x: float = radius * cos(angle)
		var y: float = radius * sin(angle)

		points.append(Vector2(x, y))

	## Set the points, rotation, skew, position, and color of the range polygon
	polygon_2d.polygon = points
	polygon_2d.rotation = collision_shape_2d.rotation
	polygon_2d.skew = collision_shape_2d.skew
	polygon_2d.position = collision_shape_2d.position
	polygon_2d.color = Color(RANGE_COLOR, 0.3)

	## Set the z-index of the range polygon to 1, making it appear below other nodes
	sprite.z_index = 1

	## Add the first value of points to the end of the array to close the outline
	points.append(Vector2(points[0]))
	outline.points = points

	## Set the width and color of the outline
	outline.width = 3
	outline.default_color = Color(1, 1, 1, 1)

func _end_timed_disable(original_modulate: Color) -> void:
	sprite.modulate = original_modulate
	enable_tower()


## Returns the enemy of [param candidates] with the most health, or the least when [param strongest] is false.
func _find_by_health(candidates: Array[IEnemy], strongest: bool) -> IEnemy:
	var best: IEnemy = candidates[0]
	for enemy in candidates:
		if enemy.health > best.health if strongest else enemy.health < best.health:
			best = enemy
	return best


## Virtual method to handle custom firing logic. Returns true if the fire event was handled.
func _handle_custom_fire() -> bool:
	return false

## True if [param enemy] is alive and within the range extended by [param margin] pixels. [param enemy] must not be freed.
func _is_valid_candidate(enemy: IEnemy, margin: float) -> bool:
	return not enemy.is_already_dead and global_position.distance_to(enemy.global_position) <= shoot_range + margin


## Virtual method called after a standard projectile is instantiated, before it's added to the tree.
func _on_projectile_instantiated(_bullet: IBullet, _target_enemy: IEnemy) -> void:
	pass


## Virtual method called every frame when a target is locked.
func _on_target_locked(delta: float) -> void:
	target_lock_time += delta


## Virtual method called when the tower's target is lost or changed.
func _on_target_lost() -> void:
	pass


## Virtual method called after an upgrade is applied.
func _on_upgrade_applied() -> void:
	pass


## Returns the enemy of [param candidates] picked by [member target_type], null when there is none.
func _pick_target(candidates: Array[IEnemy]) -> IEnemy:
	if candidates.is_empty():
		return null

	match target_type:
		TargetType.LAST:
			return candidates[-1]
		TargetType.STRONGEST:
			return _find_by_health(candidates, true)
		TargetType.WEAKEST:
			return _find_by_health(candidates, false)
		TargetType.RANDOM:
			return candidates.pick_random()
		_:
			return candidates[0]

## Rebuilds every stat from scratch: database base stats, armory buffs, each applied upgrade in order, then the tile modifiers.
func _recompute_stats() -> void:
	bullet_stats.clear()
	reward_multiplier = 1.0
	prefer_non_electrified_targets = false
	_apply_base_stats_override()

	for upgrade_id: String in _applied_upgrade_ids:
		_apply_upgrade_stats(upgrade_id)

	fire_rate *= _special_modifiers.get("fire_rate", 1.0)
	shoot_range *= _special_modifiers.get("shoot_range", 1.0)
	reward_multiplier *= _special_modifiers.get("reward_multiplier", 1.0)
	if bullet_stats.has("damage"):
		bullet_stats["damage"] = float(bullet_stats["damage"]) * _special_modifiers.get("damage", 1.0)

	update_dependent_properties()


func _resolve_initial_upgrade_ids() -> void:
	if available_upgrade_ids.is_empty() and not tower_id.is_empty():
		available_upgrade_ids = StatsDB.get_upgrade_ids_for_tower(tower_id)

func _stop_color_variation() -> void:
	if _color_tween:
		_color_tween.kill()
		_color_tween = null

## Function to check the z position of the tower and adapt the z index of the tower.
func _update_z_index() -> void:
	z_index = DepthSort.z_from_y(global_position.y)
	polygon_2d.z_index = z_index

# Signal callbacks
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area is IBullet and area in get_children():
		area.queue_free()

func _on_area_2d_body_entered(body: Node) -> void:
	if body is IEnemy:
		enemy_array.append(body)

func _on_area_2d_body_exited(body: Node) -> void:
	if body is IEnemy:
		enemy_array.erase(body)

func _on_timer_timeout() -> void:
	$ProgressBar.value += 1
	if $ProgressBar.value >= $ProgressBar.max_value:
		apply_upgrade()
		$Timer.stop()
		$ProgressBar.visible = false

## Shows the range while the mouse hovers the tower, unless the game is paused or a menu is open.
func _on_hover_changed(hovered: bool) -> void:
	if Global.paused or _menu_open:
		return
	show_range(hovered)

func _on_tower_pressed() -> void:
	Log.trace(Log.Level.DEBUG, "Tower Pressed")
	if Global.paused:
		return

	if state != TowerState.ACTIVE:
		return

	if _menu_open:
		return

	var tower_upgrade_menu_instance: RadialTowerUpgradeMenu = RADIAL_UPGRADE_MENU.instantiate()
	tower_upgrade_menu_instance.position = position
	tower_upgrade_menu_instance.name = "TowerUpgrade"
	self.add_child(tower_upgrade_menu_instance)

	# Keep range visible while menu is open
	_menu_open = true
	show_range(true)

	# Hide the menu when closed
	await tower_upgrade_menu_instance.tree_exited
	_menu_open = false
	show_range(false)
