class_name IUpgrade
extends Node2D

@export var change: Dictionary = {
									 "bullet_stat": false,
									 "tower_stat": false,
									 "tower": false
								 }

@export var bulletStats: Dictionary = {
										  "damage": 0.0,
										  "speed": 0.0,
										  "piercing": 0.0,
										  "pierce_reduction": 0.0,
										  "damage_multiplier": 0.0,
										  "aoe_range": 0.0,
										  "dot_damage": 0.0,
										  "dot_duration": 0.0,
										  "dot_tick": 0.0,
									  } # {stat: float}

@export var towerStats: Dictionary = {
										 "level": 0,
										 "shoot_range": 0.0,
										 "fire_rate": 0.0,
									 } # {stat: float}

@export var cannon: PackedScene # if a new cannon is needed
@export var tower: PackedScene # if a new tower sprite is needed
@export var price: int
