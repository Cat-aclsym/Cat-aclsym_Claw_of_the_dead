## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Menu de génération de maps en runtime.
## Permet aux joueurs de créer et jouer leurs propres maps.

class_name MapGeneratorMenu
extends Control

# Enums locaux (même valeurs que map_enums.gd)
enum MapStyle {
	LONG_PATH,
	MANY_TURNS,
	CHOKEPOINTS,
	OPEN,
	S_CURVE,
	SPIRAL,
	ZIG_ZAG
}

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

signal menu_close

var _generated_map: Node2D = null
var _generated_game_map: RuntimeGameMap = null  # Map data pour stats et édition
var _generated_level: ILevel = null
var _current_config: GenConfig = null  # Config utilisée pour générer la map actuelle
var _saved_maps_dialog: SavedMapsDialog = null
var _map_preview: MapPreview = null
var _map_editor: MapEditor = null
var _map_stats: Dictionary = {}  # Statistiques de la map générée

# Contrôles UI
@onready var main_menu_button: Button = $MarginContainer/VBoxContainer/HeaderContainer/MainMenuButton
@onready var generate_button: Button = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/GenerateButton
@onready var play_button: Button = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/PlayButton
@onready var save_button: Button = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/SaveButton
@onready var load_button: Button = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/LoadButton
@onready var preview_button: Button = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/ToolsContainer/PreviewButton")
@onready var edit_button: Button = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/ToolsContainer/EditButton")
@onready var status_label: Label = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/StatusLabel

# Paramètres de génération
@onready var width_spinbox: SpinBox = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/WidthSpinBox
@onready var height_spinbox: SpinBox = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/HeightSpinBox
@onready var style_option: OptionButton = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/StyleOption
@onready var difficulty_option: OptionButton = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/DifficultyOption
@onready var num_paths_spinbox: SpinBox = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/NumPathsSpinBox
@onready var buildable_density_slider: HSlider = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/BuildableDensitySlider
@onready var buildable_density_label: Label = $MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/BuildableDensityLabel
@onready var strict_target_check: CheckBox = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/StrictTargetCheck")
@onready var seed_spinbox: SpinBox = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/SeedContainer/SeedSpinBox")
@onready var random_seed_button: Button = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/SeedContainer/RandomSeedButton")

# core
func _ready() -> void:
	_initialize_ui()
	_connect_signals()
	_initialize_preview_and_editor()
	play_button.disabled = true
	save_button.disabled = true
	if preview_button != null:
		preview_button.disabled = true
	if edit_button != null:
		edit_button.disabled = true

# private
func _connect_signals() -> void:
	# Vérifier que tous les nœuds sont initialisés
	if main_menu_button == null:
		main_menu_button = get_node_or_null("MarginContainer/VBoxContainer/HeaderContainer/MainMenuButton")
	if generate_button == null:
		generate_button = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/GenerateButton")
	if play_button == null:
		play_button = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/PlayButton")
	if save_button == null:
		save_button = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/SaveButton")
	if load_button == null:
		load_button = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/LoadButton")
	if preview_button == null:
		preview_button = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/ToolsContainer/PreviewButton")
	if edit_button == null:
		edit_button = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/RightPanel/Margin/ActionsVBox/ToolsContainer/EditButton")
	if buildable_density_slider == null:
		buildable_density_slider = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/BuildableDensitySlider")
	if strict_target_check == null:
		strict_target_check = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/StrictTargetCheck")
	if seed_spinbox == null:
		seed_spinbox = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/SeedContainer/SeedSpinBox")
	if random_seed_button == null:
		random_seed_button = get_node_or_null("MarginContainer/VBoxContainer/BodyContainer/MainSplit/LeftPanel/Margin/ParamsVBox/ParamsContainer/SeedContainer/RandomSeedButton")
	
	var signals: Array[Dictionary] = []
	if main_menu_button:
		signals.append({SignalUtil.WHO: main_menu_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_main_menu_button_pressed})
	if generate_button:
		signals.append({SignalUtil.WHO: generate_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_generate_button_pressed})
	if play_button:
		signals.append({SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed})
	if save_button:
		signals.append({SignalUtil.WHO: save_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_save_button_pressed})
	if load_button:
		signals.append({SignalUtil.WHO: load_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_load_button_pressed})
	if preview_button:
		signals.append({SignalUtil.WHO: preview_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_preview_button_pressed})
	if edit_button:
		signals.append({SignalUtil.WHO: edit_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_edit_button_pressed})
	if buildable_density_slider:
		signals.append({SignalUtil.WHO: buildable_density_slider, SignalUtil.WHAT: "value_changed", SignalUtil.TO: _on_density_slider_changed})
	if random_seed_button:
		signals.append({SignalUtil.WHO: random_seed_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_random_seed_button_pressed})
	
	SignalUtil.connects(signals)

