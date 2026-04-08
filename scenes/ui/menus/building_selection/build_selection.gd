## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the build menu (towers and traps) and its animations.
class_name BuildSelection
extends Control

enum Tab { TOWERS, TRAPS }

## Row of [BuildCard] instances.
@onready var construction_menu: HBoxContainer = $MarginContainer/VBoxContainer/BackgroundTextureRect/BuildListMarginContainer/HBoxContainer
@onready var construction_anim_player: AnimationPlayer = $AnimationPlayer
@onready var tower_tab_button: Button = $MarginContainer/VBoxContainer/TabsHBox/TowerTabButton
@onready var trap_tab_button: Button = $MarginContainer/VBoxContainer/TabsHBox/TrapTabButton

var _current_tab: Tab = Tab.TOWERS

func _exit_tree() -> void:
	if ILevel.current_level and ILevel.current_level.stats_updated.is_connected(_on_level_stats_updated):
		ILevel.current_level.stats_updated.disconnect(_on_level_stats_updated)


func _process(_delta: float) -> void:
	if is_queued_for_deletion():
		toggle_build_menu()


func _ready() -> void:
	assert(construction_menu != null, "construction_menu node not found")
	assert(construction_anim_player != null, "construction_anim_player node not found")
	assert(tower_tab_button != null, "tower_tab_button node not found")
	assert(trap_tab_button != null, "trap_tab_button node not found")

	construction_anim_player.animation_finished.connect(
	func(_name: String) -> void:
		if _name == "RESET" and construction_menu.visible:
			construction_menu.visible = false
	)
	construction_menu.visible = true

	tower_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.TOWERS))
	trap_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.TRAPS))

	if ILevel.current_level:
		ILevel.current_level.stats_updated.connect(_on_level_stats_updated)
	
	_update_tab_visuals()
	_refresh_construction_cards()


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

func _on_level_stats_updated() -> void:
	_refresh_construction_cards()


func _on_tab_pressed(tab: Tab) -> void:
	if _current_tab == tab:
		return
	_current_tab = tab
	_update_tab_visuals()
	_refresh_construction_cards()


## Refreshes price / disabled state on all build cards (coins may have changed).
func _refresh_construction_cards() -> void:
	for aspect in construction_menu.get_children():
		var card: BuildCard = aspect.get_child(0) as BuildCard
		if card:
			var is_tower: bool = card._entity is ITower
			var is_trap: bool = card._entity is ITrap
			
			var should_be_visible: bool = false
			if _current_tab == Tab.TOWERS and is_tower:
				should_be_visible = true
			elif _current_tab == Tab.TRAPS and is_trap:
				should_be_visible = true
			
			aspect.visible = should_be_visible
			if should_be_visible:
				card.update()


func _update_tab_visuals() -> void:
	tower_tab_button.disabled = (_current_tab == Tab.TOWERS)
	trap_tab_button.disabled = (_current_tab == Tab.TRAPS)
