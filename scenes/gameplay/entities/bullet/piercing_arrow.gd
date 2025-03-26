## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Piercing arrow bullet that can pass through multiple enemies.
class_name PiercingArrow
extends IBullet

# Constants
const TRAIL_LENGTH: int = 10  # Longueur de la traînée visuelle

# Exports
@export var pierce_count: int = 3  ## Number of enemies the bullet can pierce
@export_range(0, 100) var pierce_reduction: int = 10  ## Percentage of damage reduction per enemy pierced

# Variables
var pierced_enemies: Array[IEnemy] = []  # Ennemis déjà transpercés
var piercing: int  # Current number of enemies that can be pierced
var initial_piercing: int  # Initial number of enemies that can be pierced

# core
func _ready() -> void:
	super._ready()
	
	# Initialisation des variables de perçage
	piercing = pierce_count
	initial_piercing = pierce_count
	
	# On peut ajouter un effet visuel de traînée ici si besoin


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
		
	position += direction * speed * delta


# private
func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy:
		return
		
	if pierced_enemies.has(body):
		return  # Éviter de frapper le même ennemi deux fois
		
	var enemy := body as IEnemy
	pierced_enemies.append(enemy)
	
	# Application des dégâts
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
	# Gestion du perçage
	piercing -= 1
	
	# Calcul de la réduction de dégâts
	var enemies_pierced := initial_piercing - piercing
	var remaining_damage_percent: float = 100 - (pierce_reduction * enemies_pierced)
	damage = roundi(initial_damage * (remaining_damage_percent / 100))
	
	# Si on a atteint la limite de perçage, on détruit la flèche
	if piercing <= 0:
		queue_free()
		return