# private
func _initialize_ui() -> void:
	# Initialiser les options de style
	style_option.clear()
	style_option.add_item("Long Path", MapStyle.LONG_PATH)
	style_option.add_item("Many Turns", MapStyle.MANY_TURNS)
	style_option.add_item("Chokepoints", MapStyle.CHOKEPOINTS)
	style_option.add_item("Open", MapStyle.OPEN)
	style_option.add_item("S Curve", MapStyle.S_CURVE)
	style_option.add_item("Spiral", MapStyle.SPIRAL)
	style_option.add_item("Zig Zag", MapStyle.ZIG_ZAG)
	style_option.selected = 1  # MANY_TURNS par défaut
	
	# Initialiser les options de difficulté
	difficulty_option.clear()
	difficulty_option.add_item("Easy", Difficulty.EASY)
	difficulty_option.add_item("Medium", Difficulty.MEDIUM)
	difficulty_option.add_item("Hard", Difficulty.HARD)
	difficulty_option.selected = 1  # MEDIUM par défaut
	
	# Valeurs par défaut
	width_spinbox.value = 25
	height_spinbox.value = 15
	num_paths_spinbox.value = 1
	num_paths_spinbox.min_value = 1
	num_paths_spinbox.max_value = 3
	buildable_density_slider.value = 0.12
	buildable_density_slider.min_value = 0.0
	buildable_density_slider.max_value = 0.5
	if strict_target_check != null:
		strict_target_check.button_pressed = false
	if seed_spinbox != null:
		seed_spinbox.value = 0
	_on_density_slider_changed(buildable_density_slider.value)

func _on_main_menu_button_pressed() -> void:
	get_parent().gui_margin_container.visible = true
	menu_close.emit()
	queue_free()

func _on_generate_button_pressed() -> void:
	var force_in_target: bool = strict_target_check != null and strict_target_check.button_pressed
	_start_generation(force_in_target)

func _start_generation(force_in_target: bool) -> void:
	generate_button.disabled = true
	status_label.text = "Génération en cours..."
	
	# Créer la configuration
	var config = GenConfig.new()
	config.width = int(width_spinbox.value)
	config.height = int(height_spinbox.value)
	config.style = style_option.get_selected()
	config.difficulty = difficulty_option.get_selected()
	config.num_paths = int(num_paths_spinbox.value)
	config.buildable_density = buildable_density_slider.value
	if seed_spinbox != null:
		config.seed = int(seed_spinbox.value)
	_apply_difficulty_preset(config)
	
	# Générer un seed aléatoire si pas déjà défini
	if config.seed == 0:
		var temp_rng = RandomNumberGenerator.new()
		temp_rng.randomize()
		config.seed = temp_rng.randi()
		Log.trace(Log.Level.INFO, "MapGeneratorMenu: Generated new seed=%d" % config.seed)
	else:
		Log.trace(Log.Level.INFO, "MapGeneratorMenu: Using existing seed=%d" % config.seed)
	if seed_spinbox != null:
		seed_spinbox.value = config.seed
	
	# Stocker la config pour la sauvegarde
	_current_config = config
	
	# Générer la map
	call_deferred("_generate_map", config, force_in_target)

