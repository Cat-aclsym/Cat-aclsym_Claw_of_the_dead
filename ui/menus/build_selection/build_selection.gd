## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the build menu (towers and traps) and its animations.
class_name BuildSelection
extends Control

enum Tab { TOWERS, TRAPS }

const BUILD_CARD_SCENE: PackedScene = preload("res://ui/menus/build_selection/cards/build_card.tscn")
## Entities of the menu, in display order (the [StatsDB] order is not the menu order: bat_09 comes before bat_08).
const CARD_IDS: Array[String] = ["bat_01", "bat_02", "bat_09", "bat_08", "bat_03", "bat_04", "bat_05", "bat_06", "bat_07"]

var _current_tab: Tab = Tab.TOWERS

@onready var construction_anim_player: AnimationPlayer = $AnimationPlayer
## Row of [AspectRatioContainer]s, each holding one [BuildCard] (created by [method _build_cards]).
@onready var construction_menu: HBoxContainer = $MarginContainer/VBoxContainer/BackgroundTextureRect/BuildListMarginContainer/HBoxContainer
@onready var tower_tab_button: GameButton = $MarginContainer/VBoxContainer/TabsHBox/TowerTabButton
@onready var trap_tab_button: GameButton = $MarginContainer/VBoxContainer/TabsHBox/TrapTabButton

func _ready() -> void:
	assert(construction_menu != null, "construction_menu node not found")
	assert(construction_anim_player != null, "construction_anim_player node not found")
	assert(tower_tab_button != null, "tower_tab_button node not found")
	assert(trap_tab_button != null, "trap_tab_button node not found")

	SignalUtil.connects([
		{SignalUtil.WHO: construction_anim_player, SignalUtil.WHAT: "animation_finished", SignalUtil.TO: _on_animation_finished},
		{SignalUtil.WHO: tower_tab_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_tab_pressed.bind(Tab.TOWERS)},
		{SignalUtil.WHO: trap_tab_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_tab_pressed.bind(Tab.TRAPS)},
	])
	construction_menu.visible = true

	if ILevel.current_level:
		SignalUtil.connects([{SignalUtil.WHO: ILevel.current_level, SignalUtil.WHAT: "stats_updated", SignalUtil.TO: _on_level_stats_updated}])

	_build_cards()
	_update_tab_visuals()
	_refresh_construction_cards()


func _process(_delta: float) -> void:
	if is_queued_for_deletion():
		toggle_build_menu()


func _exit_tree() -> void:
	if ILevel.current_level and ILevel.current_level.stats_updated.is_connected(_on_level_stats_updated):
		ILevel.current_level.stats_updated.disconnect(_on_level_stats_updated)


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

## Creates one [BuildCard] per id of [constant CARD_IDS], the entity scene comes from the [code]scene[/code] field of [StatsDB] (tower or trap).
## [br]An id without a scene is skipped with a warning.
func _build_cards() -> void:
	for id: String in CARD_IDS:
		var stats: Dictionary = StatsDB.get_tower(id) if StatsDB.has_tower(id) else StatsDB.get_trap(id)
		var scene: PackedScene = StatsDB.load_packed_scene(str(stats.get("scene", "")))
		if scene == null:
			Log.trace(Log.Level.WARN, "No entity scene for build card '%s'" % id)
			continue

		var aspect: AspectRatioContainer = AspectRatioContainer.new()
		aspect.name = "%sAspectRatioContainer" % id.to_pascal_case()
		aspect.stretch_mode = AspectRatioContainer.STRETCH_HEIGHT_CONTROLS_WIDTH
		var card: BuildCard = BUILD_CARD_SCENE.instantiate()
		card.name = "BuildCard%s" % id.to_pascal_case()
		card.entity = scene
		aspect.add_child(card)
		construction_menu.add_child(aspect)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"RESET" and construction_menu.visible:
		construction_menu.visible = false


func _on_level_stats_updated() -> void:
	_refresh_construction_cards()


func _on_tab_pressed(tab: Tab) -> void:
	_current_tab = tab
	_update_tab_visuals()
	_refresh_construction_cards()


## Refreshes price / disabled state on all build cards (coins may have changed).
func _refresh_construction_cards() -> void:
	for aspect: Control in construction_menu.get_children():
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


## Latches the button of the current tab (a click on the active tab would otherwise release it).
func _update_tab_visuals() -> void:
	tower_tab_button.set_pressed_no_signal(_current_tab == Tab.TOWERS)
	trap_tab_button.set_pressed_no_signal(_current_tab == Tab.TRAPS)
