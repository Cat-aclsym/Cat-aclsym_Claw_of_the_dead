## © [2026] A7 Studio. All rights reserved. Trademark.

class_name InfernoTower
extends ITower
## Specialized script for the Inferno Tower (bat_09).
## Handles continuous beams and multi-target logic.

## Active beams for continuous fire towers (beam -> target)
var _active_beams: Dictionary[IBullet, IEnemy] = {}


func _on_target_lost() -> void:
	_cleanup_beams()


func _handle_custom_fire() -> bool:
	if projectile_count > 1:
		_fire_inferno_multi_target()
		fire_rate_timer.start()
		return true
	return false


func _on_projectile_instantiated(bullet: IBullet, target_enemy: IEnemy) -> void:
	# For continuous beams, check if we already have an active beam for this target
	# Note: This is only called when projectile_count == 1 (standard fire loop)
	# because _handle_custom_fire returns true for projectile_count > 1.
	if _find_beam(target_enemy) != null:
		# The beam already exists, the new one is not in the tree yet so it is freed right away
		bullet.free()
	else:
		_active_beams[bullet] = target_enemy


func _on_upgrade_applied() -> void:
	# Update existing beams immediately with new stats
	for beam: Variant in _active_beams.keys():
		if is_instance_valid(beam):
			_apply_projectile_config(beam)


## Specific logic for multi-target Inferno Tower
func _fire_inferno_multi_target() -> void:
	# Get the first valid enemies in range
	var targets_to_hit: Array[IEnemy] = []
	for e in enemy_array:
		if targets_to_hit.size() >= projectile_count:
			break
		if is_instance_valid(e) and _is_valid_candidate(e, ACQUIRE_RANGE_MARGIN):
			targets_to_hit.append(e)

	if targets_to_hit.is_empty():
		_cleanup_beams()
		return

	# Cleanup beams for targets that are no longer being hit
	var beams_to_remove: Array[Variant] = []
	for beam: Variant in _active_beams.keys():
		if not is_instance_valid(beam):
			beams_to_remove.append(beam)
			continue

		var beam_target: Variant = _active_beams[beam]
		if not is_instance_valid(beam_target) or not beam_target in targets_to_hit:
			beam.queue_free()
			beams_to_remove.append(beam)

	for b: Variant in beams_to_remove:
		_active_beams.erase(b)

	# Fire beams for selected targets that have none yet, the others keep burning
	for t in targets_to_hit:
		if _find_beam(t) != null:
			continue

		var bullet_instance: IBullet = bullet_scene.instantiate()
		bullet_instance.tower_owner = self
		if "enemy_target" in bullet_instance:
			bullet_instance.set("enemy_target", t)

		_apply_projectile_config(bullet_instance)
		add_child(bullet_instance)
		_active_beams[bullet_instance] = t


func _find_beam(enemy: IEnemy) -> IBullet:
	for beam: Variant in _active_beams.keys():
		if is_instance_valid(beam) and _active_beams[beam] == enemy:
			return beam
	return null


func _cleanup_beams() -> void:
	for beam: Variant in _active_beams.keys():
		if is_instance_valid(beam):
			beam.queue_free()
	_active_beams.clear()


func disable_tower() -> void:
	super.disable_tower()
	_cleanup_beams()
