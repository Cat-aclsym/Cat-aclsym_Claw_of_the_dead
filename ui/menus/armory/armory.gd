## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Armory tree menu: horizontal list of [ArmoryManager] nodes the player unlocks with challenge stars.
## [br]
## Builds one [ArmoryItem] per configured node, syncs afford/prerequisite/purchase state from [ArmoryManager]
## and [ProgressionManager] (including legacy saves where buildings stay unlocked). Handles drag-to-scroll on
## the buildings strip, description panel when a card is selected, and reset spent stars with confirmation.
class_name Armory
extends Control

## Emitted when the player closes the armory (e.g. back button).
signal menu_close

const _ARMORY_ITEM_SCENE: PackedScene = preload("res://ui/menus/armory/armory_item.tscn")
const _ARMORY_SCROLL_DRAG_THRESHOLD_PX: float = 12.0
## [member ArmoryManager.get_armory_node] category of the nodes that unlock a tower or a trap.
const _BUILDING_CATEGORY: String = "periphery_building"
const _FALLBACK_ICON: Texture2D = preload("res://assets/ui/icons/star.png")
const _RESET_BUTTON_DISABLED_MODULATE: Color = Color(0.55, 0.55, 0.55, 1.0)
const _RESET_BUTTON_ENABLED_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

var _armory_items: Dictionary[String, ArmoryItem] = {}
var _armory_scroll_dragging: bool = false
var _armory_scroll_last_global_x: float = 0.0
var _armory_scroll_press_global: Vector2 = Vector2.ZERO
var _armory_scroll_press_valid: bool = false
var _selected_node_id: String = ""

@onready var close_button: TextureButton = %CloseTextureButton
@onready var description_label: Label = %DescriptionLabel
@onready var description_panel: PanelContainer = %DescriptionPanel
@onready var description_title_label: Label = %DescriptionTitleLabel
@onready var help_button: Button = %HelpButton
@onready var items_hbox: HBoxContainer = %ItemsHBox
@onready var reset_cancel_button: Button = %ResetCancelButton
@onready var reset_confirm_button: Button = %ResetConfirmButton
@onready var reset_confirm_root: Control = %ResetConfirmRoot
@onready var reset_message_label: Label = %ResetMessageLabel
@onready var reset_spent_stars_button: Button = %ResetSpentStarsButton
@onready var scroll_buildings: ScrollContainer = %ScrollBuildings
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_pressed},
	{SignalUtil.WHO: help_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_help_button_pressed},
	{SignalUtil.WHO: reset_cancel_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_reset_dialog_cancel_pressed},
	{SignalUtil.WHO: reset_confirm_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_reset_dialog_confirm_pressed},
	{SignalUtil.WHO: reset_spent_stars_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_reset_spent_stars_pressed},
	{SignalUtil.WHO: ArmoryManager, SignalUtil.WHAT: "armory_updated", SignalUtil.TO: _on_armory_updated},
]
@onready var stars_count_label: Label = %StarsCountLabel
@onready var title_label: Label = %TitleLabel


## Wires UI strings, [ArmoryManager.armory_updated], and initial population via [method _refresh].
func _ready() -> void:
	assert(close_button != null, "close_button node not found")
	assert(description_label != null, "description_label node not found")
	assert(description_panel != null, "description_panel node not found")
	assert(description_title_label != null, "description_title_label node not found")
	assert(help_button != null, "help_button node not found")
	assert(items_hbox != null, "items_hbox node not found")
	assert(reset_cancel_button != null, "reset_cancel_button node not found")
	assert(reset_confirm_button != null, "reset_confirm_button node not found")
	assert(reset_confirm_root != null, "reset_confirm_root node not found")
	assert(reset_message_label != null, "reset_message_label node not found")
	assert(reset_spent_stars_button != null, "reset_spent_stars_button node not found")
	assert(scroll_buildings != null, "scroll_buildings node not found")
	assert(stars_count_label != null, "stars_count_label node not found")
	assert(title_label != null, "title_label node not found")
	SignalUtil.connects(signals)
	_refresh()
	Narrative.play_once(&"armory_intro_seen", "armory_intro")


