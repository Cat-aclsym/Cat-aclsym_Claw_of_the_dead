## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Coordinates the first-play tutorial on Level 1.
## Orchestrates Dialogic beats and strict guided interaction objectives.
class_name TutorialManager
extends Control

# Enums
## Runtime objective gates driven by Dialogic signal events.
enum Objective {
	NONE,
	OPEN_BUILD_MENU,
	SELECT_BUILD_CARD,
	PLACE_CONFIRM,
	SELECT_TOWER,
	PRESS_UPGRADE,
	CONFIRM_UPGRADE,
	PAUSE_AND_RESUME,
}

# Constants
const LEVEL_ID_TUTORIAL: String = "lev.01"
const TIMELINE_EN_PATH: String = "res://assets/narrative/tutorial_level_01.en.dtl"
const TIMELINE_FR_PATH: String = "res://assets/narrative/tutorial_level_01.fr.dtl"
const UPGRADE_BONUS_COINS: int = 150

# Private variables
var _active_objective: Objective = Objective.NONE
var _connected_cursor: BuildPlacement = null
var _connected_hud: HUD = null
var _connected_towers: Array[ITower] = []
var _is_running: bool = false
var _last_placed_tower: ITower = null
var _place_confirm_tower_count: int = 0
var _pause_resume_waiting_for_resume: bool = false
var _tracked_level: ILevel = null
var _camera_process_was_enabled: bool = true
var _camera_input_was_enabled: bool = true
var _dialog_layout: Node = null
var _dialog_mouse_filter_cache: Dictionary = {}

# Onready variables
@onready var _overlay: TutorialOverlay = $TutorialOverlay

# Core
func _ready() -> void:
	assert(_overlay != null, "tutorial_overlay node not found")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_overlay.hide_overlay()
	Log.trace(Log.Level.DEBUG, "TutorialManager ready: visible=%s running=%s" % [visible, _is_running])

	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)

	if not Dialogic.signal_event.is_connected(_on_dialogic_signal_event):
		Dialogic.signal_event.connect(_on_dialogic_signal_event)

	if not Dialogic.timeline_ended.is_connected(_on_dialogic_timeline_ended):
		Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)

	if not Dialogic.event_handled.is_connected(_on_dialogic_event_handled):
		Dialogic.event_handled.connect(_on_dialogic_event_handled)


func _process(_delta: float) -> void:
	if not _is_running:
		return

	if _connected_cursor == null or not is_instance_valid(_connected_cursor):
		_disconnect_cursor_signals()
		_connect_cursor_signals()
	if _connected_hud == null:
		_connect_hud_signals()

	if _active_objective == Objective.NONE:
		return
	_update_objective_target()
	_try_complete_place_confirm_from_scene()

# Public
## Called when a level starts from the main UI flow.
## [param level] Running level instance
func on_level_started(level: ILevel) -> void:
	Log.trace(Log.Level.DEBUG, "TutorialManager.on_level_started level=%s valid=%s tutorial_completed=%s" % [level, is_instance_valid(level), ProgressionManager.is_tutorial_completed()])
	_tracked_level = level
	if not is_instance_valid(level):
		Log.trace(Log.Level.WARN, "TutorialManager.on_level_started aborted: invalid level")
		_stop_tutorial(false)
		return

	if ProgressionManager.is_tutorial_completed():
		Log.trace(Log.Level.INFO, "TutorialManager.on_level_started aborted: tutorial already completed")
		_stop_tutorial(false)
		return

	if level.level_id != LEVEL_ID_TUTORIAL:
		Log.trace(Log.Level.INFO, "TutorialManager.on_level_started aborted: level_id=%s" % level.level_id)
		_stop_tutorial(false)
		return

	Log.trace(Log.Level.DEBUG, "TutorialManager scheduling _start_tutorial for level_id=%s" % level.level_id)
	call_deferred("_start_tutorial")


## Called when the current level ends.
func on_level_ended() -> void:
	if not _is_running:
		return
	_stop_tutorial(false)

