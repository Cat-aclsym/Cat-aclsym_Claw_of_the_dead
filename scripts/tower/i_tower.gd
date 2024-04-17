class_name ITower
extends Node2D

enum TargetType {
	FIRST,
	LAST,
	STRONGEST,
	WEAKEST,
	RANDOM
}
enum TowerState {
	BUILDING,
	UPGRADE
}
@export var cost: int
@export var sell_price: int
@export var upgrade: Array[PackedScene] #IUpgrade
@export var level: int
@export var shoot_range: float
@export var fire_rate: float
@export var BulletScene: PackedScene = null

@onready var fire_rate_timer := $FireRateTimer as Timer
@onready var area_2d := $Area2D as Area2D
@onready var collision_shape_2d := $Area2D/CollisionShape2D as CollisionShape2D
@onready var polygon_2d := $Polygon2D as Polygon2D
@onready var sprite_2d := $Sprite2D as Sprite2D
@onready var hover_box := $TowerHoverBox/CollisionShape2D as CollisionShape2D
@onready var outline := $Polygon2D/Line2D as Line2D


var target_type: TargetType
var state: TowerState
var enemy_array: Array[IEnemy]
var target: IEnemy
var color = "#FFFFFF"
var selected = false

func _ready():
	state = TowerState.BUILDING
	target_type = TargetType.FIRST
	collision_shape_2d.shape.radius = shoot_range

	hover_box.z_index = 3
	_create_range_polygon(shoot_range, 50)


func _process(_delta: float) -> void:
	if fire_rate_timer.is_stopped():
		fire()

	
func _range_on_hover(delta):
	pass

func _create_range_polygon(radius: float, precision: int) -> void:	
	var points: Array[Vector2] = []
	for i in range(precision):
		var angle = 2 * PI * i / precision
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		points.append(Vector2(x, y))
	polygon_2d.polygon = points
	polygon_2d.rotation = collision_shape_2d.rotation
	polygon_2d.skew = collision_shape_2d.skew
	polygon_2d.position = collision_shape_2d.position
	sprite_2d.z_index = 1
	polygon_2d.color = Color(color, 0.3)
	points.append(Vector2(points[0]))
	outline.points = points
	outline.width = 3
	outline.default_color = Color(1, 1, 1, 1)
	
	

func _on_area_2d_body_entered(body) -> void:
	if body is IEnemy:
		enemy_array.append(body)


func _on_area_2d_body_exited(body) -> void:
	if body is IEnemy:
		enemy_array.erase(body)


func fire() -> void:
	if !len(enemy_array):
		return
	if BulletScene == null:
		return

	var enemy_position: Vector2  = enemy_array[0].global_position
	var bullet_instance: IBullet = BulletScene.instantiate()

	bullet_instance.direction = global_position.direction_to(enemy_position)
	bullet_instance.rotation = bullet_instance.direction.angle()
	bullet_instance.target = enemy_position
	add_child(bullet_instance)
	fire_rate_timer.start()


func upgrade_tower():
	pass


func build_tower():
	pass


func sell_tower():
	pass


func _choose_target():
	pass


func _get_strongest_target():
	var strongest = enemy_array[0]
	var strongest_health = enemy_array[0].health
	for enemies in enemy_array:
		if enemies.health > strongest_health:
			strongest = enemies
			strongest_health = enemies.health
	target = strongest


func _get_weakest_target():
	var weakest = enemy_array[0]
	var weakest_health = enemy_array[0].health
	for enemies in enemy_array:
		if enemies.health < weakest_health:
			weakest = enemies
			weakest_health = enemies.health
	target = weakest


func _get_first_target():
	target = enemy_array[0]


func _get_last_target():
	target = enemy_array[-1]


func _get_random_target():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var num = rng.randi_range(0, len(enemy_array))
	target = enemy_array[num]


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area is IBullet && area in get_children():
		area.queue_free()


func _on_tower_hover_box_mouse_entered():
	selected = true
	var size = 0
	while size < 1:
		polygon_2d.scale = lerp(polygon_2d.scale, Vector2(1, 1), size)
		await get_tree().create_timer(0.01).timeout
		size += 0.1
		_color_variation()

func _color_variation():
	if !selected:
		return
	var lerp_state = 1
	while lerp_state > 0:
		polygon_2d.color = lerp(Color(color, 0.3), Color(color, 0), 1-lerp_state)
		await get_tree().create_timer(0.02).timeout
		lerp_state -= 0.05
	
	while lerp_state < 1:
		polygon_2d.color = lerp(Color(color, 0), Color(color, 0.3), lerp_state)
		await get_tree().create_timer(0.02).timeout
		lerp_state += 0.05
		
	_color_variation()


func _on_tower_hover_box_mouse_exited():
	selected = false
	var size = 0
	while size < 1:
		polygon_2d.scale = lerp(polygon_2d.scale, Vector2(0, 0), size)
		await get_tree().create_timer(0.01).timeout
		size += 0.1
