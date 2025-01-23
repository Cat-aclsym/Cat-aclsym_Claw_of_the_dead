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
}

# Exported variables
## The bullet scene to be instantiated by the tower
@export var bullet_scene: PackedScene = null

## The bullet stats to be applied to the bullet
@export var bullet_stats: Dictionary = {
	"damage": 0.0,
	"speed": 0.0,
	"piercing": 0.0,
	"piercing_reduction": 0.0,
	"damage_multiplier": 0.0,
	"aoe_range": 0.0,
	"dot_damage": 0.0,
	"aoe_duration": 0.0,
	"aoe_tick": 0.0,
}

## The cost of the tower
@export var cost: int
## The fire rate of the tower
@export var fire_rate: float
## The level of the tower
@export var level: int
## The sell price of the tower
@export var sell_price: int
## The shooting range of the tower
@export var shoot_range: float
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
@onready var sprite_2d: Sprite2D = $Sprite2D

# Variables
## The color of the range polygon
var color: String = "#FFFFFF"
## The enemy array to store enemies in the range of the tower
var enemy_array: Array[IEnemy]
## Is the tower is selected
var selected: bool = false
## The state of the tower
var state: TowerState = TowerState.ACTIVE
## The target of the tower
var target: IEnemy
## The type of target the tower will shoot at
var target_type: TargetType
## The pending upgrade to be applied
var pending_upgrade: PackedScene

# Core methods
func _ready() -> void:
	target_type = TargetType.FIRST
	hover_box.z_index = 3
	update_dependent_properties()

func _process(_delta: float) -> void:
	if Global.paused:
		return

	if state == TowerState.BUILDING:
		_update_z_index()
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
	var bullet_instance: IBullet = bullet_scene.instantiate()

	bullet_instance.direction = global_position.direction_to(enemy_position)
	bullet_instance.rotation = bullet_instance.direction.angle()
	bullet_instance.target = enemy_position

	_apply_bullet_modifications(bullet_instance)
	add_child(bullet_instance)
	fire_rate_timer.start()

## Starts the upgrade process with the given upgrade scene
func start_upgrade(upgradeScene: PackedScene) -> void:
	pending_upgrade = upgradeScene
	state = TowerState.UPGRADING
	$ProgressBar.value = 0
	$ProgressBar.visible = true
	$Timer.start()
	emit_signal("upgrade_started")

## Applies the pending upgrade to the tower
func apply_upgrade() -> void:
	var upgrade: IUpgrade = pending_upgrade.instantiate()
	
	Log.trace(Log.Level.DEBUG, "Applying upgrade: {0}".format([pending_upgrade]))

	if upgrade.changes["tower_stat"]:
		_apply_tower_stat_changes(upgrade)
	
	if upgrade.changes["bullet_stat"]:
		_apply_bullet_stat_changes(upgrade)
	
	if upgrade.changes["tower_model"] and upgrade.tower != null:
		sprite_2d.texture = upgrade.tower

	if upgrade.changes["bullet_model"] and upgrade.bullet != null:
		bullet_scene = upgrade.bullet

	available_upgrade = upgrade.next_upgrades
	update_dependent_properties()
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

## Builds the tower
func build_tower() -> void:
	pass

## Sells the tower
func sell_tower() -> void:
	pass

# Private methods
func _apply_tower_stat_changes(upgrade: IUpgrade) -> void:
	for stat in upgrade.tower_stats.keys():
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
	sprite_2d.z_index = 1

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
	if not selected:
		return
	## Set the initial lerp state to 1
	var lerp_state: float = 1
	## Loop to interpolate the color of the range polygon
	while lerp_state > 0:
		polygon_2d.color = lerp(Color(color, 0.3), Color(color, 0), 1-lerp_state)
		await get_tree().create_timer(0.02).timeout
		lerp_state -= 0.05
	## Loop to interpolate the color of the range polygon
	while lerp_state < 1:
		polygon_2d.color = lerp(Color(color, 0), Color(color, 0.3), lerp_state)
		await get_tree().create_timer(0.02).timeout
		lerp_state += 0.05

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
	selected = true
	var size: float = 0
	while size < 1:
		polygon_2d.scale = lerp(polygon_2d.scale, Vector2(1, 1), size)
		await get_tree().create_timer(0.01).timeout
		size += 0.1
		_color_variation()

func _on_tower_hover_box_mouse_exited() -> void:
	selected = false
	var size: float = 0
	while size < 1:
		polygon_2d.scale = lerp(polygon_2d.scale, Vector2(0, 0), size)
		await get_tree().create_timer(0.01).timeout
		size += 0.1

func _on_timer_timeout() -> void:
	$ProgressBar.value += 1
	if $ProgressBar.value >= $ProgressBar.max_value:
			apply_upgrade()
			$Timer.stop()
			$ProgressBar.visible = false
