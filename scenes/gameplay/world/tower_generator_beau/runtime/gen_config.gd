## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Configuration pour la génération de map.

class_name GenConfig
extends RefCounted

var width: int = 25
var height: int = 15
var difficulty: int = 1  # Difficulty.MEDIUM
var enemy_types: Array[String] = []
var player_level: int = 1
var style: int = 1  # MapStyle.MANY_TURNS
var num_paths: int = 1
var decoration_density: float = 0.05
var buildable_density: float = 0.2
var min_path_length: int = 0
var max_path_length: int = 0  # 0 = pas de limite
var max_buildable_zones: int = 0  # 0 = pas de limite
var min_buildable_zones: int = 0  # 0 = pas de limite
var force_chokepoints: bool = false
var obstacle_density: float = 0.1  # Densité d'obstacles (décorations)
var theme: String = "default"  # Thème visuel (default, desert, forest, etc.)
var seed: int = 0  # 0 = générer un seed aléatoire
