## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Armory tree node card with icon and contextual buy button.
class_name ArmoryItem
extends VBoxContainer

signal buy_requested(node_id: String)
signal selected(node_id: String)

const COLOR_ICON_LOCKED: Color = Color(1.0, 0.58, 0.15, 1.0)
const COLOR_ICON_PURCHASED: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_PRICE_AFFORDABLE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_PRICE_UNAFFORDABLE: Color = Color(0.92, 0.26, 0.22, 1.0)

@export var cost_stars: int = 0
@export var icon_texture: Texture2D = null
@export var is_affordable: bool = false
@export var is_legacy_mode: bool = false
@export var is_locked: bool = false
@export var is_purchased: bool = false
@export var node_id: String = ""

@onready var buy_button: TextureButton = %BuyButton
@onready var buy_label: Label = %BuyLabel
@onready var card_texture_button: TextureButton = %CardTextureButton
@onready var frame_texture_rect: TextureRect = %FrameTextureRect
@onready var preview_texture_rect: TextureRect = %PreviewTextureRect
@onready var price_label: Label = %PriceLabel

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: buy_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_buy_button_pressed},
	{SignalUtil.WHO: card_texture_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_card_texture_button_pressed},
]


func _ready() -> void:
	assert(buy_button != null, "buy_button node not found")
	assert(buy_label != null, "buy_label node not found")
	assert(card_texture_button != null, "card_texture_button node not found")
	assert(frame_texture_rect != null, "frame_texture_rect node not found")
	assert(preview_texture_rect != null, "preview_texture_rect node not found")
	assert(price_label != null, "price_label node not found")
	SignalUtil.connects(signals)
	_update_visuals()


func refresh_state(affordable: bool, locked: bool, purchased: bool, legacy_mode: bool) -> void:
	is_affordable = affordable
	is_locked = locked
	is_purchased = purchased
	is_legacy_mode = legacy_mode
	_update_visuals()


func set_selected(value: bool) -> void:
	buy_button.visible = value


func _on_buy_button_pressed() -> void:
	buy_requested.emit(node_id)


func _on_card_texture_button_pressed() -> void:
	selected.emit(node_id)


func _update_visuals() -> void:
	preview_texture_rect.texture = icon_texture
	price_label.text = "x %d" % cost_stars
	price_label.add_theme_color_override("font_color", COLOR_PRICE_AFFORDABLE if is_affordable else COLOR_PRICE_UNAFFORDABLE)
	if is_purchased:
		frame_texture_rect.modulate = COLOR_ICON_PURCHASED
		buy_label.text = tr("ARMORY.OWNED")
	elif is_legacy_mode:
		frame_texture_rect.modulate = COLOR_ICON_LOCKED
		buy_label.text = tr("ARMORY.LEGACY_SKIP")
	else:
		frame_texture_rect.modulate = COLOR_ICON_LOCKED
		buy_label.text = tr("ARMORY.BUY")
	var can_buy: bool = not is_purchased and not is_legacy_mode and not is_locked and is_affordable
	buy_button.disabled = not can_buy
