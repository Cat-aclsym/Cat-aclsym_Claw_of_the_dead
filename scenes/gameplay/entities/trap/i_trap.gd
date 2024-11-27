## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Interface for a trap.
class_name ITrap
extends Node2D

## Enum for the state of the trap
enum TrapState {
    BUILDING, ## The trap is being built
    ACTIVE, ## The trap is placed and active
}

## The cost of the trap
@export var cost: int

## The area 2D node for the trap to detect enemies
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D

## The state of the trap
var state: TrapState = TrapState.ACTIVE

# core
func _ready():
    collision_shape_2d.shape.size = Vector2(64, 64) # Adjust size as needed
    _update_z_index()

func _process(_delta: float) -> void:
    if Global.paused:
        return
        
    if state == TrapState.BUILDING:
        _update_z_index()
        return

# private
func _update_z_index() -> void:
    var y_position := int(global_position.y)
    z_index = (y_position / 2) - 10

# signal
func _on_area_2d_body_entered(body) -> void:
    if body is IEnemy and state == TrapState.ACTIVE:
        apply_effect(body)

func _on_area_2d_body_exited(body) -> void:
    if body is IEnemy and state == TrapState.ACTIVE:
        remove_effect(body)

## Override these methods in specific trap implementations
func apply_effect(_enemy: IEnemy) -> void:
    pass

func remove_effect(_enemy: IEnemy) -> void:
    pass 