## Routes pointer drag on [member scroll_buildings] to horizontal scroll; defers clearing selection so item clicks win.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_armory_scroll_press_valid = scroll_buildings.get_global_rect().has_point(mb.global_position)
			if _armory_scroll_press_valid:
				_armory_scroll_press_global = mb.global_position
				_armory_scroll_dragging = false
			_queue_clear_selection_if_background_click(mb.global_position)
		else:
			if _armory_scroll_dragging:
				get_viewport().set_input_as_handled()
			_armory_scroll_dragging = false
			_armory_scroll_press_valid = false
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			_queue_clear_selection_if_background_click(st.position)
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return
		if not _armory_scroll_dragging:
			if not _armory_scroll_press_valid:
				return
			if _armory_scroll_press_global.distance_to(mm.global_position) <= _ARMORY_SCROLL_DRAG_THRESHOLD_PX:
				return
			_armory_scroll_dragging = true
			_armory_scroll_last_global_x = mm.global_position.x - mm.relative.x
		var dx: float = mm.global_position.x - _armory_scroll_last_global_x
		_armory_scroll_last_global_x = mm.global_position.x
		scroll_buildings.scroll_horizontal -= int(round(dx))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		# Same drag is already handled by MouseMotion when emulate_touch_from_mouse is on.
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			return
		var sd: InputEventScreenDrag = event
		if not scroll_buildings.get_global_rect().has_point(sd.position):
			return
		scroll_buildings.scroll_horizontal -= int(round(sd.relative.x))
		get_viewport().set_input_as_handled()


## Clears the selected node, hides the description panel, and deselects all [ArmoryItem] instances.
func _clear_selection() -> void:
	_selected_node_id = ""
	for item_ref: ArmoryItem in _armory_items.values():
		var item: ArmoryItem = item_ref as ArmoryItem
		if item != null:
			item.set_selected(false)
	description_title_label.text = ""
	description_label.text = ""
	description_panel.visible = false


## After GUI controls handle the click (e.g. card selection), clear the description if the hit was outside any item.
func _clear_selection_if_click_missed_items(global_pos: Vector2) -> void:
	if _selected_node_id.is_empty():
		return
	if not is_visible_in_tree():
		return
	for item_ref: ArmoryItem in _armory_items.values():
		var item: ArmoryItem = item_ref as ArmoryItem
		if item != null and item.get_global_rect().has_point(global_pos):
			return
	_clear_selection()


## Instantiates an [ArmoryItem] for [param node_id], sets cost/icon from [ArmoryManager] data, and connects signals.
func _create_armory_item(node_id: String) -> ArmoryItem:
	var node: Dictionary = ArmoryManager.get_armory_node(node_id)
	if node.is_empty():
		return null
	var item: ArmoryItem = _ARMORY_ITEM_SCENE.instantiate() as ArmoryItem
	if item == null:
		return null
	var cost: int = int(node.get("cost_stars", 0))
	item.node_id = node_id
	item.cost_stars = cost
	var preview: SpritePreview = _resolve_icon_data(node)
	item.icon_texture = preview.texture if preview.texture != null else _FALLBACK_ICON
	item.icon_modulate = preview.modulate
	SignalUtil.connects([
		{SignalUtil.WHO: item, SignalUtil.WHAT: "buy_requested", SignalUtil.TO: _on_buy_requested},
		{SignalUtil.WHO: item, SignalUtil.WHAT: "selected", SignalUtil.TO: _on_item_selected},
	])
	return item


## Translation for [code]ARMORY.NODE.{ID}.DESC[/code], or empty if the key is missing.
func _get_node_description(node_id: String) -> String:
	var desc_key: String = "ARMORY.NODE.%s.DESC" % node_id.to_upper()
	var desc_text: String = tr(desc_key)
	return "" if desc_text == desc_key else desc_text


## Translation for [code]ARMORY.NODE.{ID}.NAME[/code], or [param node_id] if the key is missing.
func _get_node_name(node_id: String) -> String:
	var name_key: String = "ARMORY.NODE.%s.NAME" % node_id.to_upper()
	var name_text: String = tr(name_key)
	return node_id if name_text == name_key else name_text


## When prerequisites are unmet, returns [code]ARMORY.PREREQ_BLOCK_DETAIL[/code] with human-readable missing node names.
func _get_prerequisite_block_text(node_id: String) -> String:
	var ids: Array[String] = ArmoryManager.get_unmet_prerequisite_node_ids(node_id)
	if ids.is_empty():
		return _get_node_description(node_id)
	var joined: String = ""
	for i in range(ids.size()):
		if i > 0:
			joined += ", "
		joined += _get_node_name(ids[i])
	return tr("ARMORY.PREREQ_BLOCK_DETAIL") % joined


## Refreshes the list after a purchase or external [ArmoryManager] change.
func _on_armory_updated() -> void:
	_refresh()


func _on_buy_requested(node_id: String) -> void:
	if ArmoryManager.purchase_node(node_id) and ArmoryManager.get_armory_node(node_id).get("category", "") == _BUILDING_CATEGORY:
		Narrative.play_once(&"armory_first_unlock_seen", "armory_first_unlock")


func _on_close_pressed() -> void:
	menu_close.emit()


func _on_help_button_pressed() -> void:
	Dialogic.start(Narrative.timeline_path("armory_intro"))


func _on_item_selected(node_id: String) -> void:
	_select_node(node_id)


func _on_reset_dialog_cancel_pressed() -> void:
	reset_confirm_root.visible = false


