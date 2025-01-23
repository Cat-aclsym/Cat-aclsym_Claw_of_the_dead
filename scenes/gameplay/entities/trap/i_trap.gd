## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Interface for a trap.
class_name ITrap
extends Node2D

## Enum for the type of trap behavior
enum TrapType {
    PASSIVE, ## Effect is continuously applied while enemy is on trap
    ACTIVE, ## Effect is triggered by first enemy then has cooldown
    LIMITED ## Effect is triggered by first enemy then has limited durability
}

## Enum for the state of the trap
enum TrapState {
    BUILDING, ## The trap is being built
    ACTIVE, ## The trap is placed and active
}

## The cost of the trap
@export var cost: int

## The size of the trap in tiles (1x1, 2x2, etc.)
@export var size: Vector2i = Vector2i(1, 1)

## The type of trap behavior
@export var trap_type: TrapType = TrapType.PASSIVE

## Cooldown time for ACTIVE type (in seconds)
@export var cooldown_time: float = 3.0

## Effect duration for ACTIVE type (in seconds)
@export var effect_duration: float = 2.0

## Maximum durability for LIMITED type
@export var max_durability: int = 3

## Base tile size in pixels
const TILE_SIZE: int = 64

## The state of the trap
var state: TrapState = TrapState.ACTIVE

## Current cooldown timer for ACTIVE type
var current_cooldown: float = 0.0

## Current effect duration timer for ACTIVE type
var current_effect_duration: float = 0.0

## Current durability for LIMITED type
var current_durability: int

## Whether the trap is currently active (for ACTIVE and LIMITED types)
var is_usable: bool = true

## Enemy currently affected by ACTIVE type trap
var active_affected_enemy: IEnemy = null

## List of enemies currently in the trap area
var enemies_in_area: Array[IEnemy] = []

## The area 2D node for the trap to detect enemies
@onready var area_2d: Area2D = $Area2D
@onready var collision_polygon: CollisionPolygon2D = $Area2D/CollisionPolygon2D
@onready var sprite_2d: Sprite2D = $Sprite2D

## Signal connections to be established in _ready
@onready var signals: Array[Dictionary] = [
    {SignalUtil.WHO: area_2d, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_area_2d_body_entered},
    {SignalUtil.WHO: area_2d, SignalUtil.WHAT: "body_exited", SignalUtil.TO: _on_area_2d_body_exited}
]

## Dictionary to track enemies affected by LIMITED type with their remaining effect duration
var active_affected_enemies: Dictionary

# core
func _ready():
    _update_z_index()
    SignalUtil.connects(signals)
    current_durability = max_durability
    active_affected_enemies = {}

func _process(delta: float) -> void:
    if Global.paused:
        return
        
    if state == TrapState.BUILDING:
        _update_z_index()
        return

    # Handle cooldown for ACTIVE type
    if trap_type == TrapType.ACTIVE:
        if not is_usable:
            current_cooldown -= delta
            if current_cooldown <= 0:
                is_usable = true
        
        # Handle effect duration for ACTIVE type
        if active_affected_enemy != null:
            current_effect_duration -= delta
            if current_effect_duration <= 0:
                remove_effect(active_affected_enemy)
                active_affected_enemy = null
    
    # Update opacity for LIMITED type and handle effect duration
    elif trap_type == TrapType.LIMITED:
        if is_usable:
            # Calculate opacity based on remaining durability (100% to 20%)
            var opacity := (0.8 * (float(current_durability) / float(max_durability))) + 0.2
            modulate.a = opacity
            
            # Gérer la durée d'effet pour chaque ennemi
            var to_remove := []
            for enemy in active_affected_enemies:
                active_affected_enemies[enemy] -= delta
                if active_affected_enemies[enemy] <= 0:
                    if enemy in enemies_in_area:  # Si l'ennemi est toujours sur le piège
                        active_affected_enemies[enemy] = effect_duration  # Reset duration
                    else:
                        remove_effect(enemy)
                        to_remove.append(enemy)
            
            # Nettoyer les ennemis dont l'effet est terminé
            for enemy in to_remove:
                active_affected_enemies.erase(enemy)
        else:
            # Retirer l'effet sur tous les ennemis avant de détruire le piège
            for enemy in active_affected_enemies.keys():
                if enemy != null:  # Vérifier que l'ennemi existe toujours
                    remove_effect(enemy)
            active_affected_enemies.clear()  # Vider le dictionnaire
            queue_free()

# private
func _update_z_index() -> void:
    var y_position := int(global_position.y)
    z_index = (y_position / 2) - 10

func _handle_trap_activation(enemy: IEnemy) -> void:
    match trap_type:
        TrapType.PASSIVE:
            apply_effect(enemy)
        TrapType.ACTIVE:
            if is_usable:
                apply_effect(enemy)
                active_affected_enemy = enemy
                current_effect_duration = effect_duration
                is_usable = false
                current_cooldown = cooldown_time
        TrapType.LIMITED:
            if is_usable:
                if not enemy in active_affected_enemies:  # Seulement si l'ennemi n'est pas déjà affecté
                    apply_effect(enemy)
                    active_affected_enemies[enemy] = effect_duration
                    current_durability -= 1
                    if current_durability <= 0:
                        is_usable = false

# signal
func _on_area_2d_body_entered(body) -> void:
    if not (body is IEnemy) or state != TrapState.ACTIVE:
        return
        
    enemies_in_area.append(body)
    _handle_trap_activation(body)

func _on_area_2d_body_exited(body) -> void:
    if not (body is IEnemy) or state != TrapState.ACTIVE:
        return
        
    enemies_in_area.erase(body)
    if trap_type == TrapType.PASSIVE:
        remove_effect(body)
    elif trap_type == TrapType.LIMITED:
        if body in active_affected_enemies:
            remove_effect(body)
            active_affected_enemies.erase(body)

## Override these methods in specific trap implementations
func apply_effect(_enemy: IEnemy) -> void:
    pass

func remove_effect(_enemy: IEnemy) -> void:
    pass 