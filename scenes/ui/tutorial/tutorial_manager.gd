## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Coordinates the first-play tutorial on Level 1.
## Orchestrates Dialogic beats and strict guided interaction objectives.
class_name TutorialManager
extends Control

# Enums
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
const KILLS_TO_ACTIVATE_UPGRADE: int = 5

# Private variables
var _active_objective: Objective = Objective.NONE
var _camera_input_was_enabled: bool = true
var _camera_process_was_enabled: bool = true
var _connected_cursor: BuildPlacement = null
var _connected_hud: HUD = null
var _dialog_layout: Node = null
var _is_running: bool = false
var _kills_after_placement: int = 0
var _last_placed_tower: ITower = null
var _pause_resume_waiting_for_resume: bool = false
var _place_confirm_tower_count: int = 0
var _radial_menu: RadialTowerUpgradeMenu = null
var _tracked_level: ILevel = null
var _upgrade_triggered: bool = false

# Onready variables
@onready var _overlay: TutorialOverlay = $TutorialOverlay

# Core
func _ready() -> void:
	assert(_overlay != null, "tutorial_overlay node not found")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_overlay.hide_overlay()

	SignalUtil.connects([
		{SignalUtil.WHO: get_tree(), SignalUtil.WHAT: "node_added", SignalUtil.TO: _on_tree_node_added},
		{SignalUtil.WHO: Dialogic, SignalUtil.WHAT: "signal_event", SignalUtil.TO: _on_dialogic_signal_event},
		{SignalUtil.WHO: Dialogic, SignalUtil.WHAT: "timeline_ended", SignalUtil.TO: _on_dialogic_timeline_ended},
		{SignalUtil.WHO: Dialogic, SignalUtil.WHAT: "event_handled", SignalUtil.TO: _on_dialogic_event_handled},
	])


func _process(_delta: float) -> void:
	if not _is_running:
		return

	if _connected_cursor == null or not is_instance_valid(_connected_cursor):
		_disconnect_cursor_signals()
		_connect_cursor_signals()
	if _connected_hud == null:
		_connect_hud_signals()

	if not _upgrade_triggered and _active_objective == Objective.NONE:
		if is_instance_valid(_last_placed_tower) and _kills_after_placement >= KILLS_TO_ACTIVATE_UPGRADE:
			_upgrade_triggered = true
			_activate_objective(Objective.SELECT_TOWER)
			return

	if _active_objective == Objective.NONE:
		return
	_update_objective_target()
	_try_complete_place_confirm_from_scene()


# Public
## Called when a level starts from the main UI flow.
func on_level_started(level: ILevel) -> void:
	Log.trace(Log.Level.DEBUG, "TutorialManager.on_level_started level=%s tutorial_completed=%s" % [level, ProgressionManager.is_tutorial_completed()])
	if _is_running:
		_tracked_level = null
		_stop_tutorial(false)
	_tracked_level = level
	if not is_instance_valid(level):
		_stop_tutorial(false)
		return
	if ProgressionManager.is_tutorial_completed() or level.level_id != LEVEL_ID_TUTORIAL:
		_stop_tutorial(false)
		return
	call_deferred("_start_tutorial")


## Called when the current level ends.
func on_level_ended() -> void:
	if _is_running:
		_stop_tutorial(false)


# Private
func _activate_objective(objective: Objective) -> void:
	Log.trace(Log.Level.DEBUG, "Tutorial activate: %s -> %s" % [_active_objective, objective])
	_active_objective = objective
	_pause_resume_waiting_for_resume = false

	if objective == Objective.PLACE_CONFIRM:
		_place_confirm_tower_count = _count_visible_towers()
		var hint: TutorialPlacementHint = _get_placement_hint()
		if is_instance_valid(hint):
			hint.show_hint()

	match objective:
		Objective.SELECT_TOWER, Objective.PRESS_UPGRADE:
			# Game keeps running; menus need time_scale > 0 for their tweens.
			Dialogic.paused = false
			_set_dialog_layout_visible(true)
		Objective.CONFIRM_UPGRADE:
			# Arrow-only step — no dialogue line. Keep game running for UI, stay frozen.
			Dialogic.paused = true
			_set_dialog_layout_visible(false)
		Objective.PAUSE_AND_RESUME:
			# Level must be running so the player can actually press Pause.
			Dialogic.paused = true
			if is_instance_valid(_tracked_level):
				_tracked_level.resume_from_pause()
			_set_dialog_layout_visible(false)
		_:
			Dialogic.paused = true
			_pause_level_for_dialogue()
			_set_dialog_layout_visible(false)

	_update_objective_target()


