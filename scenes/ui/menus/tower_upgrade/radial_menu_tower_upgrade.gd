## © [2026] A7 Studio. All rights reserved. Trademark.
##
class_name RadialTowerUpgradeMenu
extends Control

var active: bool = false
var bt_scale: Vector2 = Vector2(0.6, 0.6)
var color_outline: Color = Color8(0xEC, 0x8C, 0x3C)
var outline_line_width: int = 8
var radius: int = 120
var sell_price: int
var shape_scale: float = 0.0:
	set(value):
		shape_scale = clamp(value, 0.0, 1.0)
		queue_redraw()
var speed: float = 0.25
var tower: ITower
var upgrade_price: int

@onready var buttons: Control = $Buttons
@onready var close_button: TextureButton = $Buttons/CloseTextureButton
@onready var info_button: TextureButton = $Buttons/InfoTextureButton
@onready var sell_button: TextureButton = $Buttons/SellTextureButton
@onready var sell_label: Label = $Buttons/SellTextureButton/PriceRow/ValueLabel
@onready var sell_price_row: HBoxContainer = $Buttons/SellTextureButton/PriceRow
@onready var upgrade_button: TextureButton = $Buttons/UpgradeTextureButton
@onready var upgrade_coin_icon: TextureRect = $Buttons/UpgradeTextureButton/PriceRow/CoinIcon
@onready var upgrade_label: Label = $Buttons/UpgradeTextureButton/PriceRow/ValueLabel
@onready var upgrade_price_row: HBoxContainer = $Buttons/UpgradeTextureButton/PriceRow

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_button_pressed},
	{SignalUtil.WHO: info_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_info_button_pressed},
	{SignalUtil.WHO: upgrade_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_upgrade_button_pressed},
	{SignalUtil.WHO: sell_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_sell_button_pressed}
]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(sell_price_row != null, "Sell price row not found")
	assert(upgrade_price_row != null, "Upgrade price row not found")
	assert(sell_label != null, "Sell label not found")
	assert(upgrade_label != null, "Upgrade label not found")
	assert(upgrade_coin_icon != null, "Upgrade coin icon not found")
	tower = get_parent() as ITower
	global_position = tower.global_position
	sell_button.position = Vector2.ZERO
	upgrade_button.position = Vector2.ZERO
	close_button.position = Vector2.ZERO
	buttons.global_position = global_position
	buttons.position = Vector2.ZERO

	sell_price = tower.sell_price
	sell_label.text = str(sell_price)
	if !tower.available_upgrade_ids.is_empty():
		upgrade_price = StatsDB.get_upgrade_price(tower.available_upgrade_ids[0])
		upgrade_label.text = str(upgrade_price)
		upgrade_coin_icon.visible = true
	else:
		upgrade_button.disabled = true
		# Change upgrade button to gray rbg #525252
		upgrade_button.modulate = Color(0.325, 0.325, 0.325)  # Gray color
		upgrade_label.text = tr("TOWER.UPGRADE.MAX")
		upgrade_coin_icon.visible = false
	SignalUtil.connects(signals)

	for b: Control in buttons.get_children():
		b.position = buttons.position
	show_menu()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos: Vector2 = get_global_mouse_position()
		if not _get_menu_bounds_rect().has_point(mouse_pos):
			hide_menu()


func _draw() -> void:
	draw_outline(5 + buttons.get_child_count())


func draw_outline(segments: int) -> void:
	if segments < 3 or shape_scale <= 0.0:
		return

	var current_radius: float = radius * shape_scale

	var points: Array[Vector2] = []
	for i: int in range(segments):
		var angle: float = TAU * float(i) / segments
		points.append(Vector2(cos(angle), sin(angle)) * current_radius)
	points.append(points[0])  # Close the loop

	draw_polyline(points, color_outline, outline_line_width, true)