func _generate_map(config: GenConfig, force_in_target: bool = false) -> void:
	var result: Dictionary = {}
	var validation
	var successful_result: Dictionary = {}
	var total_menu_attempts: int = 24 if force_in_target else 16
	var attempts_done: int = 0
	var attempts_engine_total: int = 0
	var current_seed: int = config.seed
	var fallback_valid_result: Dictionary = {}
	var working_config: GenConfig = _duplicate_config(config)
	
	for i in range(total_menu_attempts):
		attempts_done = i + 1
		# Si trop d'échecs, assouplir automatiquement pour garantir 1 clic = 1 map.
		if i == int(total_menu_attempts / 2):
			_relax_generation_constraints(working_config)
		
		working_config.seed = current_seed
		status_label.text = "Génération en cours... (%d/%d)" % [attempts_done, total_menu_attempts]
		
		result = MapGeneratorRuntimeMain.generate_map(working_config)
		if result != null and result.has("meta"):
			var meta_try: Dictionary = result["meta"]
			if meta_try.has("attempts"):
				attempts_engine_total += int(meta_try["attempts"])
		
		if result == null or not result.has("map") or not result.has("game_map"):
			current_seed += 1
			await get_tree().process_frame
			continue
		
		var candidate_map: RuntimeGameMap = result["game_map"]
		validation = MapValidator.validate(candidate_map)
		if not validation.is_valid:
			current_seed += 1
			await get_tree().process_frame
			continue
		
		# Garder un fallback valide même hors cible.
		if fallback_valid_result.is_empty():
			fallback_valid_result = result
		
		if force_in_target:
			var in_target: bool = false
			if result.has("meta"):
				var meta_target: Dictionary = result["meta"]
				if meta_target.has("in_target_range"):
					in_target = bool(meta_target["in_target_range"])
			if not in_target:
				current_seed += 1
				await get_tree().process_frame
				continue
		
		successful_result = result
		break
	
	if successful_result.is_empty():
		# Pour le bouton "jusqu'à cible", on retombe sur une map valide plutôt
		# que d'exiger un nouveau clic utilisateur.
		if not fallback_valid_result.is_empty():
			successful_result = fallback_valid_result
		else:
			status_label.text = "Erreur : impossible de générer une map valide en %d essais" % total_menu_attempts
			generate_button.disabled = false
			return
	
	_generated_map = successful_result["map"]
	_generated_game_map = successful_result["game_map"]
	_current_config = _duplicate_config(working_config)
	_current_config.seed = working_config.seed
	if seed_spinbox != null:
		seed_spinbox.value = working_config.seed
	
	# Calculer les statistiques de la map
	_map_stats = _calculate_map_stats(_generated_game_map)
	
	# Valider la map (normalement déjà valide)
	validation = MapValidator.validate(_generated_game_map)
	if not validation.is_valid:
		var error_msg = "Erreur : " + ", ".join(validation.errors)
		status_label.text = error_msg
		generate_button.disabled = false
		Log.trace(Log.Level.ERROR, "MapGeneratorMenu: Map validation failed after selection: %s" % error_msg)
		return
	
	# Afficher les warnings si présents
	if not validation.warnings.is_empty():
		var warning_msg = "Avertissements : " + ", ".join(validation.warnings)
		Log.trace(Log.Level.WARN, "MapGeneratorMenu: %s" % warning_msg)
	
	# Vérifier que le TileMap contient des tuiles
	var tilemap: TileMap = _generated_map.get_node_or_null("TileMapPlains")
	if tilemap != null:
		var used_cells = tilemap.get_used_cells(0)
		Log.trace(Log.Level.INFO, "MapGeneratorMenu: Map generated with %d tiles" % used_cells.size())
		if used_cells.size() == 0:
			status_label.text = "Erreur : La map est vide (0 tuiles)"
			generate_button.disabled = false
			return
	
	_generated_level = _create_level_from_map(_generated_map)
	
	var stats_text = "Map générée ! Chemins: %d, Zones buildables: %d, Difficulté: %.1f%%" % [
		_map_stats.num_paths,
		_map_stats.buildable_zones,
		validation.difficulty_score * 100.0
	]
	if successful_result.has("meta"):
		var final_meta: Dictionary = successful_result["meta"]
		if final_meta.has("quality_score"):
			stats_text += " | Qualité: %.1f%%" % (float(final_meta["quality_score"]) * 100.0)
		if final_meta.has("in_target_range") and not bool(final_meta["in_target_range"]):
			stats_text += " | meilleure approximation"
	stats_text += " | Essais menu: %d/%d" % [attempts_done, total_menu_attempts]
	if attempts_engine_total > 0:
		stats_text += " | Essais moteur: %d" % attempts_engine_total
	
	status_label.text = stats_text
	generate_button.disabled = false
	play_button.disabled = false
	save_button.disabled = false
	if preview_button != null:
		preview_button.disabled = false
	if edit_button != null:
		edit_button.disabled = false

