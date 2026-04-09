## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Interface for a tower.
class_name ITower
extends IBuilding

## Signal emitted when the tower starts upgrading
signal upgrade_started
## Signal emitted when the tower finishes upgrading
signal upgrade_completed

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
}

## Enum for the type of the tower
enum TowerType {
	TOWER_1, ## The first tower
	TOWER_AOE, ## The tower with area of effect damage
	DEBUG_MULTISHOT, ## The debug multishot tower
	DEBUG_PIERCING, ## The debug piercing tower
}

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
	"damage",
	"damage_multiplier",
	"dot_damage",
	"electrify_duration",
	"electrify_slow_amount",
	"electrify_tick_damage",
	"electrify_tick_interval",
	"lightning_blue_tint_strength",
	"lightning_width_scale",
	"pierce_count",
	"pierce_reduction",
	"speed",
]

# Exported variables
## The bullet scene to be instantiated by the tower
@export var bullet_scene: PackedScene = null

## The bullet stats to be applied to the bullet (overridden at runtime from StatsDB)
var bullet_stats: Dictionary = {}

## The number of projectiles to fire simultaneously (overridden at runtime)
var projectile_count: int = 0
## The angle spread between multiple projectiles (in degrees) (overridden at runtime)
var spread_angle: float = 0.0

## The fire rate of the tower (overridden at runtime)
var fire_rate: float = 0.0
## The level of the tower (overridden at runtime)
var level: int = 0
## The sell price of the tower (computed)
var sell_price: int = 0
## The shooting range of the tower (overridden at runtime)
var shoot_range: float = 0.0

## Multiplier for gold rewards when this tower kills an enemy
var reward_multiplier: float = 1.0
## Prioritize enemies that are not electrified
var prefer_non_electrified_targets: bool = false

## Dictionary of modifiers applied to this tower (stat_name -> multiplier)
var _special_modifiers: Dictionary = {}

## Data-driven upgrade IDs available for this tower
var available_upgrade_ids: Array[String] = []

# Onready variables
## The area 2D node for the tower to detect enemies in range
@onready var area_2d: Area2D = $Area2D
## The collision shape 2D node for the tower
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
## The timer for the fire rate of the tower to shoot bullets
@onready var fire_rate_timer: Timer = $FireRateTimer
## The collision shape 2D node for the tower hover box
@onready var hover_box: CollisionShape2D = $TowerHoverBox/CollisionShape2D
## The line 2D node for the outline of the range polygon
@onready var outline: Line2D = $Polygon2D/Line2D
## The polygon 2D node for the range of the tower to detect enemies
@onready var polygon_2d: Polygon2D = $Polygon2D
## The sprite node for the tower to display the tower model
@onready var sprite: AnimatedSprite2D = %Sprite
## The button node for the tower to interact with
@onready var button: Button = $Button

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_tower_pressed}
]

# Variables
## The color of the range polygon
var color: String = "#FFFFFF"
## The enemy array to store enemies in the range of the tower
var enemy_array: Array[IEnemy]
## Is the tower is selected
var selected: bool = false
## The state of the tower
var state: TowerState = TowerState.ACTIVE
## Flag to cancel ongoing animations
var _cancel_animations: bool = false
## Flag to ignore hover interactions when menu is open
var _menu_open: bool = false
## The target of the tower
var target: IEnemy
## The time the tower has been locked on the current target
var target_lock_time: float = 0.0
## Active beams for continuous fire towers (bullet_instance -> target)
var _active_beams: Dictionary = {}
## The type of target the tower will shoot at
var target_type: TargetType
## The pending upgrade to be applied
var pending_upgrade_id: String = ""
## The tile position of the tower on the map
var tile_pos: Vector2i
var _pulse_tween: Tween = null
var _scale_tween: Tween = null
var _range_tween: Tween = null
@export var tower_id: String = ""

