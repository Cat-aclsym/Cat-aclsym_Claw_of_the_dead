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

const CARD_DIM_UNAFFORDABLE: float = 0.82
const CARD_MODULATE_AFFORDABLE: Color = Color.WHITE
const CARD_MODULATE_UNAFFORDABLE: Color = Color(CARD_DIM_UNAFFORDABLE, CARD_DIM_UNAFFORDABLE, CARD_DIM_UNAFFORDABLE, 1.0)
const STAR_ICON: Texture2D = preload("res://assets/ui/icons/star.png")

@export var cost_stars: int = 0
@export var icon_modulate: Color = Color.WHITE
@export var icon_texture: Texture2D = null
@export var is_affordable: bool = false
@export var is_legacy_mode: bool = false
@export var is_prerequisites_met: bool = true
@export var is_purchased: bool = false
@export var node_id: String = ""

var _is_card_selected: bool = false

@onready var buy_button: GameButton = %BuyButton
@onready var card_texture_button: TextureButton = %CardTextureButton
@onready var frame_texture_rect: TextureRect = %FrameTextureRect
@onready var preview_texture_rect: TextureRect = %PreviewTextureRect
## Palette swap material of the frame: its row recolors the grey card frame by state.
@onready var _frame_material: ShaderMaterial = frame_texture_rect.material as ShaderMaterial

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: buy_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_buy_button_pressed},
	{SignalUtil.WHO: card_texture_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_card_texture_button_pressed},
]


## Connects signals and applies the initial layout (buy row stays visible to avoid layout jumps when selecting).
func _ready() -> void:
	assert(buy_button != null, "buy_button node not found")
	assert(card_texture_button != null, "card_texture_button node not found")
	assert(frame_texture_rect != null, "frame_texture_rect node not found")
	assert(preview_texture_rect != null, "preview_texture_rect node not found")
	assert(_frame_material != null, "The frame of an ArmoryItem needs the palette ShaderMaterial.")
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
	preview_texture_rect.texture = icon_texture
	preview_texture_rect.modulate = icon_modulate

	var can_buy: bool = not is_purchased and not is_legacy_mode and is_prerequisites_met and is_affordable
	var only_blocked_by_stars: bool = is_prerequisites_met and not is_affordable and not is_purchased and not is_legacy_mode

	# Match build_card.gd color correction
	modulate = CARD_MODULATE_AFFORDABLE if (can_buy or is_purchased or is_legacy_mode) else CARD_MODULATE_UNAFFORDABLE

	var buy_text: String = ""
	var buy_palette: GameButton.Palette = GameButton.Palette.BLUE
	var frame_palette: GameButton.Palette = GameButton.Palette.BLUE
	if is_purchased:
		buy_palette = GameButton.Palette.GREEN
		frame_palette = GameButton.Palette.GREEN
		buy_text = tr("ARMORY.OWNED")
	elif is_legacy_mode:
		buy_text = tr("ARMORY.LEGACY_SKIP")
	elif not is_prerequisites_met:
		frame_palette = GameButton.Palette.GREY
		buy_text = tr("ARMORY.BUY_BLOCKED")
	else:
		buy_text = tr("ARMORY.BUY")
		if only_blocked_by_stars:
			buy_palette = GameButton.Palette.RED

	_frame_material.set_shader_parameter(&"palette_row", frame_palette)
	buy_button.text = ("%s  %d" % [buy_text, cost_stars] if not is_purchased else buy_text).to_upper()
	buy_button.icon = null if is_purchased else STAR_ICON
	buy_button.palette = buy_palette
	# Only a missing prerequisite greys the button: owned, legacy and unaffordable ones keep their color
	buy_button.disabled = not is_purchased and not is_legacy_mode and not is_prerequisites_met
	var allow_buy_click: bool = _is_card_selected and can_buy
	buy_button.mouse_filter = Control.MOUSE_FILTER_STOP if allow_buy_click else Control.MOUSE_FILTER_IGNORE
	buy_button.modulate.a = 1.0 if _is_card_selected else 0.0