func _apply_difficulty_preset(config: GenConfig) -> void:
	# Presets gameplay pour éviter des maps trop faciles.
	match config.difficulty:
		Difficulty.EASY:
			config.buildable_density = min(config.buildable_density, 0.16)
			config.num_paths = max(config.num_paths, 1)
			config.min_buildable_zones = max(config.min_buildable_zones, 16)
		Difficulty.MEDIUM:
			config.buildable_density = min(config.buildable_density, 0.12)
			config.num_paths = max(config.num_paths, 1)
			config.min_path_length = max(config.min_path_length, 20)
			config.min_buildable_zones = max(config.min_buildable_zones, 10)
		Difficulty.HARD:
			config.buildable_density = min(config.buildable_density, 0.08)
			config.num_paths = max(config.num_paths, 2)
			config.min_path_length = max(config.min_path_length, 28)
			config.min_buildable_zones = max(config.min_buildable_zones, 6)
			if config.max_buildable_zones <= 0:
				config.max_buildable_zones = 18
			else:
				config.max_buildable_zones = min(config.max_buildable_zones, 18)

func _on_play_button_pressed() -> void:
	if _generated_level == null:
		status_label.text = "Erreur : Aucune map générée"
		return
	
	# Cacher ce menu
	visible = false
	
	# Cacher le menu home s'il existe (il est dans UI/HomeMenu)
	var ui: UI = Global.ui
	if ui != null:
		var home: Home = ui.get_node_or_null("HomeMenu")
		if home != null:
			home.visible = false
	
	# Ajouter le level à la racine (comme dans level_selection_menu.gd)
	# D'abord l'ajouter comme enfant, puis le reparent si nécessaire
	if _generated_level.get_parent() != null:
		_generated_level.reparent(get_tree().get_root())
	else:
		get_tree().get_root().add_child(_generated_level)
	
	# Attendre que _ready() soit appelé pour initialiser les @onready
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Un frame supplémentaire pour être sûr
	
	# Vérifier que la map est bien là
	var map: IMap = _generated_level.map
	if map == null:
		status_label.text = "Erreur : La map est null"
		visible = true
		return
	
	# Vérifier que le TileMap est visible
	var tilemap: TileMap = map.get_node_or_null("TileMapPlains")
	if tilemap != null:
		tilemap.visible = true
		var used_cells = tilemap.get_used_cells(0)
		Log.trace(Log.Level.INFO, "MapGeneratorMenu: TileMap has %d tiles, visible=%s" % [used_cells.size(), tilemap.visible])
	
	# S'assurer que le Controller (TowerPlacement) est initialisé
	# Le Controller définit Global.cursor dans son _ready()
	var controller: TowerPlacement = map.get_node_or_null("Controller")
	if controller == null:
		Log.trace(Log.Level.ERROR, "MapGeneratorMenu: Controller not found in map!")
		return
	
	# Attendre que le Controller soit dans l'arbre et que _ready() soit appelé
	# Le Controller doit être dans l'arbre pour que _ready() soit appelé
	if not controller.is_inside_tree():
		Log.trace(Log.Level.WARN, "MapGeneratorMenu: Controller not in tree yet, waiting...")
		await get_tree().process_frame
		await get_tree().process_frame
	
	# Attendre encore quelques frames pour que _ready() soit appelé
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Vérifier que Global.cursor est initialisé
	if Global.cursor == null:
		Log.trace(Log.Level.WARN, "MapGeneratorMenu: Global.cursor is still null after waiting")
		# Si _ready() n'a pas été appelé, on peut essayer de forcer l'initialisation
		# Mais normalement ça devrait être fait automatiquement
	else:
		Log.trace(Log.Level.INFO, "MapGeneratorMenu: Global.cursor initialized: %s" % Global.cursor)
	
	# Activer la caméra de la map (après que tout soit initialisé)
	await get_tree().process_frame
	
	var camera: Camera2D = map.get_node_or_null("Camera2D")
	if camera == null:
		Log.trace(Log.Level.ERROR, "MapGeneratorMenu: Camera not found!")
		return
	
	# Trouver TOUTES les caméras dans la scène
	var all_cameras: Array[Camera2D] = []
	_find_all_cameras(get_tree().root, all_cameras)
	
	Log.trace(Log.Level.INFO, "MapGeneratorMenu: Found %d cameras in scene" % all_cameras.size())
	
	# Vérifier quelle caméra est actuellement active
	var current_active_camera = get_viewport().get_camera_2d()
	if current_active_camera != null:
		Log.trace(Log.Level.INFO, "MapGeneratorMenu: Currently active camera: %s" % current_active_camera.get_path())
	
	# Désactiver TOUTES les autres caméras avant d'activer celle-ci
	for cam in all_cameras:
		if cam != camera:
			cam.current = false
			cam.enabled = false
			Log.trace(Log.Level.INFO, "MapGeneratorMenu: Disabled camera: %s" % cam.get_path())
	
	# Configurer la caméra de la map
	camera.enabled = true
	if camera.zoom == Vector2(1, 1):
		camera.zoom = Vector2(1.6, 1.6)
	
	# Vérifier la position de la caméra et la recalculer si nécessaire
	if tilemap != null:
		var used_rect = tilemap.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0:
			var center_tile = used_rect.position + used_rect.size / 2
			var center_world = tilemap.map_to_local(center_tile)
			camera.position = center_world
			Log.trace(Log.Level.INFO, "MapGeneratorMenu: Camera repositioned to %s (tilemap center: %s)" % [camera.position, center_tile])
	
	# S'assurer que le TileMap et la map sont visibles
	tilemap.visible = true
	map.visible = true
	_generated_level.visible = true
	
	# Forcer la caméra à être current
	# Utiliser call_deferred pour s'assurer que c'est fait après que toutes les autres caméras soient désactivées
	camera.call_deferred("make_current")
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Vérifier si la caméra est current
	if not camera.is_current():
		Log.trace(Log.Level.WARN, "MapGeneratorMenu: Camera is not current, trying again...")
		# Désactiver toutes les autres caméras une dernière fois
		for cam in all_cameras:
			if cam != camera:
				cam.current = false
				cam.enabled = false
		# Forcer à nouveau
		camera.make_current()
		await get_tree().process_frame
	
	Log.trace(Log.Level.INFO, "MapGeneratorMenu: Camera final status - position: %s, zoom: %s, enabled: %s, current: %s" % [camera.position, camera.zoom, camera.enabled, camera.is_current()])
	Log.trace(Log.Level.INFO, "MapGeneratorMenu: TileMap position: %s, visible: %s, z_index: %s" % [tilemap.global_position, tilemap.visible, tilemap.z_index])
	
	_generated_level.start_level()
	Global.ui.start_level()

