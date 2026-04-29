## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Generic build-card used in the construction menu.
## Can represent any buildable entity (tower or trap) that exposes a `cost` property.
class_name BuildCard
extends Control

const CARD_DIM_UNAFFORDABLE: float = 0.82
const CARD_MODULATE_AFFORDABLE: Color = Color.WHITE
const CARD_MODULATE_UNAFFORDABLE: Color = Color(CARD_DIM_UNAFFORDABLE, CARD_DIM_UNAFFORDABLE, CARD_DIM_UNAFFORDABLE, 1.0)
const PRICE_LABEL_COLOR_UNAFFORDABLE: Color = Color(0.92, 0.26, 0.22, 1.0)
const PRICE_LABEL_MODULATE_VS_DIM: Color = Color(1.0 / CARD_DIM_UNAFFORDABLE, 1.0 / CARD_DIM_UNAFFORDABLE, 1.0 / CARD_DIM_UNAFFORDABLE, 1.0)

## The entity scene to instantiate when building (tower or trap).
@export var entity: PackedScene = null

var _cost: int = 0
var _entity: Node2D = null
var _locked: bool = false

## The container node for the card elements.
@onready var background_texture: TextureRect = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/BackgroundTextureRect
@onready var button_texture: TextureButton = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton
@onready var container: VBoxContainer = $CardVBoxContainer
@onready var price_coin_icon: TextureRect = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/PriceRow/CoinIcon
@onready var price_label: Label = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/PriceRow/PriceLabel
@onready var title_label: Label = $CardVBoxContainer/TitleAspectRatioContainer/TitleTextureRect/TitleLabel
@onready var preview_texture_rect: TextureRect = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/BuildPreviewTextureRect

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: button_texture, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_button_texture_pressed},
]

# core
func _ready() -> void:
	assert(entity != null, "entity scene not assigned")
	assert(background_texture != null, "background_texture node not found")
	assert(button_texture != null, "button_texture node not found")
	assert(container != null, "container node not found")
	assert(price_label != null, "price_label node not found")
	assert(price_coin_icon != null, "price_coin_icon node not found")
	assert(title_label != null, "title_label node not found")
	assert(preview_texture_rect != null, "preview_texture_rect node not found")

	_entity = entity.instantiate() as Node2D
	assert(_entity != null, "entity could not be instantiated as Node2D")
	assert("cost" in _entity, "entity must expose a 'cost' property")
	if _entity is ITower:
		var tw: ITower = _entity as ITower
		tw.apply_stats_from_db()
		ArmoryManager.apply_buffs_to_tower(tw)
	elif _entity is ITrap:
		(_entity as ITrap).apply_stats_from_db()
	_cost = int(_entity.cost)
	_locked = not _is_entity_unlocked()
	_sync_title_from_stats_db()
	_apply_entity_preview_texture()
	update()

	SignalUtil.connects(signals)
	ButtonEffects.apply(button_texture)


func _exit_tree() -> void:
	if is_instance_valid(_entity):
		_entity.free()
		_entity = null

# public
## Updates the card price label and availability.
## [br]If the building is locked (armory), shows [code]BUILD.CARD.LOCKED[/code] instead of the price.
## [br]Disables the build button if locked or if player doesn't have enough coins.
## [br]Slightly dims the card when unaffordable; price text turns red when unaffordable (not when locked).
func update() -> void:
	var can_afford: bool = ILevel.current_level != null and ILevel.current_level.coins >= _cost
	var can_build: bool = not _locked and can_afford
	
	button_texture.disabled = not can_build
	price_coin_icon.visible = not _locked
	modulate = CARD_MODULATE_AFFORDABLE if can_build else CARD_MODULATE_UNAFFORDABLE
	
	if _locked:
		price_label.text = tr("BUILD.CARD.LOCKED")
		price_label.modulate = Color(0.75, 0.78, 0.8, 1.0)
		price_label.remove_theme_color_override("font_color")
	else:
		price_label.text = str(_cost)
		if can_afford:
			price_label.modulate = Color.WHITE
			price_label.remove_theme_color_override("font_color")
		else:
			price_label.modulate = PRICE_LABEL_MODULATE_VS_DIM
			price_label.add_theme_color_override("font_color", PRICE_LABEL_COLOR_UNAFFORDABLE)


# private
## Fills the card icon from the entity. 
## Traps often use [Sprite2D], while Towers use [AnimatedSprite2D] (named 'Sprite').
func _apply_entity_preview_texture() -> void:
	var sprite_node: Node = _entity.get_node_or_null("Sprite")
	if sprite_node == null:
		sprite_node = _entity.get_node_or_null("Sprite2D")
	
	var texture: Texture2D = null
	if sprite_node is Sprite2D:
		texture = sprite_node.texture
	elif sprite_node is AnimatedSprite2D:
		if sprite_node.sprite_frames and sprite_node.sprite_frames.has_animation("idle"):
			texture = sprite_node.sprite_frames.get_frame_texture("idle", 0)
	
	if texture:
		preview_texture_rect.texture = texture

## Handles the build button press event.
## [br]Changes cursor state to build mode and closes the build menu.
func _on_button_texture_pressed() -> void:
	if _locked:
		return
	Global.cursor.change_state(Global.cursor.CursorState.BUILD, [_entity])
	var build_menu := Global.ui.get_node_or_null("BuildSelection")
	if build_menu:
		build_menu.queue_free()

	var build_menu_button: BaseButton = Global.hud.get_node_or_null("BuildSelectionMarginContainer/BuildSelectionButton")
	if build_menu_button:
		build_menu_button.set_pressed_no_signal(false)

## Sets [member title_label] from [StatsDB] when the entity has a [code]tower_id[/code] / [code]trap_id[/code].
func _sync_title_from_stats_db() -> void:
	var display_name: String = ""
	if _entity is ITower:
		var tw: ITower = _entity as ITower
		if not tw.tower_id.is_empty() and StatsDB.has_tower(tw.tower_id):
			display_name = StatsDB.get_tower_name(tw.tower_id)
	elif _entity is ITrap:
		var trap: ITrap = _entity as ITrap
		if not trap.trap_id.is_empty() and StatsDB.has_trap(trap.trap_id):
			display_name = StatsDB.get_trap_name(trap.trap_id)
	if not display_name.is_empty():
		title_label.text = display_name


func _is_entity_unlocked() -> bool:
	if _entity is ITower:
		var tw: ITower = _entity as ITower
		if tw.tower_id.is_empty():
			return true
		return ProgressionManager.is_tower_unlocked(tw.tower_id)
	if _entity is ITrap:
		var trap_entity: ITrap = _entity as ITrap
		if trap_entity.trap_id.is_empty():
			return true
		return ProgressionManager.is_trap_unlocked(trap_entity.trap_id)
	return true
