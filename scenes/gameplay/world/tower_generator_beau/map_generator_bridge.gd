@tool
extends Node2D

## © [2024] A7 Studio. All rights reserved.
## Outil visuel pour générer des maps sans toucher au code ou au terminal.

@export_group("Dimensions")
@export var width: int = 25
@export var height: int = 15

@export_group("Style & Équilibre")
@export_enum("long_path", "many_turns", "chokepoints", "open", "s_curve", "spiral", "zig_zag") var style: String = "many_turns"
@export_enum("easy", "medium", "hard") var difficulty: String = "medium"
@export var seed: int = 0

@export_group("Défis (Types d'ennemis)")
@export var enemies_fast: bool = true
@export var enemies_tank: bool = false
@export var enemies_swarm: bool = false
@export var enemies_boss: bool = false

@export_group("Contraintes Spécifiques")
@export var min_path_length: int = 0
@export var max_buildable_zones: int = 0
@export var force_chokepoints: bool = false

@export_group("Action")
@export var GENERATE_NOW: bool = false:
	set(val: bool):
		if val:
			_run_python_generator()
		GENERATE_NOW = false

@onready var generate_button: Button = get_node_or_null("CanvasLayer/GeneratorPanel/Margin/VBox/GenerateButton")
@onready var random_seed_button: Button = get_node_or_null("CanvasLayer/GeneratorPanel/Margin/VBox/RandomSeedButton")
@onready var status_label: Label = get_node_or_null("CanvasLayer/GeneratorPanel/Margin/VBox/StatusLabel")

func _ready() -> void:
	if generate_button != null:
		generate_button.pressed.connect(_on_generate_button_pressed)
	if random_seed_button != null:
		random_seed_button.pressed.connect(_on_random_seed_button_pressed)
	_update_status("Prêt à générer une map")

func _on_generate_button_pressed() -> void:
	_run_python_generator()

func _on_random_seed_button_pressed() -> void:
	var temp_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	temp_rng.randomize()
	seed = int(temp_rng.randi())
	_update_status("Seed aléatoire: %d" % seed)

func _run_python_generator():
	_update_status("Génération en cours...")
	print("Generation de la map en cours...")
	
	# Préparation des arguments
	var python_path = "python" # Ou "python3" selon l'install
	
	var enemy_list: Array[String] = []
	if enemies_fast: enemy_list.append("fast")
	if enemies_tank: enemy_list.append("tank")
	if enemies_swarm: enemy_list.append("swarm")
	if enemies_boss: enemy_list.append("boss")
	var enemy_str = ",".join(enemy_list)
	
	var args: Array[String] = [
		"-m", "scenes.gameplay.world.tower_generator_beau.main",
		"--width", str(width),
		"--height", str(height),
		"--style", style,
		"--difficulty", difficulty,
		"--enemies", enemy_str
	]
	if seed != 0:
		args.append_array(["--seed", str(seed)])
	
	if min_path_length > 0:
		args.append_array(["--min-len", str(min_path_length)])
	if max_buildable_zones > 0:
		args.append_array(["--max-buildable", str(max_buildable_zones)])
	if force_chokepoints:
		args.append("--force-choke")
		
	# Exécution
	var output: Array = []
	var exit_code = OS.execute(python_path, args, output, true)
	
	if exit_code == 0:
		print("Map generee avec succes")
		_update_status("Map générée avec succès")
		# Force Godot à rafraîchir le dossier pour voir le nouveau fichier
		if Engine.is_editor_hint():
			EditorInterface.get_resource_filesystem().scan()
	else:
		printerr("Erreur lors de la generation : ", output)
		_update_status("Erreur génération (voir console)")
		print("Conseil : verifie que Python est installe et accessible via la commande 'python'.")

func _update_status(text: String) -> void:
	if status_label != null:
		status_label.text = text
