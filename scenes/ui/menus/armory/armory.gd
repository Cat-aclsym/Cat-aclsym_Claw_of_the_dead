## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Armory tree menu: spend challenge stars on building unlock nodes.
class_name Armory
extends Control

signal menu_close

const _ARMORY_ITEM_SCENE: PackedScene = preload("res://scenes/ui/menus/armory/armory_item.tscn")
const _ARMORY_SCROLL_DRAG_THRESHOLD_PX: float = 12.0
const _FALLBACK_ICON: Texture2D = preload("res://assets/ui/level_selection/window/condition_done.svg")
const _RESET_BUTTON_DISABLED_MODULATE: Color = Color(0.55, 0.55, 0.55, 1.0)
const _RESET_BUTTON_ENABLED_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

var _armory_items: Dictionary = {}
var _armory_scroll_dragging: bool = false
var _armory_scroll_last_global_x: float = 0.0
var _armory_scroll_press_global: Vector2 = Vector2.ZERO
var _armory_scroll_press_valid: bool = false
var _selected_node_id: String = ""

@onready var close_button: TextureButton = %CloseTextureButton
@onready var description_label: Label = %DescriptionLabel
@onready var description_panel: PanelContainer = %DescriptionPanel
@onready var description_title_label: Label = %DescriptionTitleLabel
@onready var items_hbox: HBoxContainer = %ItemsHBox
@onready var legacy_label: Label = %LegacyLabel
@onready var reset_cancel_button: TextureButton = %ResetCancelButton
@onready var reset_confirm_button: TextureButton = %ResetConfirmButton
@onready var reset_confirm_root: Control = %ResetConfirmRoot
@onready var reset_message_label: Label = %ResetMessageLabel
@onready var reset_spent_stars_button: BaseButton = %ResetSpentStarsButton
@onready var reset_spent_stars_label: Label = get_node("MainMargin/VBox/HeaderHBox/ResetSpentStarsButton/ResetSpentStarsLabel") as Label
@onready var scroll_buildings: ScrollContainer = %ScrollBuildings
@onready var stars_count_label: Label = %StarsCountLabel
@onready var title_label: Label = %TitleLabel

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_pressed},
	{SignalUtil.WHO: reset_cancel_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_reset_dialog_cancel_pressed},
	{SignalUtil.WHO: reset_confirm_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_reset_dialog_confirm_pressed},
	{SignalUtil.WHO: reset_spent_stars_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_reset_spent_stars_pressed},
	{SignalUtil.WHO: scroll_buildings, SignalUtil.WHAT: "gui_input", SignalUtil.TO: _on_scroll_buildings_gui_input},
]


func _ready() -> void:
	assert(close_button != null, "close_button node not found")
	assert(description_label != null, "description_label node not found")
	assert(description_panel != null, "description_panel node not found")
	assert(description_title_label != null, "description_title_label node not found")
	assert(items_hbox != null, "items_hbox node not found")
	assert(legacy_label != null, "legacy_label node not found")
	assert(reset_cancel_button != null, "reset_cancel_button node not found")
	assert(reset_confirm_button != null, "reset_confirm_button node not found")
	assert(reset_confirm_root != null, "reset_confirm_root node not found")
	assert(reset_message_label != null, "reset_message_label node not found")
	assert(reset_spent_stars_button != null, "reset_spent_stars_button node not found")
	assert(reset_spent_stars_label != null, "reset_spent_stars_label node not found")
	assert(scroll_buildings != null, "scroll_buildings node not found")
	assert(stars_count_label != null, "stars_count_label node not found")
	assert(title_label != null, "title_label node not found")
	reset_message_label.text = tr("ARMORY.RESET_STARS_CONFIRM")
	(reset_confirm_button.get_node(^"Label") as Label).text = tr("ARMORY.RESET_CONFIRM_OK")
	(reset_cancel_button.get_node(^"Label") as Label).text = tr("ARMORY.RESET_CANCEL")
	SignalUtil.connects(signals)
	if not ArmoryManager.armory_updated.is_connected(_on_armory_updated):
		ArmoryManager.armory_updated.connect(_on_armory_updated)
	title_label.text = tr("ARMORY.TITLE")
	reset_spent_stars_label.text = tr("ARMORY.RESET_SPENT_STARS")
	_refresh()


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
		else:
			if _armory_scroll_dragging:
				get_viewport().set_input_as_handled()
			_armory_scroll_dragging = false
			_armory_scroll_press_valid = false
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