func _complete_active_objective() -> void:
	var previous: Objective = _active_objective
	if previous == Objective.NONE:
		return
	Log.trace(Log.Level.DEBUG, "Tutorial complete: %s" % previous)
	_active_objective = Objective.NONE
	_place_confirm_tower_count = 0
	_pause_resume_waiting_for_resume = false
	_overlay.hide_overlay()

	if previous == Objective.PLACE_CONFIRM:
		var hint: TutorialPlacementHint = _get_placement_hint()
		if is_instance_valid(hint):
			hint.hide_hint()
		if is_instance_valid(_tracked_level):
			_tracked_level.start_wave_flow()
		_unlock_camera_after_tutorial()
		# _process watches for KILLS_TO_ACTIVATE_UPGRADE then activates SELECT_TOWER.
		return

	if previous == Objective.PAUSE_AND_RESUME:
		Dialogic.paused = false
		return

	_pause_level_for_dialogue()
	Dialogic.paused = false


func _connect_cursor_signals() -> void:
	var cursor: BuildPlacement = Global.get("cursor") as BuildPlacement
	if cursor == null:
		return
	_connect_cursor_signals_for(cursor)


func _connect_cursor_signals_for(cursor: BuildPlacement) -> void:
	if cursor == null or _connected_cursor == cursor:
		return
	if _connected_cursor != null:
		_disconnect_cursor_signals()
	_connected_cursor = cursor
	SignalUtil.connects([
		{SignalUtil.WHO: _connected_cursor, SignalUtil.WHAT: "trigger_state_build", SignalUtil.TO: _on_cursor_trigger_state_build},
		{SignalUtil.WHO: _connected_cursor, SignalUtil.WHAT: "building_placed", SignalUtil.TO: _on_cursor_building_placed},
	])


func _connect_hud_signals() -> void:
	if Global.hud == null or _connected_hud == Global.hud:
		return
	if _connected_hud != null:
		_disconnect_hud_signals()
	_connected_hud = Global.hud
	SignalUtil.connects([
		{SignalUtil.WHO: _connected_hud, SignalUtil.WHAT: "pause_requested", SignalUtil.TO: _on_hud_pause_requested},
		{SignalUtil.WHO: _connected_hud, SignalUtil.WHAT: "build_menu_opened", SignalUtil.TO: _on_hud_build_menu_opened},
	])


func _count_visible_towers() -> int:
	if not is_instance_valid(_tracked_level) or not is_instance_valid(_tracked_level.map):
		return 0
	return _tracked_level.map.get_children().filter(func(c: Node) -> bool: return c is ITower).size()


func _disconnect_cursor_signals() -> void:
	if _connected_cursor == null:
		return
	if not is_instance_valid(_connected_cursor):
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


func _find_first_build_card_button() -> Control:
	var build_selection: Node = get_tree().get_root().find_child("BuildSelection", true, false)
	if build_selection == null:
		return null
	# Target the first non-disabled BuildCard. The card node itself gives a reliable rect;
	# targeting the whole panel puts the arrow far right due to the panel's wide center-x.
	for node: Node in build_selection.find_children("*", "BuildCard", true, false):
		var card: BuildCard = node as BuildCard
		if card != null and card.button_texture != null and not card.button_texture.disabled:
			return card
	return build_selection as Control


func _find_latest_visible_tower() -> ITower:
	if not is_instance_valid(_tracked_level) or not is_instance_valid(_tracked_level.map):
		return null
	for index: int in range(_tracked_level.map.get_child_count() - 1, -1, -1):
		var child: Node = _tracked_level.map.get_child(index)
		if child is ITower:
			return child as ITower
	return null


func _find_pause_menu() -> Pause:
	return Global.ui.find_child("Pause", true, false) as Pause if Global.ui != null else null


func _find_pause_resume_button() -> Control:
	var pause_menu: Pause = _find_pause_menu()
	return pause_menu.play_button if pause_menu != null else null


func _find_tower_upgrade_confirm_button() -> Control:
	if Global.ui == null:
		return null
	var menu: TowerUpgradeMenu = Global.ui.find_child("TowerUpgradeMenu", true, false) as TowerUpgradeMenu
	if menu == null:
		return null
	return menu.get_node_or_null("UpgradeDescriptionTextureRect/UpgradeDescriptionVBoxContainer/ButtonsHBoxContainer/ConfirmButton") as Control


