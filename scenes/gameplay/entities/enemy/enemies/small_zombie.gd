## © [2026] A7 Studio. All rights reserved. Trademark.

class_name SmallZombie
extends IEnemy

## Visual tint for the small zombie
const SMALL_TINT: Color = Color(1.0, 0.5, 0.5, 1.0)
## Scale for the small zombie
const SMALL_SCALE: Vector2 = Vector2(0.6, 0.6)


func _ready() -> void:
	super._ready()
	old_modulate = SMALL_TINT
	sprite.modulate = SMALL_TINT
	sprite.scale = SMALL_SCALE
	
	# Adjust collision shape for smaller size
	if collision_shape:
		collision_shape.scale = SMALL_SCALE
	
	# Visual effect on spawn
	_spawn_effect()


func _spawn_effect() -> void:
	var tween = create_tween()
	sprite.scale = Vector2.ZERO
	tween.tween_property(sprite, "scale", SMALL_SCALE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
