## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the build menu (towers and traps) and its animations.
class_name BuildSelection
extends Control

## Row of [BuildCard] instances.
@onready var construction_menu: HBoxContainer = $MarginContainer/BackgroundTextureRect/BuildListMarginContainer/HBoxContainer
@onready var construction_anim_player: AnimationPlayer = $AnimationPlayer

func _exit_tree() -> void:
	if ILevel.current_level and ILevel.current_level.stats_updated.is_connected(_on_level_stats_updated):
		ILevel.current_level.stats_updated.disconnect(_on_level_stats_updated)


func _process(_delta: float) -> void:
	if is_queued_for_deletion():
		toggle_build_menu()


func _ready() -> void:
	assert(construction_menu != null, "construction_menu node not found")
	assert(construction_anim_player != null, "construction_anim_player node not found")

	construction_anim_player.animation_finished.connect(
	func(_name: String) -> void:
		if _name == "RESET" and construction_menu.visible:
			construction_menu.visible = false
	)
	construction_menu.visible = true

	if ILevel.current_level:
		ILevel.current_level.stats_updated.connect(_on_level_stats_updated)


# Public functions

## Toggles the build menu visibility with animation.
## [br]Refreshes build cards when opening the menu.
func toggle_build_menu() -> void:
	if construction_menu.visible:
		Log.trace(Log.Level.INFO, "Hiding construction menu")
		construction_anim_player.play("RESET")
	else:
		Log.trace(Log.Level.INFO, "Showing construction menu")
		construction_anim_player.play("show_build_list")
		construction_menu.visible = true
		_refresh_construction_cards()
		return


# Private functions

## Re-runs [method BuildCard.update] on every card when [signal ILevel.stats_updated] fires (e.g. coins).
func _on_level_stats_updated() -> void:
	_refresh_construction_cards()


## Refreshes price / disabled state on all build cards (coins may have changed).
func _refresh_construction_cards() -> void:
	for aspect in construction_menu.get_children():
		for card in aspect.get_children():
			if card is BuildCard:
				(card as BuildCard).update()