func _focus_camera_on_hint() -> void:
	if Global.camera == null:
		return
	var hint: TutorialPlacementHint = _get_placement_hint()
	if is_instance_valid(hint):
		Global.camera.global_position = hint.global_position
		return
	if not is_instance_valid(_tracked_level) or not is_instance_valid(_tracked_level.map):
		return
	var tm: TileMap = _tracked_level.map.tilemap
	if tm == null:
		return
	var rect: Rect2i = tm.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return
	Global.camera.global_position = tm.to_global(tm.map_to_local(rect.position + rect.size / 2))


func _get_placement_hint() -> TutorialPlacementHint:
	if not is_instance_valid(_tracked_level):
		return null
	if is_instance_valid(_tracked_level.map):
		var hint: TutorialPlacementHint = _tracked_level.map.find_child("TutorialPlacementHint", true, false) as TutorialPlacementHint
		if is_instance_valid(hint):
			return hint
	return _tracked_level.find_child("TutorialPlacementHint", true, false) as TutorialPlacementHint


func _get_radial_menu() -> RadialTowerUpgradeMenu:
	if is_instance_valid(_radial_menu):
		return _radial_menu
	return get_tree().get_root().find_child("TowerUpgrade", true, false) as RadialTowerUpgradeMenu


func _get_timeline_path() -> String:
	return TIMELINE_FR_PATH if TranslationServer.get_locale().to_lower().begins_with("fr") else TIMELINE_EN_PATH


func _handle_tutorial_event(event_name: String) -> void:
	match event_name:
		"tutorial:open_build_menu":
			_activate_objective(Objective.OPEN_BUILD_MENU)
		"tutorial:select_build_card":
			_activate_objective(Objective.SELECT_BUILD_CARD)
		"tutorial:place_confirm":
			_activate_objective(Objective.PLACE_CONFIRM)
		"tutorial:select_tower":
			if not _upgrade_triggered:
				_upgrade_triggered = true
			Dialogic.paused = true
			_set_dialog_layout_visible(false)
		"tutorial:press_upgrade":
			if is_instance_valid(_radial_menu):
				_radial_menu.set_process_input(true)
			Dialogic.paused = true
			_set_dialog_layout_visible(false)
		"tutorial:pause_and_resume":
			_activate_objective(Objective.PAUSE_AND_RESUME)


func _lock_camera_for_tutorial() -> void:
	if Global.camera == null:
		return
	_focus_camera_on_hint()
	_camera_process_was_enabled = Global.camera.is_processing()
	_camera_input_was_enabled = Global.camera.is_processing_input()
	Global.camera.set_process(false)
	Global.camera.set_process_input(false)


func _pause_level_for_dialogue() -> void:
	if not is_instance_valid(_tracked_level):
		return
	_tracked_level.pause()
	Global.paused = false


func _resolve_control_target() -> Control:
	match _active_objective:
		Objective.OPEN_BUILD_MENU:
			return Global.hud.build_selection_button if Global.hud != null else null
		Objective.SELECT_BUILD_CARD:
			return _find_first_build_card_button()
		Objective.CONFIRM_UPGRADE:
			return _find_tower_upgrade_confirm_button()
		Objective.PAUSE_AND_RESUME:
			if _pause_resume_waiting_for_resume:
				return _find_pause_resume_button()
			return Global.hud.pause_button if Global.hud != null else null
	return null


func _set_dialog_layout_visible(visible_state: bool) -> void:
	if _dialog_layout == null and Dialogic.Styles.has_active_layout_node():
		_dialog_layout = Dialogic.Styles.get_layout_node()
	if _dialog_layout != null:
		_dialog_layout.visible = visible_state