func _on_density_slider_changed(value: float) -> void:
	buildable_density_label.text = "Densité zones constructibles: %.0f%%" % (value * 100)

func _on_random_seed_button_pressed() -> void:
	var temp_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	temp_rng.randomize()
	var new_seed: int = int(temp_rng.randi())
	if seed_spinbox != null:
		seed_spinbox.value = new_seed
	status_label.text = "Seed aléatoire: %d" % new_seed

func _on_save_button_pressed() -> void:
	if _current_config == null:
		status_label.text = "Erreur : Aucune map générée à sauvegarder"
		return
	
	# Vérifier que le seed est bien défini
	if _current_config.seed == 0:
		Log.trace(Log.Level.WARN, "MapGeneratorMenu: Config has seed=0, generating new seed before save")
		var temp_rng = RandomNumberGenerator.new()
		temp_rng.randomize()
		_current_config.seed = temp_rng.randi()
	
	# Demander un nom pour la map
	# Pour l'instant, on génère un nom automatique
	var timestamp = Time.get_unix_time_from_system()
	var map_name = "map_%d" % int(timestamp)
	
	# Sauvegarder la config
	Log.trace(Log.Level.INFO, "MapGeneratorMenu: Saving map '%s' with seed=%d" % [map_name, _current_config.seed])
	var saved_name = MapSaver.save_config(_current_config, map_name)
	if saved_name.is_empty():
		status_label.text = "Erreur : Impossible de sauvegarder la map"
		return
	
	status_label.text = "Map sauvegardée : %s (seed: %d)" % [saved_name, _current_config.seed]
	Log.trace(Log.Level.INFO, "MapGeneratorMenu: Map saved as '%s' with seed=%d" % [saved_name, _current_config.seed])

