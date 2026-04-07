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

## The container node for the card elements.
@onready var background_texture: TextureRect = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/BackgroundTextureRect
@onready var button_texture: TextureButton = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton
@onready var container: VBoxContainer = $CardVBoxContainer
@onready var price_label: Label = $CardVBoxContainer/CardAspectRatioContainer/CardTextureButton/PriceLabel
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
	assert(title_label != null, "title_label node not found")
	assert(preview_texture_rect != null, "preview_texture_rect node not found")

	_entity = entity.instantiate() as Node2D
	assert(_entity != null, "entity could not be instantiated as Node2D")
	assert("cost" in _entity, "entity must expose a 'cost' property")
	if _entity is ITower:
		(_entity as ITower).apply_stats_from_db()
	elif _entity is ITrap:
		(_entity as ITrap).apply_stats_from_db()
	_cost = int(_entity.cost)
	_sync_title_from_stats_db()
	_apply_entity_preview_texture()
	update()

	SignalUtil.connects(signals)
	ButtonEffects.apply(button_texture)

# public
## Updates the card price label and availability.
## [br]Disables the build button if player doesn't have enough coins.
## [br]Slightly dims the card when unaffordable; price text turns red.
func update() -> void:
	price_label.text = "{0}$".format([_cost])
	var can_afford: bool = ILevel.current_level != null and ILevel.current_level.coins >= _cost
	button_texture.disabled = not can_afford
	modulate = CARD_MODULATE_AFFORDABLE if can_afford else CARD_MODULATE_UNAFFORDABLE
	if can_afford:
		price_label.modulate = Color.WHITE
		price_label.remove_theme_color_override("font_color")
	else:
		price_label.modulate = PRICE_LABEL_MODULATE_VS_DIM
		price_label.add_theme_color_override("font_color", PRICE_LABEL_COLOR_UNAFFORDABLE)

# private
## Fills the card icon from the entity when it uses a [Sprite2D] (e.g. traps). Towers use [AnimatedSprite2D] and keep their scene texture.
func _apply_entity_preview_texture() -> void:
	var sprite_2d := _entity.get_node_or_null("Sprite2D") as Sprite2D
	if sprite_2d == null or sprite_2d.texture == null:
		return
	preview_texture_rect.texture = sprite_2d.texture
	preview_texture_rect.modulate = sprite_2d.modulate

## Handles the build button press event.
## [br]Changes cursor state to build mode and closes the build menu.
func _on_button_texture_pressed() -> void:
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
