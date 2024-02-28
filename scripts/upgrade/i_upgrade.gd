class_name IUpgrade
extends Node2D

@export var change: Dictionary = {
									 "bullet_stat": false,
									 "cannon_stat": false,
									 "tower_stat": false,
									 "cannon": false,
									 "tower": false
								 }

@export var bulletStats: Dictionary = {
										  "damage": 0.0,
										  "speed": 0.0,
									  } # {stat: float}

@export var cannonStats: Dictionary = {
										  "range": 0.0,
										  "fire_rate": 0.0,
									  } # {stat: float

@export var towerStats: Dictionary = {
										 "level": 0,
									 } # {stat: float}

@export var cannon: PackedScene # if a new cannon is needed
@export var tower: PackedScene # if a new tower sprite is needed
@export var price: int
