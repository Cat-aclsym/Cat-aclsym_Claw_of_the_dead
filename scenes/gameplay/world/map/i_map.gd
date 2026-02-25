## © [2024] A7 Studio. All rights reserved. Trademark.
class_name IMap
extends Node2D

@export var tilemap: TileMap

## Array de tous les chemins disponibles
var paths: Array[Path2D] = []

## Array des chemins actuellement actifs
var active_paths: Array[Path2D] = []

## Index du chemin de départ (0 par défaut)
@export var initial_path_index: int = 0

## Référence optionnelle au gestionnaire d'événements
var map_events: MapEvents = null

@onready var camera: Camera2D = $Camera2D

# core
func _ready() -> void:
	_load_paths()
	_initialize_paths()
	_load_map_events()
	Global.cursor.tm_ref = tilemap

# public

## Active un chemin par son index
func activate_path(path_index: int) -> void:
	if path_index < 0 or path_index >= paths.size():
		Log.trace(Log.Level.ERROR, "Index de chemin invalide: %d" % path_index)
		return

	var path = paths[path_index]
	if path not in active_paths:
		active_paths.append(path)
		path.visible = true
		Log.trace(Log.Level.INFO, "Chemin %d activé" % path_index)

## Désactive un chemin par son index
func deactivate_path(path_index: int) -> void:
	if path_index < 0 or path_index >= paths.size():
		return

	var path = paths[path_index]
	if path in active_paths:
		active_paths.erase(path)
		path.visible = false
		Log.trace(Log.Level.INFO, "Chemin %d désactivé" % path_index)

## Active plusieurs chemins en même temps
func activate_paths(path_indices: Array[int]) -> void:
	for index in path_indices:
		activate_path(index)

## Désactive tous les chemins sauf ceux spécifiés
func set_active_paths_only(path_indices: Array[int]) -> void:
	# Désactive tous
	for i in range(paths.size()):
		deactivate_path(i)
	# Active seulement ceux demandés
	activate_paths(path_indices)

## Récupère un chemin actif aléatoire pour spawner des ennemis
func get_random_active_path() -> Path2D:
	if active_paths.is_empty():
		Log.trace(Log.Level.ERROR, "Aucun chemin actif disponible!")
		return null
	return active_paths[randi() % active_paths.size()]

## Récupère tous les chemins actifs
func get_active_paths() -> Array[Path2D]:
	return active_paths

func get_tower_by_name(tower_name: String) -> ITower:
	for child in get_children():
		if child is ITower:
			var tower: ITower = child as ITower
			if tower.name == tower_name:
				return tower
	return null

# private

## Charge tous les chemins depuis le node Paths
func _load_paths() -> void:
	var children: Array[Node] = $Paths.get_children()
	for child in children:
		if child is Path2D:
			paths.append(child as Path2D)

	Log.trace(Log.Level.DEBUG, "Chargé %d chemins" % paths.size())

## Initialise l'état des chemins au démarrage
func _initialize_paths() -> void:
	# Masque tous les chemins
	for path in paths:
		path.visible = false

	# Active seulement le chemin initial
	if initial_path_index >= 0 and initial_path_index < paths.size():
		activate_path(initial_path_index)
	else:
		Log.trace(Log.Level.WARN, "Index de chemin initial invalide")


## Charge le gestionnaire d'événements s'il existe
func _load_map_events() -> void:
	if has_node("MapEvents"):
		map_events = get_node("MapEvents") as MapEvents
		Log.trace(Log.Level.DEBUG, "MapEvents chargé")


## Notifie le gestionnaire d'événements du début d'une vague
func notify_wave_start(wave_number: int) -> void:
	if map_events:
		map_events.on_wave_start(wave_number)
