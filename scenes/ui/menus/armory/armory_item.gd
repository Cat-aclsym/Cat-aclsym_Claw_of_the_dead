## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Single unlock card in the armory: preview, star cost, frame by state (locked / affordable / owned / legacy).
## [br]
## Selection is visual only until the player confirms purchase: [member buy_button] only accepts input when the card
## is selected and [method refresh_state] reports prerequisites met, enough stars, not legacy, and not already owned.
class_name ArmoryItem
extends VBoxContainer

## Fired when the buy control confirms a purchase for [param node_id] (parent calls [method ArmoryManager.purchase_node]).
signal buy_requested(node_id: String)

## Fired when the card body is pressed so the parent can show the description panel and selection highlight.
signal selected(node_id: String)

const COLOR_BUY_BLOCKED_MODULATE: Color = Color(0.55, 0.55, 0.55, 1.0)
const COLOR_BUY_LABEL_DEFAULT: Color = Color(0.137255, 0.215686, 0.223529, 1.0)
const COLOR_PRICE_AFFORDABLE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_PRICE_UNAFFORDABLE: Color = Color(0.92, 0.26, 0.22, 1.0)
const CARD_DIM_UNAFFORDABLE: float = 0.82
const CARD_MODULATE_AFFORDABLE: Color = Color.WHITE
const CARD_MODULATE_UNAFFORDABLE: Color = Color(CARD_DIM_UNAFFORDABLE, CARD_DIM_UNAFFORDABLE, CARD_DIM_UNAFFORDABLE, 1.0)
const PRICE_LABEL_MODULATE_VS_DIM: Color = Color(1.0 / CARD_DIM_UNAFFORDABLE, 1.0 / CARD_DIM_UNAFFORDABLE, 1.0 / CARD_DIM_UNAFFORDABLE, 1.0)
const BUY_BUTTON_BLUE: Texture2D = preload("res://assets/ui/buttons/Bouton Bleu.svg")
const BUY_BUTTON_GREEN: Texture2D = preload("res://assets/ui/buttons/Bouton Vert.svg")
const FRAME_BLUE: Texture2D = preload("res://assets/ui/building_cards/Blue Frame.svg")
const FRAME_GREEN: Texture2D = preload("res://assets/ui/building_cards/Green Frame.svg")
const FRAME_GREY: Texture2D = preload("res://assets/ui/building_cards/Grey Frame.svg")

@export var cost_stars: int = 0
@export var icon_texture: Texture2D = null
@export var icon_modulate: Color = Color.WHITE
@export var is_affordable: bool = false
@export var is_legacy_mode: bool = false
@export var is_prerequisites_met: bool = true
@export var is_purchased: bool = false
@export var node_id: String = ""
@export var node_name: String = ""

var _is_card_selected: bool = false

@onready var buy_button: TextureButton = %BuyButton
@onready var buy_label: Label = %BuyLabel
@onready var card_texture_button: TextureButton = %CardTextureButton
@onready var frame_texture_rect: TextureRect = %FrameTextureRect
@onready var preview_texture_rect: TextureRect = %PreviewTextureRect
@onready var price_label: Label = %PriceLabel
@onready var stars_icon_texture_rect: TextureRect = %StarsIconTextureRect
@onready var title_label: Label = %TitleLabel

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: buy_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_buy_button_pressed},
	{SignalUtil.WHO: card_texture_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_card_texture_button_pressed},
]


## Connects signals and applies the initial layout (buy row stays visible to avoid layout jumps when selecting).
func _ready() -> void:
	assert(buy_button != null, "buy_button node not found")
	assert(buy_label != null, "buy_label node not found")
	assert(card_texture_button != null, "card_texture_button node not found")
	assert(frame_texture_rect != null, "frame_texture_rect node not found")
	assert(preview_texture_rect != null, "preview_texture_rect node not found")
	assert(price_label != null, "price_label node not found")
	assert(stars_icon_texture_rect != null, "stars_icon_texture_rect node not found")
	assert(title_label != null, "title_label node not found")
	SignalUtil.connects(signals)
	# Keep button layout space at all times to avoid vertical jumps on selection.
	buy_button.visible = true
	_update_visuals()