func _on_load_button_pressed() -> void:
	# Créer le dialog si nécessaire
	if _saved_maps_dialog == null:
		var dialog_scene = preload("res://scenes/gameplay/world/tower_generator_beau/ui/saved_maps_dialog.tscn")
		_saved_maps_dialog = dialog_scene.instantiate()
		_saved_maps_dialog.map_selected.connect(_on_map_selected)
		add_child(_saved_maps_dialog)
	
	# Rafraîchir la liste et afficher le dialog
	_saved_maps_dialog._refresh_maps_list()
	_saved_maps_dialog.popup_centered()

## Initialise la prévisualisation et l'éditeur
func _initialize_preview_and_editor() -> void:
	# Charger les scènes
	var preview_scene = preload("res://scenes/gameplay/world/tower_generator_beau/ui/map_preview.tscn")
	var editor_scene = preload("res://scenes/gameplay/world/tower_generator_beau/ui/map_editor.tscn")
	
	# Instancier
	_map_preview = preview_scene.instantiate()
	_map_editor = editor_scene.instantiate()
	
	# Ajouter à la scène
	add_child(_map_preview)
	add_child(_map_editor)
	
	# Connecter les signaux
	_map_preview.close_requested.connect(func(): _map_preview.visible = false)
	_map_editor.close_requested.connect(func(): _map_editor.stop_editing())
	_map_editor.map_updated.connect(_on_map_edited)

## Bouton prévisualisation
func _on_preview_button_pressed() -> void:
	if _generated_game_map != null and not _map_stats.is_empty():
		_map_preview.show_preview(_generated_game_map, _map_stats)

## Bouton édition
func _on_edit_button_pressed() -> void:
	if _generated_game_map != null and _generated_map != null:
		_map_editor.start_editing(_generated_game_map, _generated_map)

## Callback quand la map est éditée
func _on_map_edited(game_map: RuntimeGameMap) -> void:
	# Recalculer les stats
	_map_stats = _calculate_map_stats(game_map)
	
	# Reconstruire la map visuelle (nécessite une reconstruction complète)
	Log.trace(Log.Level.INFO, "MapEditor: Map edited, stats recalculated")
	# Note: Pour une reconstruction complète, il faudrait appeler MapBuilder.build_map() à nouveau

func _on_map_selected(map_name: String) -> void:
	# Charger la config
	var config = MapSaver.load_config(map_name)
	if config == null:
		status_label.text = "Erreur : Impossible de charger la map '%s'" % map_name
		return
	
	# Vérifier que le seed est bien chargé
	if config.seed == 0:
		Log.trace(Log.Level.WARN, "MapGeneratorMenu: Loaded config has seed=0, generating new seed")
		var temp_rng = RandomNumberGenerator.new()
		temp_rng.randomize()
		config.seed = temp_rng.randi()
	else:
		Log.trace(Log.Level.INFO, "MapGeneratorMenu: Loaded config with seed=%d" % config.seed)
	
	# Appliquer la config aux contrôles UI
	width_spinbox.value = config.width
	height_spinbox.value = config.height
	style_option.selected = config.style
	difficulty_option.selected = config.difficulty
	num_paths_spinbox.value = config.num_paths
	buildable_density_slider.value = config.buildable_density
	_on_density_slider_changed(config.buildable_density)
	
	# Stocker la config (avec le seed)
	_current_config = config
	
	# Générer automatiquement la map avec le seed sauvegardé
	status_label.text = "Chargement de la map '%s' (seed: %d)..." % [map_name, config.seed]
	call_deferred("_generate_map", config)

## Trouve toutes les caméras dans l'arbre de scène
func _find_all_cameras(node: Node, cameras: Array[Camera2D]) -> void:
	if node is Camera2D:
		cameras.append(node as Camera2D)
	for child in node.get_children():
		_find_all_cameras(child, cameras)