# Core methods
func _ready() -> void:
	target_type = TargetType.FIRST
	assert(sprite != null)
	_apply_base_stats_override()
	_resolve_initial_upgrade_ids()
	ArmoryManager.append_unlocked_upgrade_ids(self)
	available_upgrade_ids = _filter_upgrade_ids(available_upgrade_ids)
	sell_price = ceil(cost / 2.0)
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
	if Global.paused:
		return

	if state == TowerState.BUILDING:
		_update_z_index()
		# Allow range display even during building
		return
	
	if is_instance_valid(target):
		# Vérifier si la cible est toujours valide (vivante et à portée avec une marge de 10px pour éviter le clignotement)
		if target.is_already_dead or global_position.distance_to(target.global_position) > shoot_range + 10.0:
			target = null
			target_lock_time = 0.0
			_cleanup_beams()
		else:
			target_lock_time += delta

	if fire_rate_timer.is_stopped():
		fire()

# Public methods
func cancel_build_preview() -> void:
	show_range(false, true)

func enter_build_preview() -> void:
	state = TowerState.BUILDING
	show_range(true, false)

func get_building_kind() -> IBuilding.BuildingKind:
	return IBuilding.BuildingKind.TOWER

## Returns a copy of [member bullet_stats] for UI and tooling (single source for projectile numbers).
func get_display_bullet_stats() -> Dictionary:
	return bullet_stats.duplicate()

func get_placement_vertical_offset() -> float:
	return 16.0

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
	Log.trace(Log.Level.INFO, "Applying tower stats from StatsDB for %s: %s" % [tower_id, base])
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
		for k in bs.keys():
			bullet_stats[k] = bs[k]

## Fires a bullet at the current target if conditions are met
func fire() -> void:
	if state != TowerState.ACTIVE or not len(enemy_array):
		return

	if bullet_scene == null:
		Log.trace(Log.Level.ERROR, "Missing bullet scene")
		return

	_choose_target()

	if not target:
		Log.trace(Log.Level.WARN, "Failed to retrieve target")
		return

	var enemy_position: Vector2 = target.global_position
	var base_direction: Vector2 = global_position.direction_to(enemy_position)

	# Calculate total spread angle for all projectiles
	var total_angle: float = spread_angle * (projectile_count - 1)
	var start_angle: float = -total_angle / 2

	# Spawn each projectile
	for i in range(projectile_count):
		# For continuous beams, check if we already have an active beam for this target
		if bullet_scene and "inferno_beam" in bullet_scene.resource_path:
			var existing_beam = null
			for beam in _active_beams.keys():
				if is_instance_valid(beam) and _active_beams[beam] == target:
					existing_beam = beam
					break
			
			if existing_beam:
				# Re-trigger damage and visual update on existing beam
				if existing_beam.has_method("fire_tick"):
					existing_beam.fire_tick()
				continue

		var bullet_instance: IBullet = bullet_scene.instantiate()

		# Calculate angle for this projectile
		var current_angle: float = start_angle + (spread_angle * i)
		var rotated_direction: Vector2 = base_direction.rotated(deg_to_rad(current_angle))

		bullet_instance.direction = rotated_direction
		bullet_instance.rotation = rotated_direction.angle()
		bullet_instance.target = enemy_position
		if "enemy_target" in bullet_instance:
			bullet_instance.enemy_target = target

		# Set tower owner to allow reward multiplier logic
		if "tower_owner" in bullet_instance:
			bullet_instance.tower_owner = self

		_apply_projectile_config(bullet_instance)
		add_child(bullet_instance)

		if bullet_scene and "inferno_beam" in bullet_scene.resource_path:
			_active_beams[bullet_instance] = target

	fire_rate_timer.start()

## Starts the upgrade process with the given upgrade id
func start_upgrade(upgrade_id: String) -> void:
	if upgrade_id.is_empty() or not StatsDB.has_upgrade(upgrade_id):
		Log.trace(Log.Level.ERROR, "Invalid upgrade id: %s" % upgrade_id)
		return
	var upgrade_price: int = StatsDB.get_upgrade_price(upgrade_id)
	if ILevel.current_level.coins < upgrade_price:
		Log.trace(Log.Level.ERROR, "Not enough coins to upgrade")
		return
	pending_upgrade_id = upgrade_id
	state = TowerState.UPGRADING
	$ProgressBar.value = 0
	$ProgressBar.visible = true
	$Timer.start()
	emit_signal("upgrade_started")