func hide_menu() -> void:
	active = false
	var tw: Tween = create_tween().set_parallel()
	SignalUtil.connects([{SignalUtil.WHO: tw, SignalUtil.WHAT: "finished", SignalUtil.TO: _on_tween_finished}])
	for b: Control in buttons.get_children():
		tw.tween_property(b, "position", Vector2.ZERO, speed)\
			.set_trans(Tween.TRANS_BACK)
		tw.tween_property(b, "scale", Vector2.ZERO, speed)\
			.set_trans(Tween.TRANS_LINEAR)

		tw.tween_property(sell_price_row, "position", Vector2.ZERO, speed)\
			.set_trans(Tween.TRANS_BACK)
		tw.tween_property(sell_price_row, "scale", Vector2.ZERO, speed)\
			.set_trans(Tween.TRANS_LINEAR)

		tw.tween_property(upgrade_price_row, "position", Vector2.ZERO, speed)\
			.set_trans(Tween.TRANS_BACK)
		tw.tween_property(upgrade_price_row, "scale", Vector2.ZERO, speed)\
			.set_trans(Tween.TRANS_LINEAR)

	tw.tween_property(self, "shape_scale", 0.0, speed)\
		.set_trans(Tween.TRANS_BACK) # or LINEAR / ELASTIC etc.


func show_menu() -> void:
	buttons.show()
	active = true
	var spacing: float = TAU / buttons.get_child_count()
	var tw: Tween = create_tween().set_parallel()
	SignalUtil.connects([{SignalUtil.WHO: tw, SignalUtil.WHAT: "finished", SignalUtil.TO: _on_tween_finished}])
	var index: int = 0
	for b: Control in buttons.get_children():
		# Subtract PI/2 to align the first button  to the top
		var a: float = spacing * index + PI / 2
		var dest: Vector2 = Vector2(radius, 0).rotated(a) - (b.size * bt_scale / 2)
		tw.tween_property(b, "position", dest, speed)\
			.from(buttons.position)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", bt_scale, speed)\
			.from(Vector2.ZERO)\
			.set_trans(Tween.TRANS_LINEAR)
		index += 1

	tw.tween_property(self, "shape_scale", 1.0, speed)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)


func _get_menu_bounds_rect() -> Rect2:
	var bounds: Rect2 = Rect2()
	for b: Node in buttons.get_children():
		if b is Control:
			var r: Rect2 = Rect2(b.global_position, b.size * b.scale)
			if bounds.size == Vector2.ZERO:
				bounds = r
			else:
				bounds = bounds.merge(r)
	var padding: float = 8.0
	return bounds.grow(padding)


func _on_close_button_pressed() -> void:
	hide_menu()


func _on_info_button_pressed() -> void:
	if tower == null:
		return
	var desc_scene: PackedScene = load("res://scenes/ui/menus/tower_upgrade/tower_info.tscn")
	if desc_scene == null:
		Log.trace(Log.Level.ERROR, "Failed to load tower upgrade description scene")
		return
	if Global.hud != null and Global.hud.find_child("TowerInfo", true, false) != null:
		return
	var desc_instance: TowerInfo = desc_scene.instantiate()
	if Global.hud != null:
		Global.hud.add_child(desc_instance)
	else:
		add_child(desc_instance)
	desc_instance.setup(tower)


func _on_sell_button_pressed() -> void:
	tower.sell_tower()
	hide_menu()


func _on_tween_finished() -> void:
	# If menu is not active, hide buttons and free the menu
	if not active:
		buttons.hide()
		queue_free()


func _on_upgrade_button_pressed() -> void:
	if tower == null or tower.available_upgrade_ids.is_empty():
		return
	var upgrade_menu_scene: PackedScene = load("res://scenes/ui/menus/tower_upgrade/tower_upgrade_menu.tscn")
	if upgrade_menu_scene == null:
		Log.trace(Log.Level.ERROR, "Failed to load tower upgrade menu scene")
		return
	if Global.hud != null and Global.hud.find_child("TowerUpgradeMenu", true, false) != null:
		return
	var upgrade_menu_instance: TowerUpgradeMenu = upgrade_menu_scene.instantiate()
	if Global.hud != null:
		Global.hud.add_child(upgrade_menu_instance)
	else:
		add_child(upgrade_menu_instance)
	upgrade_menu_instance.setup(tower, tower.available_upgrade_ids)
	hide_menu()