func _on_reset_dialog_confirm_pressed() -> void:
	ArmoryManager.reset_armory_spending()
	reset_confirm_root.visible = false


func _on_reset_spent_stars_pressed() -> void:
	if reset_spent_stars_button.disabled:
		return
	reset_confirm_root.visible = true


## Defers [method _clear_selection_if_click_missed_items] so controls under the pointer receive the press first.
func _queue_clear_selection_if_background_click(global_pos: Vector2) -> void:
	if _selected_node_id.is_empty():
		return
	call_deferred("_clear_selection_if_click_missed_items", global_pos)


## Rebuilds the item row from [method ArmoryManager.get_node_ids_ordered], updates star count and reset button state.
func _refresh() -> void:
	while items_hbox.get_child_count() > 0:
		var cb: Node = items_hbox.get_child(0)
		items_hbox.remove_child(cb)
		cb.queue_free()
	_armory_items.clear()

	var avail: int = ArmoryManager.get_available_stars()
	stars_count_label.text = str(avail)
	reset_spent_stars_button.disabled = ProgressionManager.data.armory_purchased.is_empty()
	_update_reset_button_visual()

	for nid in ArmoryManager.get_node_ids_ordered():
		var armory_item: ArmoryItem = _create_armory_item(nid)
		if armory_item == null:
			continue
		_armory_items[nid] = armory_item
		items_hbox.add_child(armory_item)
		_sync_armory_item_state(armory_item, nid)
		armory_item.set_selected(false)
	if not _selected_node_id.is_empty() and _armory_items.has(_selected_node_id):
		_select_node(_selected_node_id)
	else:
		_clear_selection()


## Picks a card icon from the first [code]unlock_tower[/code] or [code]unlock_trap[/code] effect by previewing the linked scene.
## [br]Fallback: tries to find a tower or trap ID within the node ID string.
func _resolve_icon_data(node: Dictionary) -> SpritePreview:
	for effect: Dictionary in node.get("effects", []):
		var effect_type: String = str(effect.get("type", ""))
		if effect_type == "unlock_tower":
			var tower_id: String = str(effect.get("tower_id", ""))
			if StatsDB.has_tower(tower_id):
				return SpritePreview.from_scene(StatsDB.load_packed_scene(str(StatsDB.get_tower(tower_id).get("scene", ""))))
		elif effect_type == "unlock_trap":
			var trap_id: String = str(effect.get("trap_id", ""))
			if StatsDB.has_trap(trap_id):
				return SpritePreview.from_scene(StatsDB.load_packed_scene(str(StatsDB.get_trap(trap_id).get("scene", ""))))

	# Fallback: try to find a tower/trap ID in the node ID (e.g. "unlock_bat_01_branch_a" -> "bat_01")
	var node_id: String = node.get("id", "")
	for tower_id: String in StatsDB.get_tower_ids():
		if tower_id in node_id:
			return SpritePreview.from_scene(StatsDB.load_packed_scene(str(StatsDB.get_tower(tower_id).get("scene", ""))))
	for trap_id: String in StatsDB.get_trap_ids():
		if trap_id in node_id:
			return SpritePreview.from_scene(StatsDB.load_packed_scene(str(StatsDB.get_trap(trap_id).get("scene", ""))))

	return SpritePreview.new()


## Highlights one card, shows title and either prerequisite hint or full description depending on purchase/prereq state.
func _select_node(node_id: String) -> void:
	_selected_node_id = node_id
	for key: String in _armory_items.keys():
		var item: ArmoryItem = _armory_items.get(key) as ArmoryItem
		if item != null:
			item.set_selected(key == node_id)
	description_title_label.text = _get_node_name(node_id)
	var legacy_mode: bool = ProgressionManager.data.armory_legacy_mode
	var purchased: bool = ArmoryManager.is_node_purchased(node_id)
	if not legacy_mode and not purchased and not ArmoryManager.are_prerequisites_met(node_id):
		description_label.text = _get_prerequisite_block_text(node_id)
	else:
		description_label.text = _get_node_description(node_id)
	description_panel.visible = true


## Pushes current stars, prerequisites, purchase, and legacy flags into a single [ArmoryItem] for [method ArmoryItem.refresh_state].
func _sync_armory_item_state(item: ArmoryItem, node_id: String) -> void:
	item.refresh_state(
		ArmoryManager.get_available_stars() >= item.cost_stars,
		ArmoryManager.are_prerequisites_met(node_id),
		ArmoryManager.is_node_purchased(node_id),
		ProgressionManager.data.armory_legacy_mode
	)


## Dims the reset control and its label when there is nothing to reset ([member BaseButton.disabled]).
func _update_reset_button_visual() -> void:
	var is_disabled: bool = reset_spent_stars_button.disabled
	reset_spent_stars_button.modulate = _RESET_BUTTON_DISABLED_MODULATE if is_disabled else _RESET_BUTTON_ENABLED_MODULATE
