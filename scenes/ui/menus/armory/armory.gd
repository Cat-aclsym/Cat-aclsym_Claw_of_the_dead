## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Armory tree menu: spend challenge stars on building unlock nodes.
class_name Armory
extends Control

signal menu_close

const _ARMORY_ITEM_SCENE: PackedScene = preload("res://scenes/ui/menus/armory/armory_item.tscn")
const _FALLBACK_ICON: Texture2D = preload("res://assets/ui/level_selection/window/condition_done.svg")

@onready var close_button: TextureButton = %CloseTextureButton
@onready var description_label: Label = %DescriptionLabel
@onready var items_hbox: HBoxContainer = %ItemsHBox
@onready var legacy_label: Label = %LegacyLabel
@onready var reset_confirm: ConfirmationDialog = %ResetConfirmDialog
@onready var reset_spent_stars_button: Button = %ResetSpentStarsButton
@onready var stars_count_label: Label = %StarsCountLabel
@onready var title_label: Label = %TitleLabel

var _armory_items: Dictionary = {}
var _selected_node_id: String = ""

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_pressed},
	{SignalUtil.WHO: reset_confirm, SignalUtil.WHAT: "confirmed", SignalUtil.TO: _on_reset_confirm_confirmed},
	{SignalUtil.WHO: reset_spent_stars_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_reset_spent_stars_pressed},
]


func _ready() -> void:
	assert(close_button != null, "close_button node not found")
	assert(description_label != null, "description_label node not found")
	assert(items_hbox != null, "items_hbox node not found")
	assert(legacy_label != null, "legacy_label node not found")
	assert(reset_confirm != null, "reset_confirm node not found")
	assert(reset_spent_stars_button != null, "reset_spent_stars_button node not found")
	assert(stars_count_label != null, "stars_count_label node not found")
	assert(title_label != null, "title_label node not found")
	reset_confirm.dialog_text = tr("ARMORY.RESET_STARS_CONFIRM")
	reset_confirm.ok_button_text = tr("ARMORY.RESET_CONFIRM_OK")
	reset_spent_stars_button.text = tr("ARMORY.RESET_SPENT_STARS")
	SignalUtil.connects(signals)
	if not ArmoryManager.armory_updated.is_connected(_on_armory_updated):
		ArmoryManager.armory_updated.connect(_on_armory_updated)
	title_label.text = tr("ARMORY.TITLE")
	_refresh()


func _on_armory_updated() -> void:
	_refresh()


func _on_buy_pressed(node_id: String) -> void:
	ArmoryManager.purchase_node(node_id)


func _on_close_pressed() -> void:
	menu_close.emit()


func _on_reset_confirm_confirmed() -> void:
	ArmoryManager.reset_armory_spending()


func _on_reset_spent_stars_pressed() -> void:
	if reset_spent_stars_button.disabled:
		return
	reset_confirm.popup_centered()


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
	stars_count_label.text = "x %d" % avail
	reset_spent_stars_button.disabled = ProgressionManager.data.armory_purchased.is_empty()

	for nid in ArmoryManager.get_node_ids_ordered():
		var armory_item: ArmoryItem = _create_armory_item(nid)
		if armory_item == null:
			continue
		_armory_items[nid] = armory_item
		items_hbox.add_child(armory_item)
		_sync_armory_item_state(armory_item, nid)
		if _selected_node_id.is_empty():
			_selected_node_id = nid
	if not _selected_node_id.is_empty() and _armory_items.has(_selected_node_id):
		_select_node(_selected_node_id)
	elif items_hbox.get_child_count() > 0:
		var first_item: ArmoryItem = items_hbox.get_child(0) as ArmoryItem
		if first_item != null:
			_select_node(first_item.node_id)


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


func _sync_armory_item_state(item: ArmoryItem, node_id: String) -> void:
	item.refresh_state(
		ArmoryManager.get_available_stars() >= item.cost_stars,
		not ArmoryManager.can_purchase(node_id),
		ArmoryManager.is_node_purchased(node_id),
		ProgressionManager.data.armory_legacy_mode
	)


func _on_buy_requested(node_id: String) -> void:
	ArmoryManager.purchase_node(node_id)


func _on_item_selected(node_id: String) -> void:
	_select_node(node_id)


func _select_node(node_id: String) -> void:
	_selected_node_id = node_id
	for key in _armory_items.keys():
		var item: ArmoryItem = _armory_items.get(key) as ArmoryItem
		if item != null:
			item.set_selected(key == node_id)
	description_label.text = _get_node_description(node_id)


func _get_node_description(node_id: String) -> String:
	var desc_key: String = "ARMORY.NODE.%s.DESC" % node_id.to_upper()
	var desc_text: String = tr(desc_key)
	return "" if desc_text == desc_key else desc_text


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
		var names: PackedStringArray = animated.sprite_frames.get_animation_names()
		if not names.is_empty():
			var texture: Texture2D = animated.sprite_frames.get_frame_texture(names[0], 0)
			entity.queue_free()
			return texture if texture != null else _FALLBACK_ICON
	entity.queue_free()
	return _FALLBACK_ICON
