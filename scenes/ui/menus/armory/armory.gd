## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Meta menu: spend challenge stars on armory nodes (unlocks and tower buffs).
class_name Armory
extends Control

signal menu_close

const _BUFF_TAB_CATEGORY: String = "core_buff"

## Prevents [method _fit_scroll_content_width] re-entry when [signal ScrollContainer.resized] feedback-loops with content min width.
var _fitting_scroll: bool = false

@onready var close_button: TextureButton = %CloseTextureButton
@onready var legacy_label: Label = %LegacyLabel
@onready var nodes_buffs: VBoxContainer = %NodesBuffsVBox
@onready var nodes_buildings: VBoxContainer = %NodesBuildingsVBox
@onready var reset_confirm: ConfirmationDialog = %ResetConfirmDialog
@onready var reset_spent_stars_button: Button = %ResetSpentStarsButton
@onready var scroll_buffs: ScrollContainer = %ScrollBuffs
@onready var scroll_buildings: ScrollContainer = %ScrollBuildings
@onready var stars_label: Label = %StarsLabel
@onready var tab_container: TabContainer = %ArmoryTabs
@onready var title_label: Label = %TitleLabel

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_pressed},
	{SignalUtil.WHO: reset_confirm, SignalUtil.WHAT: "confirmed", SignalUtil.TO: _on_reset_confirm_confirmed},
	{SignalUtil.WHO: reset_spent_stars_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_reset_spent_stars_pressed},
	{SignalUtil.WHO: tab_container, SignalUtil.WHAT: "tab_changed", SignalUtil.TO: _on_tab_changed},
]


func _ready() -> void:
	assert(close_button != null, "close_button node not found")
	assert(legacy_label != null, "legacy_label node not found")
	assert(nodes_buffs != null, "nodes_buffs node not found")
	assert(nodes_buildings != null, "nodes_buildings node not found")
	assert(reset_confirm != null, "reset_confirm node not found")
	assert(reset_spent_stars_button != null, "reset_spent_stars_button node not found")
	assert(scroll_buffs != null, "scroll_buffs node not found")
	assert(scroll_buildings != null, "scroll_buildings node not found")
	assert(stars_label != null, "stars_label node not found")
	assert(tab_container != null, "tab_container node not found")
	assert(title_label != null, "title_label node not found")
	tab_container.set_tab_title(0, tr("ARMORY.TAB.BUILDINGS"))
	tab_container.set_tab_title(1, tr("ARMORY.TAB.BUFFS"))
	reset_confirm.dialog_text = tr("ARMORY.RESET_STARS_CONFIRM")
	reset_confirm.ok_button_text = tr("ARMORY.RESET_CONFIRM_OK")
	reset_spent_stars_button.text = tr("ARMORY.RESET_SPENT_STARS")
	SignalUtil.connects(signals)
	if not scroll_buildings.resized.is_connected(_fit_scroll_content_width):
		scroll_buildings.resized.connect(_fit_scroll_content_width)
	if not scroll_buffs.resized.is_connected(_fit_scroll_content_width):
		scroll_buffs.resized.connect(_fit_scroll_content_width)
	if not ArmoryManager.armory_updated.is_connected(_on_armory_updated):
		ArmoryManager.armory_updated.connect(_on_armory_updated)
	title_label.text = tr("ARMORY.TITLE")
	_refresh()
	await get_tree().process_frame
	_fit_scroll_content_width()


func _add_node_row(parent_vbox: VBoxContainer, node_id: String) -> void:
	var node: Dictionary = ArmoryManager.get_armory_node(node_id)
	if node.is_empty():
		return

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_key: String = "ARMORY.NODE.%s.NAME" % node_id.to_upper()
	var desc_key: String = "ARMORY.NODE.%s.DESC" % node_id.to_upper()
	var name_text: String = tr(name_key)
	if name_text == name_key:
		name_text = node_id
	var desc_text: String = tr(desc_key)
	if desc_text == desc_key:
		desc_text = ""

	var text_v: VBoxContainer = VBoxContainer.new()
	text_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title: Label = Label.new()
	title.text = name_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_v.add_child(title)
	if not desc_text.is_empty():
		var desc: Label = Label.new()
		desc.text = desc_text
		desc.modulate = Color(0.85, 0.9, 0.9)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_v.add_child(desc)

	var cost: int = int(node.get("cost_stars", 0))
	var cost_l: Label = Label.new()
	cost_l.text = tr("ARMORY.STAR_COST") % cost
	cost_l.custom_minimum_size = Vector2(120, 0)
	cost_l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var buy: Button = Button.new()
	buy.custom_minimum_size = Vector2(140, 0)
	buy.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	buy.text = tr("ARMORY.BUY")
	var purchased: bool = ArmoryManager.is_node_purchased(node_id)
	if purchased:
		buy.text = tr("ARMORY.OWNED")
		buy.disabled = true
	elif ProgressionManager.data.armory_legacy_mode:
		buy.text = tr("ARMORY.LEGACY_SKIP")
		buy.disabled = true
	elif ArmoryManager.can_purchase(node_id):
		buy.pressed.connect(_on_buy_pressed.bind(node_id))
	else:
		buy.disabled = true
		if not ArmoryManager.get_available_stars() >= cost:
			buy.text = tr("ARMORY.CANT_AFFORD")
		else:
			buy.text = tr("ARMORY.LOCKED_PREREQ")

	row.add_child(text_v)
	row.add_child(cost_l)
	row.add_child(buy)
	parent_vbox.add_child(row)


func _fit_one_scroll_panel(vbox: VBoxContainer, scroll: ScrollContainer) -> void:
	if scroll == null or vbox == null:
		return
	var w: float = scroll.size.x
	if w <= 1.0:
		return
	vbox.custom_minimum_size.x = w


## ScrollContainer children default to a narrow min width; match viewport width so rows use the full panel.
func _fit_scroll_content_width() -> void:
	if _fitting_scroll:
		return
	_fitting_scroll = true
	_fit_one_scroll_panel(nodes_buildings, scroll_buildings)
	_fit_one_scroll_panel(nodes_buffs, scroll_buffs)
	_fitting_scroll = false


func _is_buff_node(node_def: Dictionary) -> bool:
	return str(node_def.get("category", "")) == _BUFF_TAB_CATEGORY


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


func _on_tab_changed(_tab: int) -> void:
	_fit_scroll_content_width.call_deferred()


func _refresh() -> void:
	while nodes_buildings.get_child_count() > 0:
		var cb: Node = nodes_buildings.get_child(0)
		nodes_buildings.remove_child(cb)
		cb.queue_free()
	while nodes_buffs.get_child_count() > 0:
		var cf: Node = nodes_buffs.get_child(0)
		nodes_buffs.remove_child(cf)
		cf.queue_free()

	legacy_label.visible = ProgressionManager.data.armory_legacy_mode
	if legacy_label.visible:
		legacy_label.text = tr("ARMORY.LEGACY_NOTICE")

	var avail: int = ArmoryManager.get_available_stars()
	var earned: int = ArmoryManager.get_total_earned_stars()
	stars_label.text = tr("ARMORY.STARS_LINE") % [avail, earned]
	reset_spent_stars_button.disabled = ProgressionManager.data.armory_purchased.is_empty()

	for nid in ArmoryManager.get_node_ids_ordered():
		var def: Dictionary = ArmoryManager.get_armory_node(nid)
		if _is_buff_node(def):
			_add_node_row(nodes_buffs, nid)
		else:
			_add_node_row(nodes_buildings, nid)
	_fit_scroll_content_width.call_deferred()
