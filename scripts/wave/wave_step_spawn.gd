## © [2026] A7 Studio. All rights reserved. Trademark.

class_name WaveStepSpawn
extends WaveStep
## A wave step that spawns a number of enemies of a specific type.


# core
func _init(in_data: Dictionary) -> void:
	super._init(WaveStep.Order.SPAWN, in_data)


# public
## Executes the spawn logic, instantiating an enemy and placing it on a path.
func exec() -> void:
	var enemy_id: String = _data[WaveStep.ENEMY_ID]
	var spawner_index: int = _data[WaveStep.SPAWNER]

	if not ScenesLoader.enemies_scene.has(enemy_id):
		ScenesLoader.enemies_scene[enemy_id] = load("res://scenes/gameplay/entities/enemy/enemies/%s.tscn" % enemy_id)

	var enemy: IEnemy = ScenesLoader.enemies_scene[enemy_id].instantiate()
	var level = ILevel.current_level

	if not enemy.enemy_id.is_empty():
		var is_first_encounter: bool = not ProgressionManager.is_enemy_seen(enemy.enemy_id)
		if is_first_encounter:
			var reveal_texture: Texture2D = _get_enemy_preview_texture(enemy)
			if Global.ui and reveal_texture != null:
				Global.ui.notify_new_enemy_reveal(enemy.enemy_id, reveal_texture, _get_enemy_preview_scale(enemy))
		ProgressionManager.mark_enemy_seen(enemy.enemy_id)

	EnemySpawner.spawn_enemy(level.map.paths[spawner_index], enemy)
	_data[WaveStep.COUNT] -= 1


## Returns true if all enemies for this step have been spawned.
func is_over() -> bool:
	return _data[WaveStep.COUNT] == 0


## Extracts a preview scale from an enemy instance.
func _get_enemy_preview_scale(enemy: IEnemy) -> Vector2:
	var animated_sprite: AnimatedSprite2D = enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite != null:
		return animated_sprite.scale

	var sprite_2d: Sprite2D = enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite_2d != null:
		return sprite_2d.scale

	return Vector2.ONE


## Extracts a preview texture from an enemy instance.
func _get_enemy_preview_texture(enemy: IEnemy) -> Texture2D:
	var animated_sprite: AnimatedSprite2D = enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		var animation_names: PackedStringArray = animated_sprite.sprite_frames.get_animation_names()
		if not animation_names.is_empty():
			var anim_name: String = "idle" if animated_sprite.sprite_frames.has_animation("idle") else str(animation_names[0])
			return animated_sprite.sprite_frames.get_frame_texture(anim_name, 0)

	var sprite_2d: Sprite2D = enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite_2d != null:
		return sprite_2d.texture

	return null