func _start_tutorial() -> void:
	if not is_instance_valid(_tracked_level) or ProgressionManager.is_tutorial_completed():
		return
	if _tracked_level.level_id != LEVEL_ID_TUTORIAL:
		return

	Log.trace(Log.Level.INFO, "Tutorial start: level_id=%s" % _tracked_level.level_id)
	_is_running = true
	visible = true
	_active_objective = Objective.NONE
	_camera_input_was_enabled = true
	_camera_process_was_enabled = true
	_kills_after_placement = 0
	_last_placed_tower = null
	_place_confirm_tower_count = 0
	_pause_resume_waiting_for_resume = false
	_radial_menu = null
	_upgrade_triggered = false

	_connect_cursor_signals()
	_connect_hud_signals()
	_lock_camera_for_tutorial()
	_pause_level_for_dialogue()

	var timeline_resource: Resource = load(_get_timeline_path())
	if timeline_resource == null:
		Log.trace(Log.Level.ERROR, "Tutorial timeline not found: %s" % _get_timeline_path())
		_stop_tutorial(false)
		return

	var dialog_layout: Node = Dialogic.start(timeline_resource)
	if dialog_layout != null:
		_dialog_layout = dialog_layout
	if _dialog_layout == null and Dialogic.Styles.has_active_layout_node():
		_dialog_layout = Dialogic.Styles.get_layout_node()

	if _dialog_layout != null:
		_dialog_layout.process_mode = Node.PROCESS_MODE_ALWAYS
		if _dialog_layout is CanvasLayer:
			var cl: CanvasLayer = _dialog_layout as CanvasLayer
			cl.layer = 100
			cl.offset = Vector2.ZERO
			cl.follow_viewport_enabled = false
		elif _dialog_layout is CanvasItem:
			(_dialog_layout as CanvasItem).z_index = 9000
		_set_dialog_layout_visible(true)


func _stop_tutorial(mark_completed: bool) -> void:
	Log.trace(Log.Level.INFO, "Tutorial stop: mark_completed=%s" % mark_completed)
	if mark_completed:
		ProgressionManager.mark_tutorial_completed()

	_is_running = false
	_active_objective = Objective.NONE
	_kills_after_placement = 0
	_last_placed_tower = null
	_pause_resume_waiting_for_resume = false
	_place_confirm_tower_count = 0
	_radial_menu = null
	_upgrade_triggered = false
	visible = false
	_overlay.hide_overlay()

	var hint: TutorialPlacementHint = _get_placement_hint()
	if is_instance_valid(hint):
		hint.hide_hint()

	Dialogic.paused = false
	_set_dialog_layout_visible(true)
	_disconnect_cursor_signals()
	_disconnect_hud_signals()
	_unlock_camera_after_tutorial()

	if get_tree().paused:
		get_tree().paused = false
	Global.paused = false

	if is_instance_valid(_tracked_level):
		_tracked_level.resume_from_pause()
	_tracked_level = null
	_dialog_layout = null


func _try_complete_place_confirm_from_scene() -> void:
	if _active_objective != Objective.PLACE_CONFIRM:
		return
	var visible_tower_count: int = _count_visible_towers()
	if visible_tower_count <= _place_confirm_tower_count:
		return
	var latest: ITower = _find_latest_visible_tower()
	if is_instance_valid(latest):
		_last_placed_tower = latest
	_complete_active_objective()


func _unlock_camera_after_tutorial() -> void:
	if Global.camera == null:
		return
	Global.camera.set_process(_camera_process_was_enabled)
	Global.camera.set_process_input(_camera_input_was_enabled)


func _update_objective_target() -> void:
	match _active_objective:
		Objective.NONE:
			_overlay.hide_overlay()
			return
		Objective.PLACE_CONFIRM:
			var hint: TutorialPlacementHint = _get_placement_hint()
			if is_instance_valid(hint):
				_overlay.show_for_world_item(hint, Vector2(64.0, 32.0))
			else:
				_overlay.hide_overlay()
			return
		Objective.SELECT_TOWER:
			if is_instance_valid(_last_placed_tower):
				_overlay.show_for_world_item(_last_placed_tower)
			else:
				_overlay.hide_overlay()
			return
		Objective.PRESS_UPGRADE:
			# RadialTowerUpgradeMenu is a Control child of ITower (world space) — needs
			# canvas→screen conversion. Use radius*2 as the world bounding box.
			var radial: RadialTowerUpgradeMenu = _get_radial_menu()
			if is_instance_valid(radial):
				var diameter: float = radial.radius * 2.0
				_overlay.show_for_world_item(radial, Vector2(diameter, diameter))
			else:
				_overlay.hide_overlay()
			return

	var target: Control = _resolve_control_target()
	if is_instance_valid(target):
		Log.trace(Log.Level.DEBUG, "Tutorial target: %s -> %s" % [_active_objective, target])
		_overlay.show_for_target(target)
	else:
		_overlay.hide_overlay()


# Signal callbacks
func _on_cursor_building_placed(building: IBuilding) -> void:
	if building is ITower:
		_last_placed_tower = building as ITower
	if _active_objective == Objective.PLACE_CONFIRM:
		_complete_active_objective()