# Private
func _activate_objective(objective: Objective) -> void:
	Log.trace(Log.Level.DEBUG, "Tutorial objective activate: %s -> %s" % [_active_objective, objective])
	_active_objective = objective
	if objective == Objective.PLACE_CONFIRM:
		_place_confirm_tower_count = _count_visible_towers()
		Log.trace(Log.Level.DEBUG, "Tutorial PLACE_CONFIRM baseline tower count=%d" % _place_confirm_tower_count)
	_pause_resume_waiting_for_resume = false
	Dialogic.paused = true
	_pause_level_for_dialogue()
	_set_dialog_layout_input_passthrough(false)
	_set_dialog_layout_visible(not _should_hide_dialog_layout_for_objective(objective))
	_overlay.set_blocking_mode(not _should_use_non_blocking_overlay(objective))
	_update_objective_target()


func _complete_active_objective() -> void:
	var previous_objective: Objective = _active_objective
	if _active_objective == Objective.NONE:
		return
	Log.trace(Log.Level.DEBUG, "Tutorial objective complete: %s" % previous_objective)
	_active_objective = Objective.NONE
	_place_confirm_tower_count = 0
	_pause_resume_waiting_for_resume = false
	_overlay.hide_overlay()
	_pause_level_for_dialogue()
	_set_dialog_layout_input_passthrough(false)
	if previous_objective == Objective.PLACE_CONFIRM and is_instance_valid(_tracked_level):
		_tracked_level.start_wave_flow()
	Dialogic.paused = false


func _connect_cursor_signals() -> void:
	var cursor: BuildPlacement = Global.get("cursor") as BuildPlacement
	Log.trace(Log.Level.DEBUG, "Tutorial connect cursor requested: cursor=%s valid=%s connected=%s" % [cursor, is_instance_valid(cursor), _connected_cursor])
	if cursor == null:
		return
	_connect_cursor_signals_for(cursor)


func _connect_cursor_signals_for(cursor: BuildPlacement) -> void:
	if cursor == null:
		return
	if _connected_cursor == cursor:
		Log.trace(Log.Level.DEBUG, "Tutorial cursor already connected")
		return

	if _connected_cursor != null:
		_disconnect_cursor_signals()

	_connected_cursor = cursor
	Log.trace(Log.Level.DEBUG, "Tutorial cursor connected: %s" % _connected_cursor)
	if not _connected_cursor.trigger_state_build.is_connected(_on_cursor_trigger_state_build):
		_connected_cursor.trigger_state_build.connect(_on_cursor_trigger_state_build)
	if not _connected_cursor.building_placed.is_connected(_on_cursor_building_placed):
		_connected_cursor.building_placed.connect(_on_cursor_building_placed)


func _connect_hud_signals() -> void:
	if Global.hud == null:
		Log.trace(Log.Level.DEBUG, "Tutorial connect HUD skipped: Global.hud is null")
		return
	if _connected_hud == Global.hud:
		Log.trace(Log.Level.DEBUG, "Tutorial HUD already connected")
		return

	if _connected_hud != null:
		_disconnect_hud_signals()

	_connected_hud = Global.hud
	Log.trace(Log.Level.DEBUG, "Tutorial HUD connected: %s" % _connected_hud)
	if not _connected_hud.pause_requested.is_connected(_on_hud_pause_requested):
		_connected_hud.pause_requested.connect(_on_hud_pause_requested)
	if not _connected_hud.build_menu_opened.is_connected(_on_hud_build_menu_opened):
		_connected_hud.build_menu_opened.connect(_on_hud_build_menu_opened)


func _connect_tower_signal(tower: ITower) -> void:
	if tower == null:
		return
	if tower in _connected_towers:
		Log.trace(Log.Level.DEBUG, "Tutorial tower already connected: %s" % tower)
		return
	Log.trace(Log.Level.DEBUG, "Tutorial tower connected: %s" % tower)
	if not tower.upgrade_completed.is_connected(_on_tower_upgrade_completed):
		tower.upgrade_completed.connect(_on_tower_upgrade_completed)
	_connected_towers.append(tower)