## Applies the pending upgrade to the tower
func apply_upgrade() -> void:
	if pending_upgrade_id.is_empty() or not StatsDB.has_upgrade(pending_upgrade_id):
		Log.trace(Log.Level.ERROR, "No pending upgrade id to apply")
		return
	var changes: Dictionary = StatsDB.get_upgrade_changes(pending_upgrade_id)
	var tower_stats: Dictionary = StatsDB.get_upgrade_tower_stats(pending_upgrade_id)
	var bullet_stats_delta: Dictionary = StatsDB.get_upgrade_bullet_stats(pending_upgrade_id)
	var upgrade_data: Dictionary = StatsDB.get_upgrade(pending_upgrade_id)

	if changes.get("tower_stat", false):
		_apply_tower_stat_changes(tower_stats)

	if changes.get("bullet_stat", false):
		_apply_bullet_stat_changes(bullet_stats_delta)

	if changes.get("tower_model", false):
		var tower_model_path: String = str(upgrade_data.get("tower_model_path", ""))
		var tower_model_res: Resource = load(tower_model_path) if not tower_model_path.is_empty() else null
		if tower_model_res is Texture2D:
			if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
				var idle_anim = sprite.sprite_frames.get_animation("idle")
				# Determine frame index: 0 to add if empty, or last frame index to update
				var frame_idx = 0
				if idle_anim.get_frame_count() > 0:
					frame_idx = idle_anim.get_frame_count() - 1

				idle_anim.set_frame_texture(frame_idx, tower_model_res)

				if not sprite.is_playing() or sprite.animation != "idle":
					sprite.play("idle")
			else:
				var reason = "'idle' animation missing"
				if sprite.sprite_frames == null:
					reason = "no sprite_frames assigned"
				elif not sprite.sprite_frames.has_animation("idle"):
					reason = "'idle' animation missing"
				Log.trace(Log.Level.WARN, "Cannot apply tower_model texture: %s in AnimatedSprite2D." % reason)
		elif not tower_model_path.is_empty():
			Log.trace(Log.Level.ERROR, "tower_model_path is not a Texture2D as expected. Type: %s" % typeof(tower_model_res))

	if changes.get("bullet_model", false):
		var bullet_override: PackedScene = StatsDB.get_upgrade_bullet_scene(pending_upgrade_id)
		if bullet_override != null:
			bullet_scene = bullet_override

	available_upgrade_ids = _filter_upgrade_ids(StatsDB.get_upgrade_next_ids(pending_upgrade_id))
	sell_price += ceil(float(StatsDB.get_upgrade_price(pending_upgrade_id)) / 2.0)
	update_dependent_properties()
	level += int(tower_stats.get("level", 1))
	pending_upgrade_id = ""
	state = TowerState.ACTIVE
	emit_signal("upgrade_completed")

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

## Applies special modifiers from a map tile
func apply_special_modifier(modifiers: Dictionary) -> void:
	if modifiers.is_empty():
		_special_modifiers.clear()
	else:
		for stat in modifiers.keys():
			_special_modifiers[stat] = modifiers[stat]

	# Re-apply base stats first to avoid stacking multipliers incorrectly
	_apply_base_stats_override()

	# Apply modifiers to basic tower stats
	if _special_modifiers.has("fire_rate"):
		fire_rate *= _special_modifiers["fire_rate"]
	if _special_modifiers.has("shoot_range"):
		shoot_range *= _special_modifiers["shoot_range"]
	if _special_modifiers.has("reward_multiplier"):
		reward_multiplier *= _special_modifiers["reward_multiplier"]

	# Apply modifiers to bullet stats
	if _special_modifiers.has("damage") and bullet_stats.has("damage"):
		bullet_stats["damage"] = int(bullet_stats["damage"] * _special_modifiers["damage"])

	Log.trace(Log.Level.INFO, "Tower {0} stats updated with modifiers: {1}".format([name, _special_modifiers]))
	_apply_special_visual_effect(modifiers)
	update_dependent_properties()

