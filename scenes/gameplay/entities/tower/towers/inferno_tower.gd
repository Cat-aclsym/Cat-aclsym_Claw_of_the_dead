## © [2026] A7 Studio. All rights reserved. Trademark.

class_name InfernoTower
extends ITower
## Specialized script for the Inferno Tower (bat_09).
## Handles continuous beams and multi-target logic.

## Active beams for continuous fire towers (bullet_instance -> target)
var _active_beams: Dictionary = {}


func _on_target_lost() -> void:
	_cleanup_beams()


func _on_target_locked(delta: float) -> void:
	target_lock_time += delta


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
	var existing_beam: Node = null
	for beam in _active_beams.keys():
		if is_instance_valid(beam) and _active_beams[beam] == target_enemy:
			existing_beam = beam
			break
	
	if existing_beam:
		# If we already have a beam, we don't need the new one
		# This is a bit tricky because ITower.fire() just instantiated it.
		# We'll queue_free the new one and use the old one.
		bullet.queue_free()
		if existing_beam.has_method("fire_tick"):
			existing_beam.call("fire_tick")
	else:
		_active_beams[bullet] = target_enemy


func _on_upgrade_applied() -> void:
	# Update existing beams immediately with new stats
	for beam in _active_beams.keys():
		if is_instance_valid(beam):
			_apply_projectile_config(beam)


## Specific logic for multi-target Inferno Tower
func _fire_inferno_multi_target() -> void:
	# Get all valid enemies in range
	var valid_enemies: Array[IEnemy] = []
	for e in enemy_array:
		if is_instance_valid(e) and not e.is_already_dead and global_position.distance_to(e.global_position) <= shoot_range + 5.0:
			valid_enemies.append(e)
	
	if valid_enemies.is_empty():
		_cleanup_beams()
		return

	# Sort or prioritize targets based on target_type if needed
	var targets_to_hit: Array[IEnemy] = []
	for e in valid_enemies:
		if targets_to_hit.size() >= projectile_count:
			break
		targets_to_hit.append(e)

	# Cleanup beams for targets that are no longer being hit
	var beams_to_remove: Array[Node] = []
	for beam in _active_beams.keys():
		if not is_instance_valid(beam):
			beams_to_remove.append(beam)
			continue
		
		var beam_target = _active_beams[beam]
		if not is_instance_valid(beam_target) or not beam_target in targets_to_hit:
			beam.queue_free()
			beams_to_remove.append(beam)
	
	for b in beams_to_remove:
		_active_beams.erase(b)

	# Fire or update beams for selected targets
	for t in targets_to_hit:
		var existing_beam: Node = null
		for beam in _active_beams.keys():
			if is_instance_valid(beam) and _active_beams[beam] == t:
				existing_beam = beam
				break
		
		if existing_beam:
			if existing_beam.has_method("fire_tick"):
				existing_beam.call("fire_tick")
		else:
			var bullet_instance: IBullet = bullet_scene.instantiate()
			bullet_instance.tower_owner = self
			if "enemy_target" in bullet_instance:
				bullet_instance.set("enemy_target", t)
			
			_apply_projectile_config(bullet_instance)
			add_child(bullet_instance)
			_active_beams[bullet_instance] = t


func _cleanup_beams() -> void:
	for beam in _active_beams.keys():
		if is_instance_valid(beam):
			beam.queue_free()
	_active_beams.clear()


func disable_tower() -> void:
	super.disable_tower()
	_cleanup_beams()
