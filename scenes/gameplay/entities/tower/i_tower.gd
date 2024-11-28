## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Interface for a tower.
class_name ITower
extends Node2D


## Enum for the type of target the tower will shoot at
enum TargetType {
	FIRST, ## Shoots at the first enemy that enters the range
	LAST, ## Shoots at the last enemy that enters the range
	STRONGEST, ## Shoots at the enemy with the most health
	WEAKEST, ## Shoots at the enemy with the least health
	RANDOM ## Shoots at a random enemy
}

## Enum for the state of the tower
enum TowerState {
	BUILDING, ## The tower is being built
	UPGRADING, ## The tower is being upgraded
	ACTIVE, ## The tower is placed and active
}

## The bullet scene to be instantiated by the tower
@export var bullet_scene: PackedScene = null

@export var bullet_stats: Dictionary = {
	"damage": 0.0,
	"speed": 0.0,
	"piercing": 0.0,
	"piercing_reduction": 0.0,
	"aoe_range": 0.0,
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


# core
func _ready():
	## Set the initial target type of the tower to FIRST
	target_type = TargetType.FIRST
	## Set the z-index of the hover box to 3, making it appear above other nodes
	hover_box.z_index = 3
	update_dependent_properties()


func _process(_delta: float) -> void:
	if Global.paused:
		return

	if state == TowerState.BUILDING:
		_update_z_index()
		return

	## If the fire rate timer is stopped, call the fire function
	if fire_rate_timer.is_stopped():
		fire()

# public
## Function to fire a bullet at the target.
func fire() -> void:
	## If there are no enemies in the enemy array or the bullet_scene is null, return
	if not len(enemy_array):
		return
	## Security check for bullet_scene
	if bullet_scene == null:
		Log.trace(Log.Level.ERROR, "Missing bullet scene")
		return

	## Switch statement to determine the target based on the target type
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

	if not target:
		Log.trace(Log.Level.WARN, "Failed to retrieve target")
		return

	## Get the global position of the target and instantiate a bullet
	var enemy_position: Vector2 = target.global_position
	var bullet_instance: IBullet = bullet_scene.instantiate()
	
	# Applique les modifications de la tour à la balle
	_apply_bullet_modifications(bullet_instance)

	## Set the direction, rotation, and target of the bullet
	bullet_instance.direction = global_position.direction_to(enemy_position)
	bullet_instance.rotation = bullet_instance.direction.angle()
	bullet_instance.target = enemy_position
	##  Add the bullet to the scene tree
	add_child(bullet_instance)
	## Start the fire rate timer
	fire_rate_timer.start()

func apply_upgrade(upgradeScene: PackedScene) -> void:
	var upgrade: IUpgrade = upgradeScene.instantiate()

	Log.trace(Log.Level.DEBUG, "Applying upgrade: {0}".format([upgradeScene]))

	# Vérifie si les statistiques de la tour doivent être modifiées
	if upgrade.changes["tower_stat"]:
		for stat in upgrade.tower_stats.keys():
			if self.get(stat):
				Log.trace(Log.Level.DEBUG, "Modifying stat: {0} by {1}".format([stat, upgrade.tower_stats[stat]]))
				self.set(stat, self.get(stat) + upgrade.tower_stats[stat])

	# Vérifie si les statistiques des projectiles doivent être modifiées
	if upgrade.changes["bullet_stat"]:
		for stat in upgrade.bullet_stats.keys():
			if bullet_stats.has(stat):
				bullet_stats[stat] += upgrade.bullet_stats[stat]

	# Vérifie si le modèle de la tour doit être remplacé
	if upgrade.changes["tower"]:
		if upgrade.tower != null:
			sprite_2d.texture = upgrade.tower.instance() # Remplace le modèle

	update_dependent_properties()

	#Met la nouvelle upgrade disponible dans la liste des upgrades
	available_upgrade = upgrade.next_upgrades

func update_dependent_properties() -> void:
	# Met à jour le radius de la collision shape
	if collision_shape_2d.shape is CircleShape2D:
		collision_shape_2d.shape.radius = shoot_range

	# Réactualise le polygone de portée
	_create_range_polygon(shoot_range, 50)

	# Calcul du temps d'attente du Timer en fonction de fire_rate
	if fire_rate_timer != null:
		if fire_rate > 0:  # Évite une division par zéro
			fire_rate_timer.wait_time = 1.0 / fire_rate
		else:
			fire_rate_timer.wait_time = 1.0  # Valeur par défaut si fire_rate <= 0

		# Redémarre le Timer si nécessaire
		if fire_rate_timer.is_stopped():
			fire_rate_timer.start()

	# Met à jour d'autres propriétés visuelles
	_update_z_index()
	
func _apply_bullet_modifications(bullet_instance: IBullet) -> void:
	if bullet_instance == null:
		return

	# Transfert des statistiques
	bullet_instance.damage += bullet_stats["damage"]
	bullet_instance.speed += bullet_stats["speed"]

 


func build_tower():
	pass


func sell_tower():
	pass


func _choose_target():
	pass


# private
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


# signal
## Function to detect when an enemy enters the range of the tower.
## @param body Object - The object that entered the range of the tower.
func _on_area_2d_body_entered(body) -> void:
	## If the object is an IEnemy, add it to the enemy array
	if body is IEnemy:
		enemy_array.append(body)


## Function to detect when an enemy exits the range of the tower.
## @param body Object - The object that exited the range of the tower.
func _on_area_2d_body_exited(body) -> void:
	## If the object is an IEnemy, remove it from the enemy array
	if body is IEnemy:
		enemy_array.erase(body)


## Function to interpolate between two values.
## @param a float - The first value.
func _on_area_2d_area_exited(area: Area2D) -> void:
	## If the area is an IBullet and is in the range of the tower, queue free the area
	if area is IBullet && area in get_children():
		area.queue_free()


## Function to interpolate between two values.
func _on_tower_hover_box_mouse_entered():
	## Set the selected boolean to true
	selected = true
	## Set the size of the range polygon to 0
	var size: float = 0
	## Loop to interpolate the size of the range polygon to 1
	while size < 1:
		polygon_2d.scale = lerp(polygon_2d.scale, Vector2(1, 1), size)
		await get_tree().create_timer(0.01).timeout
		size += 0.1
		_color_variation()


## Function to stop the color variation when the mouse exits the hover box.
func _on_tower_hover_box_mouse_exited():
	## Set the selected boolean to false
	selected = false
	## Set the size of the range polygon to 0
	var size: float = 0
	## Loop to interpolate the size of the range polygon to 0 to hide the range polygon
	while size < 1:
		polygon_2d.scale = lerp(polygon_2d.scale, Vector2(0, 0), size)
		await get_tree().create_timer(0.01).timeout
		size += 0.1