func _connect_visible_towers() -> void:
	if not is_instance_valid(_tracked_level):
		Log.trace(Log.Level.DEBUG, "Tutorial visible tower scan skipped: tracked level invalid")
		return
	if not is_instance_valid(_tracked_level.map):
		Log.trace(Log.Level.DEBUG, "Tutorial visible tower scan skipped: map invalid")
		return

	Log.trace(Log.Level.DEBUG, "Tutorial scanning visible towers in map children=%d" % _tracked_level.map.get_child_count())
	for child in _tracked_level.map.get_children():
		if child is ITower:
			_connect_tower_signal(child as ITower)


func _count_visible_towers() -> int:
	if not is_instance_valid(_tracked_level):
		return 0
	if not is_instance_valid(_tracked_level.map):
		return 0

	var tower_count: int = 0
	for child in _tracked_level.map.get_children():
		if child is ITower:
			tower_count += 1
	return tower_count


func _find_latest_visible_tower() -> ITower:
	if not is_instance_valid(_tracked_level):
		return null
	if not is_instance_valid(_tracked_level.map):
		return null

	for index in range(_tracked_level.map.get_child_count() - 1, -1, -1):
		var child: Node = _tracked_level.map.get_child(index)
		if child is ITower:
			return child as ITower

	return null


func _disconnect_cursor_signals() -> void:
	if _connected_cursor == null:
		return
	if not is_instance_valid(_connected_cursor):
		Log.trace(Log.Level.WARN, "Tutorial cursor became invalid before disconnect")
		_connected_cursor = null
		return
	if _connected_cursor.trigger_state_build.is_connected(_on_cursor_trigger_state_build):
		_connected_cursor.trigger_state_build.disconnect(_on_cursor_trigger_state_build)
	if _connected_cursor.building_placed.is_connected(_on_cursor_building_placed):
		_connected_cursor.building_placed.disconnect(_on_cursor_building_placed)
	_connected_cursor = null


func _disconnect_hud_signals() -> void:
	if _connected_hud == null:
		return
	if _connected_hud.pause_requested.is_connected(_on_hud_pause_requested):
		_connected_hud.pause_requested.disconnect(_on_hud_pause_requested)
	if _connected_hud.build_menu_opened.is_connected(_on_hud_build_menu_opened):
		_connected_hud.build_menu_opened.disconnect(_on_hud_build_menu_opened)
	_connected_hud = null


func _disconnect_tower_signals() -> void:
	for tower in _connected_towers:
		if not is_instance_valid(tower):
			continue
		if tower.upgrade_completed.is_connected(_on_tower_upgrade_completed):
			tower.upgrade_completed.disconnect(_on_tower_upgrade_completed)
	_connected_towers.clear()


func _find_first_build_card_button() -> Control:
	if Global.ui == null:
		return null

	var build_selection: BuildSelection = Global.ui.get_node_or_null("BuildSelection") as BuildSelection
	if build_selection == null:
		return null

	var cards: Array[Node] = build_selection.find_children("*", "BuildCard", true, false)
	for card_node in cards:
		if not card_node is BuildCard:
			continue
		var card: BuildCard = card_node as BuildCard
		if card.button_texture == null:
			continue
		if card.button_texture.disabled:
			continue
		return card.button_texture

	return null


func _find_pause_menu() -> Pause:
	if Global.ui == null:
		return null
	return Global.ui.find_child("Pause", true, false) as Pause


func _find_pause_resume_button() -> Control:
	var pause_menu: Pause = _find_pause_menu()
	if pause_menu == null:
		return null
	return pause_menu.play_button


func _find_tower_upgrade_confirm_button() -> Control:
	if Global.ui == null:
		return null

	var menu: TowerUpgradeMenu = Global.ui.find_child("TowerUpgradeMenu", true, false) as TowerUpgradeMenu
	if menu == null:
		return null

	return menu.get_node_or_null("UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/ButtonsHBoxContainer/ConfirmButton") as Control


