## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Interface for a tower.
class_name ITower
extends Node2D

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


# Exported variables
@export_subgroup("Bullet Configuration")
## The bullet scene to be instantiated by the tower
@export var bullet_scene: PackedScene = null

## The bullet stats to be applied to the bullet (overridden at runtime from StatsDB)
var bullet_stats: Dictionary = {}

@export_subgroup("Multi-Shot Properties")
## The number of projectiles to fire simultaneously (overridden at runtime)
var projectile_count: int = 0
## The angle spread between multiple projectiles (in degrees) (overridden at runtime)
var spread_angle: float = 0.0

@export_subgroup("Tower Properties")
## The cost of the tower (overridden at runtime)
var cost: int = 0
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

## Dictionary of modifiers applied to this tower (stat_name -> multiplier)
var _special_modifiers: Dictionary = {}

@export_subgroup("Upgrades")
## The upgrade array to store upgrades that are applied in the tower
@export var available_upgrade: Array[PackedScene]

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
## The sprite 2D node for the tower to display the tower model
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
# @onready var sprite_2d: Sprite2D = $Sprite2D
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
## The type of target the tower will shoot at
var target_type: TargetType
## The pending upgrade to be applied
var pending_upgrade: PackedScene
## The tile position of the tower on the map
var tile_pos: Vector2i
var _pulse_tween: Tween = null
var _scale_tween: Tween = null
var _range_tween: Tween = null
@onready var stats_db = get_node("/root/StatsDB")
@export var tower_id: String = ""

# Core methods
func _ready() -> void:
	target_type = TargetType.FIRST
	_apply_base_stats_override()
	sell_price = ceil(cost / 2.0)
	hover_box.z_index = 3
	update_dependent_properties()
	# Sync range visibility with selected state (especially for duplicated towers)
	show_range(selected, false)
	
	if state == TowerState.ACTIVE:
		call_deferred("_register_with_cursor")
		
	if animated_sprite_2d and animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("idle"):
		animated_sprite_2d.play("idle")
	SignalUtil.connects(signals)

func _process(_delta: float) -> void:
	if Global.paused:
		return

	if state == TowerState.BUILDING:
		_update_z_index()
		# Allow range display even during building
		return

	if fire_rate_timer.is_stopped():
		fire()

# Public methods
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
		var bullet_instance: IBullet = bullet_scene.instantiate()

		# Calculate angle for this projectile
		var current_angle: float = start_angle + (spread_angle * i)
		var rotated_direction: Vector2 = base_direction.rotated(deg_to_rad(current_angle))

		bullet_instance.direction = rotated_direction
		bullet_instance.rotation = rotated_direction.angle()
		bullet_instance.target = enemy_position
		
		# Set tower owner to allow reward multiplier logic
		if "tower_owner" in bullet_instance:
			bullet_instance.tower_owner = self

		_apply_bullet_modifications(bullet_instance)
		add_child(bullet_instance)

	fire_rate_timer.start()

## Starts the upgrade process with the given upgrade scene
func start_upgrade(upgradeScene: PackedScene) -> void:
	var upgrade: IUpgrade = upgradeScene.instantiate()
	if ILevel.current_level.coins < upgrade.price:
		Log.trace(Log.Level.ERROR, "Not enough coins to upgrade")
		return
	pending_upgrade = upgradeScene
	state = TowerState.UPGRADING
	$ProgressBar.value = 0
	$ProgressBar.visible = true
	$Timer.start()
	emit_signal("upgrade_started")

