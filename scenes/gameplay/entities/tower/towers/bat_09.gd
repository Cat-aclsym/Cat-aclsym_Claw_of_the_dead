## © [2026] A7 Studio. All rights reserved. Trademark.

class_name InfernoTower
extends ITower
## Inferno Tower (bat09) with single-target (charging) and multi-target modes.

# Enums
enum InfernoMode {
	SINGLE_TARGET, ## Focuses one target with increasing damage
	MULTI_TARGET   ## Focuses multiple targets with constant damage
}

# Constants
const CHARGE_TIME_MAX: float = 3.0 ## Time to reach maximum damage multiplier
const DAMAGE_MULTIPLIER_MAX: float = 5.0 ## Maximum damage multiplier at full charge

# Exported variables
@export var mode: InfernoMode = InfernoMode.SINGLE_TARGET

# Private variables
var _current_targets: Array[IEnemy] = []
var _charge_timer: float = 0.0
var _beam_visuals: Array[Line2D] = []

# Built-in functions
func _ready() -> void:
	super._ready()
	# Initialize beam visuals pool or similar if needed
	# For now, we'll manage them dynamically or via child nodes

func _process(delta: float) -> void:
	if Global.paused:
		return

	if state != TowerState.ACTIVE:
		return

	_update_targets()
	
	if _current_targets.is_empty():
		_reset_charge()
		_hide_beams()
		return

	if mode == InfernoMode.SINGLE_TARGET:
		_process_single_target(delta)
	else:
		_process_multi_target(delta)

# Private functions
func _update_targets() -> void:
	# Clean up dead or out of range targets
	_current_targets = _current_targets.filter(func(e): return is_instance_valid(e) and e in enemy_array)
	
	if mode == InfernoMode.SINGLE_TARGET:
		if _current_targets.is_empty() and not enemy_array.is_empty():
			_choose_target()
			if target:
				_current_targets.append(target)
				_reset_charge()
		elif _current_targets.size() > 1:
			_current_targets = [_current_targets[0]]
	else:
		# Multi-target mode: fill up to projectile_count
		var max_targets = projectile_count
		for enemy in enemy_array:
			if _current_targets.size() >= max_targets:
				break
			if not enemy in _current_targets:
				_current_targets.append(enemy)

func _process_single_target(delta: float) -> void:
	var target_enemy = _current_targets[0]
	_charge_timer = min(_charge_timer + delta, CHARGE_TIME_MAX)
	
	# Damage is applied via a tick system or continuous process
	# Since ITower uses a fire_rate_timer, we might want to override fire()
	# but for a continuous beam, we apply damage in _process or a separate interval.
	
	var multiplier = 1.0
	# Branch 1 (Single Target) has increasing damage
	# The base tower (no upgrades) is branch 1 but WITHOUT increasing damage.
	# We'll check a bullet_stat or tower_stat to see if charging is enabled.
	if bullet_stats.get("is_charging", false):
		multiplier = lerp(1.0, DAMAGE_MULTIPLIER_MAX, _charge_timer / CHARGE_TIME_MAX)
	
	_apply_beam_damage(target_enemy, multiplier, delta)
	_update_beam_visual(0, target_enemy, multiplier)

func _process_multi_target(delta: float) -> void:
	_reset_charge()
	for i in range(_current_targets.size()):
		var target_enemy = _current_targets[i]
		_apply_beam_damage(target_enemy, 1.0, delta)
		_update_beam_visual(i, target_enemy, 1.0)
	
	# Hide unused beams
	for i in range(_current_targets.size(), _beam_visuals.size()):
		if is_instance_valid(_beam_visuals[i]):
			_beam_visuals[i].visible = false

func _apply_beam_damage(enemy: IEnemy, multiplier: float, delta: float) -> void:
	# Damage per second based on bullet_stats["damage"]
	var base_dmg = bullet_stats.get("damage", 10.0)
	var total_dmg = base_dmg * multiplier * delta
	enemy.take_damage(total_dmg, IEnemy.DamageType.DEFAULT, self)

func _reset_charge() -> void:
	_charge_timer = 0.0

func _update_beam_visual(index: int, target_enemy: IEnemy, multiplier: float) -> void:
	# Ensure we have enough Line2D nodes
	while _beam_visuals.size() <= index:
		var new_beam = Line2D.new()
		new_beam.width = 2.0
		new_beam.default_color = Color.ORANGE_RED
		add_child(new_beam)
		_beam_visuals.append(new_beam)
	
	var beam = _beam_visuals[index]
	beam.visible = true
	beam.clear_points()
	beam.add_point(Vector2.ZERO) # Tower center (local)
	beam.add_point(to_local(target_enemy.global_position))
	
	# Visual feedback for charge
	if mode == InfernoMode.SINGLE_TARGET:
		beam.width = lerp(2.0, 5.0, (multiplier - 1.0) / (DAMAGE_MULTIPLIER_MAX - 1.0))
		beam.default_color = lerp(Color.ORANGE_RED, Color.RED, (multiplier - 1.0) / (DAMAGE_MULTIPLIER_MAX - 1.0))
	else:
		beam.width = 1.5
		beam.default_color = Color.ORANGE

func _hide_beams() -> void:
	for beam in _beam_visuals:
		if is_instance_valid(beam):
			beam.visible = false

# Override fire() to prevent default projectile spawning
func fire() -> void:
	# Inferno Tower uses continuous beams in _process instead of discrete projectiles
	pass

func apply_upgrade() -> void:
	super.apply_upgrade()
	# Check if upgrade changed the mode
	var upgrade_data = StatsDB.get_upgrade(pending_upgrade_id)
	if upgrade_data.has("inferno_mode"):
		mode = upgrade_data["inferno_mode"] as InfernoMode
		_reset_charge()
		_hide_beams()
		_current_targets.clear()