func _find_upgrade_button_from_radial() -> Control:
	var radial_menu: RadialTowerUpgradeMenu = get_tree().get_root().find_child("TowerUpgrade", true, false) as RadialTowerUpgradeMenu
	if radial_menu == null:
		return null
	return radial_menu.upgrade_button


func _get_timeline_path() -> String:
	var locale: String = TranslationServer.get_locale().to_lower()
	return TIMELINE_FR_PATH if locale.begins_with("fr") else TIMELINE_EN_PATH


func _grant_upgrade_bonus() -> void:
	if not is_instance_valid(_tracked_level):
		return
	if _tracked_level.coins >= UPGRADE_BONUS_COINS:
		return
	_tracked_level.coins = UPGRADE_BONUS_COINS


func _handle_tutorial_event(event_name: String) -> void:
	match event_name:
		"tutorial:open_build_menu":
			_activate_objective(Objective.OPEN_BUILD_MENU)
		"tutorial:select_build_card":
			_activate_objective(Objective.SELECT_BUILD_CARD)
		"tutorial:place_confirm":
			_activate_objective(Objective.PLACE_CONFIRM)
		"tutorial:select_tower":
			_activate_objective(Objective.SELECT_TOWER)
		"tutorial:press_upgrade":
			_activate_objective(Objective.PRESS_UPGRADE)
		"tutorial:confirm_upgrade":
			_activate_objective(Objective.CONFIRM_UPGRADE)
		"tutorial:pause_and_resume":
			_activate_objective(Objective.PAUSE_AND_RESUME)
		"tutorial:grant_upgrade_coins":
			_grant_upgrade_bonus()
		_:
			pass


func _pause_level_for_dialogue() -> void:
	if not is_instance_valid(_tracked_level):
		return
	_tracked_level.pause()
	# Keep tutorial UI interactions available while the world is frozen.
	Global.paused = false


func _resume_level_for_interaction() -> void:
	if not is_instance_valid(_tracked_level):
		return
	_tracked_level.resume_from_pause()
	Global.paused = false


func _center_camera_on_level() -> void:
	if Global.camera == null:
		return
	if not is_instance_valid(_tracked_level):
		return
	if not is_instance_valid(_tracked_level.map):
		return
	if _tracked_level.map.tilemap == null:
		return

	var used_rect: Rect2i = _tracked_level.map.tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return

	var center_cell: Vector2i = used_rect.position + (used_rect.size / 2)
	var center_local: Vector2 = _tracked_level.map.tilemap.map_to_local(center_cell)
	Global.camera.global_position = _tracked_level.map.tilemap.to_global(center_local)


func _lock_camera_for_tutorial() -> void:
	if Global.camera == null:
		return
	_center_camera_on_level()
	_camera_process_was_enabled = Global.camera.is_processing()
	_camera_input_was_enabled = Global.camera.is_processing_input()
	Global.camera.set_process(false)
	Global.camera.set_process_input(false)


func _prepare_dialog_layout_parent() -> void:
	if Global.ui == null:
		return

	if Dialogic.Styles.has_active_layout_node():
		_dialog_layout = Dialogic.Styles.get_layout_node()
		if _dialog_layout != null and _dialog_layout.get_parent() != Global.ui:
			if _dialog_layout.get_parent() != null:
				_dialog_layout.reparent(Global.ui)
			else:
				Global.ui.add_child(_dialog_layout)
	else:
		_dialog_layout = Dialogic.Styles.load_style("", Global.ui)


func _set_dialog_layout_visible(visible_state: bool) -> void:
	if _dialog_layout == null and Dialogic.Styles.has_active_layout_node():
		_dialog_layout = Dialogic.Styles.get_layout_node()
	if _dialog_layout == null:
		return
	_dialog_layout.visible = visible_state