## Updates exported mirrors used by [method _update_visuals]: affordability, prereqs, purchase, and legacy bypass.
func refresh_state(affordable: bool, prerequisites_met: bool, purchased: bool, legacy_mode: bool) -> void:
	is_affordable = affordable
	is_prerequisites_met = prerequisites_met
	is_purchased = purchased
	is_legacy_mode = legacy_mode
	_update_visuals()


## Stores selection for the parent; [method _update_visuals] fades the buy row in (alpha) only when this is true and purchase is allowed.
func set_selected(value: bool) -> void:
	_is_card_selected = value
	_update_visuals()


## Emits [signal buy_requested] only when the node can still be bought (stars, prereqs, not legacy).
func _on_buy_button_pressed() -> void:
	if is_purchased or is_legacy_mode or not is_prerequisites_met or not is_affordable:
		return
	buy_requested.emit(node_id)


## Notifies the armory screen to focus this card and open the description panel.
func _on_card_texture_button_pressed() -> void:
	selected.emit(node_id)


## Applies textures, labels, price visibility, disabled/mouse_filter rules, and buy-row alpha from current flags.
func _update_visuals() -> void:
	title_label.text = node_name
	preview_texture_rect.texture = icon_texture
	preview_texture_rect.modulate = icon_modulate
	price_label.text = "%d" % cost_stars
	
	var can_buy: bool = not is_purchased and not is_legacy_mode and is_prerequisites_met and is_affordable
	var only_blocked_by_stars: bool = is_prerequisites_met and not is_affordable and not is_purchased and not is_legacy_mode
	
	# Match build_card.gd color correction
	modulate = CARD_MODULATE_AFFORDABLE if (can_buy or is_purchased or is_legacy_mode) else CARD_MODULATE_UNAFFORDABLE
	
	if not is_affordable and not is_purchased and not is_legacy_mode:
		price_label.modulate = PRICE_LABEL_MODULATE_VS_DIM
		price_label.add_theme_color_override("font_color", COLOR_PRICE_UNAFFORDABLE)
	else:
		price_label.modulate = Color.WHITE
		price_label.add_theme_color_override("font_color", COLOR_PRICE_AFFORDABLE)

	var buy_rgb: Color = Color.WHITE
	if is_purchased:
		buy_button.texture_normal = BUY_BUTTON_GREEN
		frame_texture_rect.texture = FRAME_GREEN
		buy_label.text = tr("ARMORY.OWNED")
		price_label.visible = false
		stars_icon_texture_rect.visible = false
	elif is_legacy_mode:
		buy_button.texture_normal = BUY_BUTTON_BLUE
		frame_texture_rect.texture = FRAME_BLUE
		buy_label.text = tr("ARMORY.LEGACY_SKIP")
		price_label.visible = true
		stars_icon_texture_rect.visible = true
	elif not is_prerequisites_met:
		buy_button.texture_normal = BUY_BUTTON_BLUE
		frame_texture_rect.texture = FRAME_GREY
		buy_label.text = tr("ARMORY.BUY_BLOCKED")
		buy_rgb = COLOR_BUY_BLOCKED_MODULATE
		price_label.visible = true
		stars_icon_texture_rect.visible = true
	elif not is_affordable:
		buy_button.texture_normal = BUY_BUTTON_BLUE
		frame_texture_rect.texture = FRAME_BLUE
		buy_label.text = tr("ARMORY.BUY")
		price_label.visible = true
		stars_icon_texture_rect.visible = true
	else:
		buy_button.texture_normal = BUY_BUTTON_BLUE
		frame_texture_rect.texture = FRAME_BLUE
		buy_label.text = tr("ARMORY.BUY")
		price_label.visible = true
		stars_icon_texture_rect.visible = true
	if only_blocked_by_stars:
		buy_label.add_theme_color_override("font_color", COLOR_PRICE_UNAFFORDABLE)
	else:
		buy_label.add_theme_color_override("font_color", COLOR_BUY_LABEL_DEFAULT)
	
	buy_button.disabled = not can_buy and not only_blocked_by_stars
	var allow_buy_click: bool = _is_card_selected and can_buy
	buy_button.mouse_filter = Control.MOUSE_FILTER_STOP if allow_buy_click else Control.MOUSE_FILTER_IGNORE
	
	var alpha: float = 1.0 if _is_card_selected else 0.0
	buy_button.modulate = Color(buy_rgb.r, buy_rgb.g, buy_rgb.b, alpha)