func _clear_selection() -> void:
	_selected_node_id = ""
	for item_ref in _armory_items.values():
		var item: ArmoryItem = item_ref as ArmoryItem
		if item != null:
			item.set_selected(false)
	description_title_label.text = ""
	description_label.text = ""
	description_panel.visible = false


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
	item.icon_texture = _resolve_icon_texture(node)
	if not item.buy_requested.is_connected(_on_buy_requested):
		item.buy_requested.connect(_on_buy_requested)
	if not item.selected.is_connected(_on_item_selected):
		item.selected.connect(_on_item_selected)
	return item


func _extract_preview_texture(scene_path: String) -> Texture2D:
	var packed_scene: PackedScene = StatsDB.load_packed_scene(scene_path)
	if packed_scene == null:
		return _FALLBACK_ICON
	var entity: Node = packed_scene.instantiate()
	if entity == null:
		return _FALLBACK_ICON
	var sprite: Sprite2D = entity.find_child("Sprite2D", true, false) as Sprite2D
	if sprite != null and sprite.texture != null:
		entity.queue_free()
		return sprite.texture
	var animated: AnimatedSprite2D = entity.find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
	if animated != null and animated.sprite_frames != null:
		var animation_name: StringName = &"idle"
		if not animated.sprite_frames.has_animation(animation_name):
			var names: PackedStringArray = animated.sprite_frames.get_animation_names()
			if not names.is_empty():
				animation_name = StringName(names[0])
		if animated.sprite_frames.has_animation(animation_name) and animated.sprite_frames.get_frame_count(animation_name) > 0:
			var texture: Texture2D = animated.sprite_frames.get_frame_texture(animation_name, 0)
			entity.queue_free()
			return texture if texture != null else _FALLBACK_ICON
	entity.queue_free()
	return _FALLBACK_ICON


func _get_node_description(node_id: String) -> String:
	var desc_key: String = "ARMORY.NODE.%s.DESC" % node_id.to_upper()
	var desc_text: String = tr(desc_key)
	return "" if desc_text == desc_key else desc_text


func _get_node_name(node_id: String) -> String:
	var name_key: String = "ARMORY.NODE.%s.NAME" % node_id.to_upper()
	var name_text: String = tr(name_key)
	return node_id if name_text == name_key else name_text


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


func _on_armory_updated() -> void:
	_refresh()


func _on_buy_requested(node_id: String) -> void:
	ArmoryManager.purchase_node(node_id)


func _on_close_pressed() -> void:
	menu_close.emit()


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


func _on_scroll_buildings_gui_input(event: InputEvent) -> void:
	if _selected_node_id.is_empty():
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb == null:
		return
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	for item_ref in _armory_items.values():
		var item: ArmoryItem = item_ref as ArmoryItem
		if item != null and item.get_global_rect().has_point(mb.global_position):
			return
	_clear_selection()


func _refresh() -> void:
	while items_hbox.get_child_count() > 0:
		var cb: Node = items_hbox.get_child(0)
		items_hbox.remove_child(cb)
		cb.queue_free()
	_armory_items.clear()

	legacy_label.visible = ProgressionManager.data.armory_legacy_mode
	if legacy_label.visible:
		legacy_label.text = tr("ARMORY.LEGACY_NOTICE")

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


func _resolve_icon_texture(node: Dictionary) -> Texture2D:
	for effect in node.get("effects", []):
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var effect_type: String = str(effect.get("type", ""))
		if effect_type == "unlock_tower":
			var tower_id: String = str(effect.get("tower_id", ""))
			if StatsDB.has_tower(tower_id):
				var tower: Dictionary = StatsDB.get_tower(tower_id)
				return _extract_preview_texture(str(tower.get("scene", "")))
		elif effect_type == "unlock_trap":
			var trap_id: String = str(effect.get("trap_id", ""))
			if StatsDB.has_trap(trap_id):
				var trap: Dictionary = StatsDB.get_trap(trap_id)
				return _extract_preview_texture(str(trap.get("scene", "")))
	return _FALLBACK_ICON


func _select_node(node_id: String) -> void:
	_selected_node_id = node_id
	for key in _armory_items.keys():
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


func _sync_armory_item_state(item: ArmoryItem, node_id: String) -> void:
	item.refresh_state(
		ArmoryManager.get_available_stars() >= item.cost_stars,
		ArmoryManager.are_prerequisites_met(node_id),
		ArmoryManager.is_node_purchased(node_id),
		ProgressionManager.data.armory_legacy_mode
	)


func _update_reset_button_visual() -> void:
	var is_disabled: bool = reset_spent_stars_button.disabled
	reset_spent_stars_button.modulate = _RESET_BUTTON_DISABLED_MODULATE if is_disabled else _RESET_BUTTON_ENABLED_MODULATE
	reset_spent_stars_label.modulate = _RESET_BUTTON_DISABLED_MODULATE if is_disabled else _RESET_BUTTON_ENABLED_MODULATE