func _set_dialog_layout_input_passthrough(enabled: bool) -> void:
	if _dialog_layout == null and Dialogic.Styles.has_active_layout_node():
		_dialog_layout = Dialogic.Styles.get_layout_node()
	if _dialog_layout == null:
		return

	var controls: Array[Control] = []
	if _dialog_layout is Control:
		controls.append(_dialog_layout as Control)
	for node in _dialog_layout.find_children("*", "Control", true, false):
		if node is Control:
			controls.append(node as Control)

	if enabled:
		for control in controls:
			if not is_instance_valid(control):
				continue
			if not _dialog_mouse_filter_cache.has(control):
				_dialog_mouse_filter_cache[control] = control.mouse_filter
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		for control in _dialog_mouse_filter_cache.keys():
			if not is_instance_valid(control):
				continue
			control.mouse_filter = int(_dialog_mouse_filter_cache[control])
		_dialog_mouse_filter_cache.clear()


func _should_hide_dialog_layout_for_objective(objective: Objective) -> bool:
	match objective:
		Objective.OPEN_BUILD_MENU, Objective.SELECT_BUILD_CARD:
			return true
		_:
			return true


func _should_use_non_blocking_overlay(objective: Objective) -> bool:
	match objective:
		Objective.OPEN_BUILD_MENU, Objective.SELECT_BUILD_CARD:
			return true
		_:
			return false


func _unlock_camera_after_tutorial() -> void:
	if Global.camera == null:
		return
	Global.camera.set_process(_camera_process_was_enabled)
	Global.camera.set_process_input(_camera_input_was_enabled)


func _start_tutorial() -> void:
	if not is_instance_valid(_tracked_level):
		Log.trace(Log.Level.WARN, "Tutorial start aborted: tracked level invalid")
		return
	if ProgressionManager.is_tutorial_completed():
		Log.trace(Log.Level.INFO, "Tutorial start aborted: already completed")
		return
	if _tracked_level.level_id != LEVEL_ID_TUTORIAL:
		Log.trace(Log.Level.INFO, "Tutorial start aborted: tracked level_id=%s" % _tracked_level.level_id)
		return

	Log.trace(Log.Level.INFO, "Tutorial start requested for level_id=%s" % _tracked_level.level_id)
	_is_running = true
	visible = true
	_active_objective = Objective.NONE
	_place_confirm_tower_count = 0
	_pause_resume_waiting_for_resume = false
	_last_placed_tower = null

	_connect_cursor_signals()
	_connect_hud_signals()
	_connect_visible_towers()
	Log.trace(Log.Level.DEBUG, "Tutorial start: connected_cursor=%s connected_hud=%s connected_towers=%d" % [_connected_cursor, _connected_hud, _connected_towers.size()])
	_lock_camera_for_tutorial()
	_pause_level_for_dialogue()
	_prepare_dialog_layout_parent()

	var timeline_path: String = _get_timeline_path()
	Log.trace(Log.Level.INFO, "Tutorial timeline path=%s" % timeline_path)
	var timeline_resource: Resource = load(timeline_path)
	if timeline_resource == null:
		Log.trace(Log.Level.ERROR, "Tutorial timeline not found: %s" % timeline_path)
		_stop_tutorial(false)
		return

	var dialog_layout: Node = Dialogic.start(timeline_resource)
	if dialog_layout != null:
		_dialog_layout = dialog_layout
		Log.trace(Log.Level.DEBUG, "Tutorial dialog layout returned by Dialogic: %s" % _dialog_layout)

	if _dialog_layout == null and Dialogic.Styles.has_active_layout_node():
		_dialog_layout = Dialogic.Styles.get_layout_node()

	if _dialog_layout != null:
		_dialog_layout.process_mode = Node.PROCESS_MODE_ALWAYS
		if _dialog_layout is CanvasItem:
			(_dialog_layout as CanvasItem).z_index = 9000
		_set_dialog_layout_visible(true)
		Log.trace(Log.Level.DEBUG, "Tutorial dialog layout visible and process always")


