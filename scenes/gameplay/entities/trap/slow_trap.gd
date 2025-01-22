## © [2024] A7 Studio. All rights reserved. Trademark.
##
## A trap that slows down enemies.
class_name SlowTrap
extends ITrap

## The slow effect percentage (0.5 = 50% slower)
@export var slow_amount: float = 0.9
## The number of enemies that can step on the trap before it breaks
@export var max_durability: int = 10

var current_durability: int

@onready var break_particles: GPUParticles2D = $BreakParticles

func _ready() -> void:
    super()
    current_durability = max_durability

func apply_effect(enemy: IEnemy) -> void:
    enemy.speed *= (1.0 - slow_amount)
    current_durability -= 1
    # Update opacity based on remaining durability
    sprite_2d.modulate.a = float(current_durability) / float(max_durability)
    
    if current_durability <= 0:
        _break()

func remove_effect(enemy: IEnemy) -> void:
    enemy.speed /= (1.0 - slow_amount)

func _break() -> void:
    # Hide the sprite but keep particles visible
    sprite_2d.visible = false
    # Disable collision to prevent new enemies from being affected
    area_2d.monitoring = false
    area_2d.monitorable = false
    # Emit particles
    break_particles.emitting = true
    # Wait for particles to finish before removing the trap
    await get_tree().create_timer(break_particles.lifetime).timeout
    queue_free() 