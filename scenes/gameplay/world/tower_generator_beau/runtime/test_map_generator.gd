## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Script de test pour la génération de maps en runtime.
## À attacher à un nœud pour tester rapidement la génération.
##
## Usage : Appuyer sur F5 pour générer une map de test.

extends Node2D

@onready var test_map_container: Node2D = $TestMapContainer

func _ready() -> void:
	# Générer une map de test au démarrage
	_generate_test_map()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Espace ou Entrée
		_generate_test_map()

func _generate_test_map() -> void:
	# Nettoyer l'ancienne map
	if test_map_container:
		for child in test_map_container.get_children():
			child.queue_free()
	else:
		test_map_container = Node2D.new()
		test_map_container.name = "TestMapContainer"
		add_child(test_map_container)
	
	# Créer une configuration de test
	var config = MapGeneratorRuntimeMain.create_default_config()
	config.width = 20
	config.height = 12
	config.style = 1  # MapStyle.MANY_TURNS
	config.num_paths = 1
	
	# Générer la map
	var map_instance = MapGeneratorRuntimeMain.generate_map(config)
	
	# Ajouter à la scène
	test_map_container.add_child(map_instance)
	
	print("✅ Map générée avec succès ! (Appuyez sur Espace pour régénérer)")