## Applies a visual effect to the tower based on the modifier
func _apply_special_visual_effect(modifier: Dictionary) -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if _scale_tween:
		_scale_tween.kill()
		_scale_tween = null

	# Reset visual state if no modifier or no color
	if not modifier.has("color"):
		if sprite:
			sprite.modulate = Color.WHITE
			sprite.scale = Vector2(1, 1)
		else:
			self.modulate = Color.WHITE
			self.scale = Vector2(1, 1)
		return

	# Keep the tower visuals neutral; the bonus tile scene owns the color tint.
	if sprite:
		sprite.modulate = Color.WHITE
	else:
		self.modulate = Color.WHITE

	# Add a small scale effect only to the tower sprite
	_scale_tween = create_tween()
	if sprite:
		if modifier["label"].ends_with("-"):
			_scale_tween.tween_property(sprite, "scale", Vector2(0.85, 0.85), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			_scale_tween.tween_property(sprite, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		if modifier["label"].ends_with("-"):
			_scale_tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			_scale_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Builds the tower
func build_tower() -> void:
	pass

## Sells the tower
func sell_tower() -> void:
	ILevel.current_level.coins += sell_price
	var placement_system: BuildPlacement = Global.get("cursor") as BuildPlacement
	if placement_system:
		placement_system.remove_invalid_cell(tile_pos)
	queue_free()

func _register_with_cursor() -> void:
	if not is_inside_tree():
		return

	# Safe access to Global.cursor to avoid assertion if it's not yet set
	var placement_system: BuildPlacement = Global.get("cursor") as BuildPlacement
	if placement_system:
		if tile_pos == Vector2i.ZERO:
			if placement_system.tm_ref:
				# Use global position to ensure correct map conversion
				tile_pos = placement_system.tm_ref.local_to_map(placement_system.tm_ref.to_local(global_position))
		placement_system.add_invalid_cell(tile_pos)

# Private methods
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
		selected = true
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
		selected = false
		if smooth:
			_range_tween = create_tween().set_parallel(true)
			_range_tween.tween_property(polygon_2d, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_range_tween.tween_property(outline, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_range_tween.set_parallel(false)
			_range_tween.tween_callback(func():
				polygon_2d.visible = false
				outline.visible = false
			)
		else:
			polygon_2d.scale = Vector2(0, 0)
			outline.scale = Vector2(0, 0)
			polygon_2d.visible = false
			outline.visible = false

func _apply_tower_stat_changes(tower_stats: Dictionary) -> void:
	for stat in tower_stats.keys():
		if stat == "level":
			continue
		if stat in self:
			Log.trace(Log.Level.DEBUG, "Modifying stat: {0} by {1}".format([stat, tower_stats[stat]]))
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

func _apply_bullet_stat_changes(bullet_stats_delta: Dictionary) -> void:
	for stat in bullet_stats_delta.keys():
		var delta: Variant = bullet_stats_delta[stat]
		if bullet_stats.has(stat):
			bullet_stats[stat] += delta
		else:
			bullet_stats[stat] = delta


## Overwrites gameplay fields on the projectile from [member bullet_stats] (tower-owned balance; scenes are VFX-only).
func _apply_projectile_config(bullet_instance: Node) -> void:
	if bullet_instance == null:
		return
	for key in PROJECTILE_GAMEPLAY_KEYS:
		if not bullet_stats.has(key):
			continue
		if not (key in bullet_instance):
			continue
		var v: Variant = bullet_stats[key]
		match key:
			"damage", "speed", "pierce_count", "burn_damage_base", "aoe_range", "pierce_reduction":
				bullet_instance.set(key, int(round(float(v))))
			"burn_duration", "aoe_duration", "aoe_tick":
				bullet_instance.set(key, float(v))
			"dot_damage", "damage_multiplier":
				bullet_instance.set(key, float(v))
			_:
				bullet_instance.set(key, v)


func _apply_base_stats_override() -> void:
	apply_stats_from_db()
	ArmoryManager.apply_buffs_to_tower(self)


func _filter_upgrade_ids(ids: Array[String]) -> Array[String]:
	return ArmoryManager.filter_upgrade_ids(ids)


func _resolve_initial_upgrade_ids() -> void:
	if available_upgrade_ids.is_empty() and not tower_id.is_empty():
		available_upgrade_ids = StatsDB.get_upgrade_ids_for_tower(tower_id)

func _choose_target() -> void:
	var old_target = target
	
	# Filtrer les ennemis pour ne garder que ceux qui sont réellement à portée (avec une petite marge)
	var valid_candidates = enemy_array.filter(func(e): 
		return is_instance_valid(e) and not e.is_already_dead and global_position.distance_to(e.global_position) <= shoot_range + 5.0
	)

	if prefer_non_electrified_targets:
		var non_electrified_enemies: Array[IEnemy] = valid_candidates.filter(
			func(enemy: IEnemy) -> bool:
				return enemy.has_method("is_electrified") and not enemy.is_electrified()
		)
		if not non_electrified_enemies.is_empty():
			_choose_target_from_list(non_electrified_enemies)
			if target != old_target:
				target_lock_time = 0.0
				_cleanup_beams()
			return

	_choose_target_from_list(valid_candidates)
	if target != old_target:
		target_lock_time = 0.0
		_cleanup_beams()

func _cleanup_beams() -> void:
	for beam in _active_beams.keys():
		if is_instance_valid(beam):
			beam.queue_free()
	_active_beams.clear()

func _choose_target_from_list(candidates: Array[IEnemy]) -> void:
	if candidates.is_empty():
		target = null
		return

	match target_type:
		TargetType.FIRST:
			target = candidates[0]
		TargetType.LAST:
			target = candidates[-1]
		TargetType.STRONGEST:
			_get_strongest_target_from_list(candidates)
		TargetType.WEAKEST:
			_get_weakest_target_from_list(candidates)
		TargetType.RANDOM:
			_get_random_target_from_list(candidates)
		_:
			target = candidates[0]

## Function to create the range polygon for the tower when the tower is selected.
## [param radius] - The radius of the range polygon.
## [param precision] - The number of points in the range polygon.
func _create_range_polygon(radius: float, precision: int) -> void:
	## Create an array of Vector2 points for the range polygon
	var points: Array[Vector2] = []
	for i in range(precision):
		var angle = 2 * PI * i / precision
		var x: float = radius * cos(angle)
		var y: float = radius * sin(angle)

		points.append(Vector2(x, y))

	## Set the points, rotation, skew, position, and color of the range polygon
	polygon_2d.polygon = points
	polygon_2d.rotation = collision_shape_2d.rotation
	polygon_2d.skew = collision_shape_2d.skew
	polygon_2d.position = collision_shape_2d.position
	polygon_2d.color = Color(color, 0.3)

	## Set the z-index of the range polygon to 1, making it appear below other nodes
	sprite.z_index = 1

	## Add the first value of points to the end of the array to close the outline
	points.append(Vector2(points[0]))
	outline.points = points

	## Set the width and color of the outline
	outline.width = 3
	outline.default_color = Color(1, 1, 1, 1)

## Function to get the strongest enemy in the enemy array.
func _get_strongest_target():
	_get_strongest_target_from_list(enemy_array)

func _get_strongest_target_from_list(candidates: Array[IEnemy]) -> void:
	## Set the initial strongest enemy to the first enemy in the enemy array
	var strongest: IEnemy = candidates[0]
	## Set the initial health of the strongest enemy to the health of the first enemy in the enemy array
	var strongest_health: float = candidates[0].health
	## Loop through the enemy array to find the enemy with the most health
	for enemies in candidates:
		if enemies.health > strongest_health:
			strongest = enemies
			strongest_health = enemies.health
	## Set the target to the strongest enemy
	target = strongest

## Function to get the weakest enemy in the enemy array.
func _get_weakest_target():
	_get_weakest_target_from_list(enemy_array)

func _get_weakest_target_from_list(candidates: Array[IEnemy]) -> void:
	## Set the initial weakest enemy to the first enemy in the enemy array
	var weakest: IEnemy = candidates[0]
	## Set the initial health of the weakest enemy to the health of the first enemy in the enemy array
	var weakest_health: float = candidates[0].health
	## Loop through the enemy array to find the enemy with the least health
	for enemies in candidates:
		if enemies.health < weakest_health:
			weakest = enemies
			weakest_health = enemies.health
	## Set the target to the weakest enemy
	target = weakest

## Function to get the first enemy in the enemy array.
func _get_first_target():
	_get_first_target_from_list(enemy_array)

func _get_first_target_from_list(candidates: Array[IEnemy]) -> void:
	## Set the target to the first enemy in the enemy array
	target = candidates[0]

## Function to get the last enemy in the enemy array.
func _get_last_target():
	_get_last_target_from_list(enemy_array)

func _get_last_target_from_list(candidates: Array[IEnemy]) -> void:
	## Set the target to the last enemy in the enemy array
	target = candidates[-1]

## Function to get a random enemy in the enemy array.
func _get_random_target():
	_get_random_target_from_list(enemy_array)

func _get_random_target_from_list(candidates: Array[IEnemy]) -> void:
	## Create a RandomNumberGenerator and set the seed to the current time
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	## Generate a random number between 0 and the length of the enemy array
	var num: int = rng.randi_range(0, len(candidates)-1)
	target = candidates[num]

## Function to interpolate between two values.
func _color_variation() -> void:
	## Check if the tower is selected
	if not selected or _cancel_animations or polygon_2d == null:
		return
	## Set the initial lerp state to 1
	var lerp_state: float = 1
	## Loop to interpolate the color of the range polygon
	while lerp_state > 0 and not _cancel_animations:
		polygon_2d.color = lerp(Color(color, 0.3), Color(color, 0), 1-lerp_state)
		await get_tree().create_timer(0.02).timeout
		lerp_state -= 0.05
	## Loop to interpolate the color of the range polygon
	while lerp_state < 1 and not _cancel_animations:
		polygon_2d.color = lerp(Color(color, 0), Color(color, 0.3), lerp_state)
		await get_tree().create_timer(0.02).timeout
		lerp_state += 0.05

	if not _cancel_animations:
		## Call the function to interpolate the color of the range polygon
		_color_variation()

## Function to check the z position of the tower and adapt the z index of the tower.
func _update_z_index() -> void:
	var y_position := int(global_position.y)
	z_index = y_position if y_position else 0
	polygon_2d.z_index = z_index

# Signal callbacks
func _on_area_2d_body_entered(body: Node) -> void:
	if body is IEnemy:
		enemy_array.append(body)

func _on_area_2d_body_exited(body: Node) -> void:
	if body is IEnemy:
		enemy_array.erase(body)

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area is IBullet and area in get_children():
		area.queue_free()

func _on_tower_hover_box_mouse_entered() -> void:
	if Global.paused:
		return
	if _menu_open:
		return
	show_range(true)

func _on_tower_hover_box_mouse_exited() -> void:
	if Global.paused:
		return
	if _menu_open:
		return
	show_range(false)

func _on_timer_timeout() -> void:
	$ProgressBar.value += 1
	if $ProgressBar.value >= $ProgressBar.max_value:
			apply_upgrade()
			$Timer.stop()
			$ProgressBar.visible = false

func _on_tower_pressed() -> void:
	Log.trace(Log.Level.DEBUG, "Tower Pressed")
	if Global.paused:
		return

	if state != TowerState.ACTIVE:
		return

	if self.find_child("TowerUpgrade", true, false) != null:
		Log.trace(Log.Level.DEBUG, "Tower upgrade menu already exists")
		return

	var tower_upgrade_menu : PackedScene = load("res://scenes/ui/menus/tower_upgrade/radial_menu_tower_upgrade.tscn")
	if tower_upgrade_menu == null :
		Log.trace(Log.Level.ERROR, "Failed to load tower upgrade menu scene")
		return

	var tower_upgrade_menu_instance: Control = tower_upgrade_menu.instantiate()
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