func _stop_tutorial(mark_completed: bool) -> void:
	Log.trace(Log.Level.INFO, "Tutorial stop requested: mark_completed=%s running=%s active_objective=%s" % [mark_completed, _is_running, _active_objective])
	if mark_completed:
		ProgressionManager.mark_tutorial_completed()

	_is_running = false
	_active_objective = Objective.NONE
	_place_confirm_tower_count = 0
	_pause_resume_waiting_for_resume = false
	visible = false
	_overlay.hide_overlay()
	Dialogic.paused = false
	_set_dialog_layout_input_passthrough(false)
	_set_dialog_layout_visible(true)

	_disconnect_cursor_signals()
	_disconnect_hud_signals()
	_disconnect_tower_signals()
	_unlock_camera_after_tutorial()

	if get_tree().paused:
		get_tree().paused = false
	Global.paused = false

	if is_instance_valid(_tracked_level):
		_tracked_level.resume_from_pause()

	_tracked_level = null
	_dialog_layout = null


func _update_objective_target() -> void:
	if _active_objective == Objective.OPEN_BUILD_MENU or _active_objective == Objective.SELECT_BUILD_CARD:
		_overlay.hide_overlay()
		return

	var target: Control = null

	match _active_objective:
		Objective.OPEN_BUILD_MENU:
			if Global.hud != null:
				target = Global.hud.build_selection_button
		Objective.SELECT_BUILD_CARD:
			target = _find_first_build_card_button()
		Objective.PLACE_CONFIRM:
			if Global.cursor != null:
				target = Global.cursor.place_button
		Objective.SELECT_TOWER:
			if is_instance_valid(_last_placed_tower):
				target = _last_placed_tower.button
			elif _connected_towers.size() > 0 and is_instance_valid(_connected_towers[0]):
				target = _connected_towers[0].button
		Objective.PRESS_UPGRADE:
			target = _find_upgrade_button_from_radial()
		Objective.CONFIRM_UPGRADE:
			target = _find_tower_upgrade_confirm_button()
		Objective.PAUSE_AND_RESUME:
			if _pause_resume_waiting_for_resume:
				target = _find_pause_resume_button()
			else:
				if Global.hud != null:
					target = Global.hud.pause_button
		_:
			pass

	if is_instance_valid(target):
		Log.trace(Log.Level.DEBUG, "Tutorial objective target resolved: objective=%s target=%s" % [_active_objective, target])
		_overlay.show_for_target(target)
	else:
		Log.trace(Log.Level.DEBUG, "Tutorial objective target missing: objective=%s" % _active_objective)
		_overlay.hide_overlay()

# Signal callbacks
func _on_cursor_building_placed(building: IBuilding) -> void:
	Log.trace(Log.Level.DEBUG, "Tutorial cursor building placed: building=%s objective=%s" % [building, _active_objective])
	if building is ITower:
		_last_placed_tower = building as ITower
		_connect_tower_signal(_last_placed_tower)

	if _active_objective == Objective.PLACE_CONFIRM:
		_complete_active_objective()


func _try_complete_place_confirm_from_scene() -> void:
	if _active_objective != Objective.PLACE_CONFIRM:
		return

	var visible_tower_count: int = _count_visible_towers()
	Log.trace(Log.Level.DEBUG, "Tutorial PLACE_CONFIRM fallback check: baseline=%d visible=%d last_tower=%s" % [_place_confirm_tower_count, visible_tower_count, _last_placed_tower])
	if visible_tower_count <= _place_confirm_tower_count:
		return

	var latest_tower: ITower = _find_latest_visible_tower()
	if is_instance_valid(latest_tower):
		_last_placed_tower = latest_tower
		_connect_tower_signal(latest_tower)

	_complete_active_objective()


func _on_cursor_trigger_state_build() -> void:
	if _active_objective == Objective.SELECT_BUILD_CARD:
		_complete_active_objective()


