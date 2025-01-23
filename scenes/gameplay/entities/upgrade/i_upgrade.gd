## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Defines the interface for an upgrade that can be applied to a tower.
class_name IUpgrade
extends Node2D

## Defines which aspects of the tower can be upgraded
enum UpgradeType {
	BULLET_STAT, ## Modifies bullet statistics
	TOWER_STAT, ## Modifies tower statistics
	TOWER_MODEL, ## Changes the tower's visual model
}

## Configuration of which aspects will be modified by this upgrade
@export var changes: Dictionary = {
	"tower_stat": false, ## Whether tower stats will be modified
	"tower_model": false, ## Whether tower model will be changed
	"bullet_stat": false, ## Whether bullet stats will be modified
	"bullet_model": false, ## Whether bullet model will be changed
}

## Bullet statistics modification values
@export var bullet_stats: Dictionary = {
	"damage": 0.0, ## Base damage increase
	"speed": 0.0, ## Projectile speed modifier
	"piercing": 0.0, ## Armor penetration value
	"pierce_reduction": 0.0, ## Reduction in piercing effectiveness
	"damage_multiplier": 0.0, ## Damage multiplication factor
	"aoe_range": 0.0, ## Area of effect range
	"dot_damage": 0.0, ## Damage over time amount
	"dot_duration": 0.0, ## Duration of damage over time effect
	"dot_tick": 0.0, ## Interval between damage ticks
}

## Tower statistics modification values
@export var tower_stats: Dictionary = {
	"level": 0, ## Tower upgrade level
	"shoot_range": 0.0, ## Attack range modifier
	"fire_rate": 0.0, ## Attack speed modifier
}

## The nexts upgrades available after this one
@export var next_upgrades: Array[PackedScene]

## New tower model texture to replace the current one
@export var tower: Texture

## New bullet model scene to replace the current one
@export var bullet: PackedScene

## Cost of applying this upgrade
@export var price: int

## Validates that the upgrade configuration is correct.
func _ready() -> void:
	assert(price >= 0, "Upgrade price must be non-negative")
