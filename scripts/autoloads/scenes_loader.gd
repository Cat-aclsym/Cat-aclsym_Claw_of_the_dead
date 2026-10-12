## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages loading of game scenes and resources.
extends Node

const END_GAME_MENU: PackedScene = preload("res://scenes/ui/menus/end_game/end_game.tscn")

var enemies_scene: Dictionary = {}