## Applies the pending upgrade to the tower
func apply_upgrade() -> void:
	var upgrade: IUpgrade = pending_upgrade.instantiate()

	if upgrade.changes["tower_stat"]:
		_apply_tower_stat_changes(upgrade)

	if upgrade.changes["bullet_stat"]:
		_apply_bullet_stat_changes(upgrade)

	if upgrade.changes["tower_model"] and upgrade.tower != null:
		if upgrade.tower is Texture2D:
			if animated_sprite_2d.sprite_frames != null and animated_sprite_2d.sprite_frames.has_animation("idle"):
				var idle_anim = animated_sprite_2d.sprite_frames.get_animation("idle")
				# Determine frame index: 0 to add if empty, or last frame index to update
				var frame_idx = 0
				if idle_anim.get_frame_count() > 0:
					frame_idx = idle_anim.get_frame_count() - 1

				idle_anim.set_frame_texture(frame_idx, upgrade.tower)

				if not animated_sprite_2d.is_playing() or animated_sprite_2d.animation != "idle":
					animated_sprite_2d.play("idle")
			else: # upgrade.tower is Texture2D, but no 'idle' animation or no sprite_frames
				var reason = "'idle' animation missing"
				if animated_sprite_2d.sprite_frames == null:
					reason = "no sprite_frames assigned"
				elif not animated_sprite_2d.sprite_frames.has_animation("idle"):
					reason = "'idle' animation missing" # Redundant but clear
				Log.trace(Log.Level.WARN, "Cannot apply tower_model texture: %s in AnimatedSprite2D." % reason)
		else: # upgrade.tower is not Texture2D (and not null)
			Log.trace(Log.Level.ERROR, "upgrade.tower for tower_model is not a Texture2D as expected. Type: %s" % typeof(upgrade.tower))

	if upgrade.changes["bullet_model"] and upgrade.bullet != null:
		bullet_scene = upgrade.bullet

	available_upgrade = upgrade.next_upgrades
	sell_price += ceil(upgrade.price / 2.0)
	update_dependent_properties()
	level += 1
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
		if animated_sprite_2d:
			animated_sprite_2d.modulate = Color.WHITE
			animated_sprite_2d.scale = Vector2(1, 1)
		elif sprite_2d:
			sprite_2d.modulate = Color.WHITE
			sprite_2d.scale = Vector2(1, 1)
		else:
			self.modulate = Color.WHITE
			self.scale = Vector2(1, 1)
		return
		
	var effect_color = modifier["color"]
	effect_color.a = 1.0 # Force full opacity for the color tint
	
	# Create a dedicated tween for the visual effect
	_pulse_tween = create_tween().set_loops()
	
	# Pulse only the color between normal (White) and the modifier color (Solid Tint)
	# No scale/zoom effect as requested
	if animated_sprite_2d:
		_pulse_tween.tween_property(animated_sprite_2d, "modulate", effect_color, 1.0).set_trans(Tween.TRANS_SINE)
		_pulse_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 1.0).set_trans(Tween.TRANS_SINE)
	elif sprite_2d:
		_pulse_tween.tween_property(sprite_2d, "modulate", effect_color, 1.0).set_trans(Tween.TRANS_SINE)
		_pulse_tween.tween_property(sprite_2d, "modulate", Color.WHITE, 1.0).set_trans(Tween.TRANS_SINE)
	else:
		# Fallback to the whole node
		_pulse_tween.tween_property(self, "modulate", effect_color, 1.0).set_trans(Tween.TRANS_SINE)
		_pulse_tween.tween_property(self, "modulate", Color.WHITE, 1.0).set_trans(Tween.TRANS_SINE)
	
	# Add a small scale effect only to the tower sprite
	_scale_tween = create_tween()
	var target_sprite: Node2D = null
	if animated_sprite_2d:
		target_sprite = animated_sprite_2d
	elif sprite_2d:
		target_sprite = sprite_2d
	
	if target_sprite:
		if modifier["label"].ends_with("-"):
			_scale_tween.tween_property(target_sprite, "scale", Vector2(0.85, 0.85), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			_scale_tween.tween_property(target_sprite, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		# Fallback to the whole node if no sprite is found
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
	var placement_system = Global.get("cursor")
	if placement_system:
		placement_system.remove_invalid_cell(tile_pos)
	queue_free()

func _register_with_cursor() -> void:
	if not is_inside_tree():
		return
		
	# Safe access to Global.cursor to avoid assertion if it's not yet set
	var placement_system = Global.get("cursor")
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

func _apply_tower_stat_changes(upgrade: IUpgrade) -> void:
	for stat in upgrade.tower_stats.keys():
		if stat == "level":
			continue
		if self.get(stat):
			Log.trace(Log.Level.DEBUG, "Modifying stat: {0} by {1}".format([stat, upgrade.tower_stats[stat]]))
			self.set(stat, self.get(stat) + upgrade.tower_stats[stat])

func _apply_bullet_stat_changes(upgrade: IUpgrade) -> void:
	for stat in upgrade.bullet_stats.keys():
		if bullet_stats.has(stat):
			bullet_stats[stat] += upgrade.bullet_stats[stat]

func _apply_bullet_modifications(bullet_instance: IBullet) -> void:
	if bullet_instance == null:
		return

	bullet_instance.damage += bullet_stats["damage"]
	bullet_instance.speed += bullet_stats["speed"]


func _apply_base_stats_override() -> void:
	if tower_id.is_empty() or stats_db == null:
		return
	if not stats_db.has_tower(tower_id):
		Log.trace(Log.Level.ERROR, "StatsDB missing tower id: %s" % tower_id)
		return
	var data: Dictionary = stats_db.get_tower(tower_id)
	var base: Dictionary = data.get("base", {})
	level = stats_db.get_tower_level(tower_id)
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

func _choose_target() -> void:
	match target_type:
		TargetType.FIRST:
			_get_first_target()
		TargetType.LAST:
			_get_last_target()
		TargetType.STRONGEST:
			_get_strongest_target()
		TargetType.WEAKEST:
			_get_weakest_target()
		TargetType.RANDOM:
			_get_random_target()

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
	animated_sprite_2d.z_index = 1

	## Add the first value of points to the end of the array to close the outline
	points.append(Vector2(points[0]))
	outline.points = points

	## Set the width and color of the outline
	outline.width = 3
	outline.default_color = Color(1, 1, 1, 1)

## Function to get the strongest enemy in the enemy array.
func _get_strongest_target():
	## Set the initial strongest enemy to the first enemy in the enemy array
	var strongest: IEnemy = enemy_array[0]
	## Set the initial health of the strongest enemy to the health of the first enemy in the enemy array
	var strongest_health: float = enemy_array[0].health
	## Loop through the enemy array to find the enemy with the most health
	for enemies in enemy_array:
		if enemies.health > strongest_health:
			strongest = enemies
			strongest_health = enemies.health
	## Set the target to the strongest enemy
	target = strongest

## Function to get the weakest enemy in the enemy array.
func _get_weakest_target():
	## Set the initial weakest enemy to the first enemy in the enemy array
	var weakest: IEnemy = enemy_array[0]
	## Set the initial health of the weakest enemy to the health of the first enemy in the enemy array
	var weakest_health: float = enemy_array[0].health
	## Loop through the enemy array to find the enemy with the least health
	for enemies in enemy_array:
		if enemies.health < weakest_health:
			weakest = enemies
			weakest_health = enemies.health
	## Set the target to the weakest enemy
	target = weakest

## Function to get the first enemy in the enemy array.
func _get_first_target():
	## Set the target to the first enemy in the enemy array
	target = enemy_array[0]

## Function to get the last enemy in the enemy array.
func _get_last_target():
	## Set the target to the last enemy in the enemy array
	target = enemy_array[-1]

## Function to get a random enemy in the enemy array.
func _get_random_target():
	## Create a RandomNumberGenerator and set the seed to the current time
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	## Generate a random number between 0 and the length of the enemy array
	var num: int = rng.randi_range(0, len(enemy_array)-1)
	target = enemy_array[num]

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
	if _menu_open:
		return
	show_range(true)

func _on_tower_hover_box_mouse_exited() -> void:
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