## Crée un ILevel dynamique à partir d'une map générée
func _create_level_from_map(map: IMap) -> ILevel:
	# Charger la scène de base ILevel
	var level_scene = preload("res://scenes/gameplay/world/level/i_level.tscn")
	var level: ILevel = level_scene.instantiate()
	
	# Configurer le level
	level.level_id = "lev.generated"
	level.level_name = "Map Générée"
	level.level_description = "Map générée dynamiquement"
	level.arc_id = "arc.01"
	
	# La map est déjà instanciée, on l'ajoute directement
	level.add_child(map)
	level.map = map
	
	# Générer des vagues adaptées à la map
	if _generated_game_map != null and _current_config != null:
		var rng = RandomNumberGenerator.new()
		rng.seed = _current_config.seed
		var waves_data = WaveGenerator.generate_waves(_current_config, _generated_game_map, rng)
		_create_waves_file(level.level_id, waves_data)
	
	return level

## Crée un fichier JSON de vagues
func _create_waves_file(level_id: String, waves_data: Dictionary) -> void:
	# Sauvegarder dans user:// pour que ILevel puisse le charger
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("resources/levels"):
		dir.make_dir_recursive("resources/levels")
	
	var filepath = "user://resources/levels/%s.json" % level_id
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(waves_data, "\t"))
		file.close()
		Log.trace(Log.Level.INFO, "MapGeneratorMenu: Created waves file with %d waves" % waves_data.get("waves", []).size())
	else:
		Log.trace(Log.Level.ERROR, "Failed to create waves file: %s" % filepath)

## Calcule les statistiques de la map
func _calculate_map_stats(game_map: RuntimeGameMap) -> Dictionary:
	var stats = {
		"width": game_map.width,
		"height": game_map.height,
		"num_paths": game_map.paths.size(),
		"path_lengths": [],
		"avg_path_length": 0.0,
		"buildable_zones": 0,
		"spawns": game_map.spawns.size(),
		"exits": game_map.exits.size()
	}
	
	# Calculer les longueurs des chemins
	var total_length = 0.0
	for path in game_map.paths:
		var length = path.points.size()
		stats.path_lengths.append(length)
		total_length += length
	
	if game_map.paths.size() > 0:
		stats.avg_path_length = total_length / float(game_map.paths.size())
	
	# Compter les zones buildables
	for x in range(game_map.width):
		for y in range(game_map.height):
			var tile = game_map.get_tile(x, y)
			if tile and tile.type == 2:  # TileType.BUILDABLE
				stats.buildable_zones += 1
	
	return stats

func _duplicate_config(source: GenConfig) -> GenConfig:
	var cfg = GenConfig.new()
	cfg.width = source.width
	cfg.height = source.height
	cfg.difficulty = source.difficulty
	cfg.enemy_types = source.enemy_types.duplicate()
	cfg.player_level = source.player_level
	cfg.style = source.style
	cfg.num_paths = source.num_paths
	cfg.decoration_density = source.decoration_density
	cfg.buildable_density = source.buildable_density
	cfg.min_path_length = source.min_path_length
	cfg.max_path_length = source.max_path_length
	cfg.max_buildable_zones = source.max_buildable_zones
	cfg.min_buildable_zones = source.min_buildable_zones
	cfg.force_chokepoints = source.force_chokepoints
	cfg.obstacle_density = source.obstacle_density
	cfg.theme = source.theme
	cfg.seed = source.seed
	return cfg

func _relax_generation_constraints(config: GenConfig) -> void:
	# Dégrade en douceur pour sortir une map en un clic.
	if config.min_path_length > 0:
		config.min_path_length = maxi(0, config.min_path_length - 8)
	if config.max_path_length > 0:
		config.max_path_length += 10
	if config.min_buildable_zones > 0:
		config.min_buildable_zones = maxi(4, config.min_buildable_zones - 4)
	if config.max_buildable_zones > 0 and config.max_buildable_zones < config.min_buildable_zones:
		config.max_buildable_zones = config.min_buildable_zones + 4
	config.buildable_density = clamp(config.buildable_density + 0.03, 0.05, 0.22)
	if config.num_paths > 2:
		config.num_paths = 2