func _on_dialogic_signal_event(argument: Variant) -> void:
	if not _is_running:
		return
	if typeof(argument) != TYPE_STRING:
		return
	Log.trace(Log.Level.DEBUG, "Tutorial Dialogic signal: %s" % argument)
	_handle_tutorial_event(argument as String)


func _on_dialogic_event_handled(event: DialogicEvent) -> void:
	if not _is_running:
		return
	Log.trace(Log.Level.DEBUG, "Tutorial Dialogic event handled: %s" % event)
	if event is DialogicCharacterEvent or event is DialogicTextEvent:
		_set_dialog_layout_visible(true)


func _on_dialogic_timeline_ended() -> void:
	if not _is_running:
		return
	Log.trace(Log.Level.INFO, "Tutorial timeline ended")
	_stop_tutorial(true)


func _on_hud_pause_requested() -> void:
	Log.trace(Log.Level.DEBUG, "Tutorial HUD pause requested: objective=%s waiting_resume=%s" % [_active_objective, _pause_resume_waiting_for_resume])
	if _active_objective != Objective.PAUSE_AND_RESUME:
		return
	if _pause_resume_waiting_for_resume:
		return

	_pause_resume_waiting_for_resume = true
	_update_objective_target()


func _on_pause_menu_resumed() -> void:
	Log.trace(Log.Level.DEBUG, "Tutorial pause menu resumed: objective=%s waiting_resume=%s" % [_active_objective, _pause_resume_waiting_for_resume])
	if _active_objective != Objective.PAUSE_AND_RESUME:
		return
	if not _pause_resume_waiting_for_resume:
		return
	_complete_active_objective()


func _on_tower_upgrade_completed() -> void:
	Log.trace(Log.Level.DEBUG, "Tutorial tower upgrade completed: objective=%s" % _active_objective)
	if _active_objective == Objective.CONFIRM_UPGRADE:
		_complete_active_objective()


func _on_tree_node_added(node: Node) -> void:
	if not _is_running:
		return
	Log.trace(Log.Level.DEBUG, "Tutorial tree node added: %s" % node)

	if node is BuildPlacement:
		Log.trace(Log.Level.DEBUG, "Tutorial detected BuildPlacement node: %s" % node)
		_connect_cursor_signals_for(node as BuildPlacement)

	if node is ITower:
		_connect_tower_signal(node as ITower)

	if node is RadialTowerUpgradeMenu and _active_objective == Objective.SELECT_TOWER:
		_complete_active_objective()
		return

	if node is TowerUpgradeMenu and _active_objective == Objective.PRESS_UPGRADE:
		var upgrade_menu: TowerUpgradeMenu = node as TowerUpgradeMenu
		if not upgrade_menu.upgrade_confirmed.is_connected(_on_upgrade_menu_confirmed):
			upgrade_menu.upgrade_confirmed.connect(_on_upgrade_menu_confirmed)
		_complete_active_objective()
		return

	if node is TowerUpgradeMenu:
		var confirm_menu: TowerUpgradeMenu = node as TowerUpgradeMenu
		if not confirm_menu.upgrade_confirmed.is_connected(_on_upgrade_menu_confirmed):
			confirm_menu.upgrade_confirmed.connect(_on_upgrade_menu_confirmed)

	if node is Pause:
		var pause_menu: Pause = node as Pause
		if not pause_menu.resumed.is_connected(_on_pause_menu_resumed):
			pause_menu.resumed.connect(_on_pause_menu_resumed)


func _on_upgrade_menu_confirmed() -> void:
	Log.trace(Log.Level.DEBUG, "Tutorial upgrade menu confirmed: objective=%s" % _active_objective)
	if _active_objective == Objective.CONFIRM_UPGRADE:
		_complete_active_objective()


func _on_hud_build_menu_opened() -> void:
	Log.trace(Log.Level.DEBUG, "Tutorial HUD build menu opened: objective=%s" % _active_objective)
	if _active_objective == Objective.OPEN_BUILD_MENU:
		_complete_active_objective()