func _on_cursor_trigger_state_build() -> void:
	if _active_objective == Objective.SELECT_BUILD_CARD:
		_complete_active_objective()


func _on_dialogic_event_handled(event: DialogicEvent) -> void:
	if not _is_running:
		return
	if event is DialogicCharacterEvent or event is DialogicTextEvent:
		_set_dialog_layout_visible(true)


func _on_dialogic_signal_event(argument: Variant) -> void:
	if not _is_running or typeof(argument) != TYPE_STRING:
		return
	Log.trace(Log.Level.DEBUG, "Tutorial Dialogic signal: %s" % argument)
	_handle_tutorial_event(argument as String)


func _on_dialogic_timeline_ended() -> void:
	if _is_running:
		Log.trace(Log.Level.INFO, "Tutorial timeline ended")
		_stop_tutorial(true)


func _on_enemy_killed() -> void:
	if _upgrade_triggered or _active_objective != Objective.NONE:
		return
	_kills_after_placement += 1
	Log.trace(Log.Level.DEBUG, "Tutorial kill: %d/%d" % [_kills_after_placement, KILLS_TO_ACTIVATE_UPGRADE])


func _on_hud_build_menu_opened() -> void:
	if _active_objective == Objective.OPEN_BUILD_MENU:
		_complete_active_objective()


func _on_hud_pause_requested() -> void:
	if _active_objective != Objective.PAUSE_AND_RESUME or _pause_resume_waiting_for_resume:
		return
	_pause_resume_waiting_for_resume = true
	_update_objective_target()


func _on_pause_menu_resumed() -> void:
	if _active_objective == Objective.PAUSE_AND_RESUME and _pause_resume_waiting_for_resume:
		_complete_active_objective()


func _on_radial_menu_closed() -> void:
	# Radial menu closed without pressing upgrade — let player retry by clicking tower again.
	if _active_objective != Objective.PRESS_UPGRADE:
		return
	_radial_menu = null
	_active_objective = Objective.SELECT_TOWER
	_overlay.hide_overlay()
	_update_objective_target()


func _on_tree_node_added(node: Node) -> void:
	if not _is_running:
		return

	if node is IEnemy and not _upgrade_triggered and is_instance_valid(_last_placed_tower):
		var enemy: IEnemy = node as IEnemy
		SignalUtil.connects([{SignalUtil.WHO: enemy, SignalUtil.WHAT: "die", SignalUtil.TO: _on_enemy_killed}])

	if node is BuildPlacement:
		_connect_cursor_signals_for(node as BuildPlacement)

	if node is RadialTowerUpgradeMenu and _active_objective == Objective.SELECT_TOWER:
		_radial_menu = node as RadialTowerUpgradeMenu
		_radial_menu.set_process_input(false)
		SignalUtil.connects([{SignalUtil.WHO: _radial_menu, SignalUtil.WHAT: "tree_exiting", SignalUtil.TO: _on_radial_menu_closed}])
		_active_objective = Objective.NONE
		_overlay.hide_overlay()
		_activate_objective(Objective.PRESS_UPGRADE)
		return

	if node is TowerUpgradeMenu and _active_objective == Objective.PRESS_UPGRADE:
		var upgrade_menu: TowerUpgradeMenu = node as TowerUpgradeMenu
		SignalUtil.connects([
			{SignalUtil.WHO: upgrade_menu, SignalUtil.WHAT: "upgrade_confirmed", SignalUtil.TO: _on_upgrade_menu_confirmed},
			{SignalUtil.WHO: upgrade_menu, SignalUtil.WHAT: "tree_exiting", SignalUtil.TO: _on_upgrade_menu_closed},
		])
		_active_objective = Objective.NONE
		_overlay.hide_overlay()
		_activate_objective(Objective.CONFIRM_UPGRADE)
		return

	if node is Pause:
		var pause_menu: Pause = node as Pause
		SignalUtil.connects([{SignalUtil.WHO: pause_menu, SignalUtil.WHAT: "resumed", SignalUtil.TO: _on_pause_menu_resumed}])


func _on_upgrade_menu_closed() -> void:
	# Upgrade menu closed without confirming — let player retry from the tower click.
	if _active_objective != Objective.CONFIRM_UPGRADE:
		return
	_active_objective = Objective.SELECT_TOWER
	_overlay.hide_overlay()
	_update_objective_target()


func _on_upgrade_menu_confirmed() -> void:
	if _active_objective == Objective.CONFIRM_UPGRADE:
		_complete_active_objective()
