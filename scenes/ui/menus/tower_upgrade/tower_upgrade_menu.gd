class_name TowerUpgradeMenu
extends Control

var sell_price: int
var upgrade_price: int
var tower: ITower
var description_instance: TowerUpgradeDescription
var _description_tween: Tween

@onready var sell_button: TextureButton = $VBoxContainer/HBoxContainer/SellAspectRatioContainer/SellTextureButton
@onready var sell_label: Label = $VBoxContainer/HBoxContainer/SellAspectRatioContainer/SellLabel
@onready var upgrade_button: TextureButton = $VBoxContainer/HBoxContainer/UpgradeAspectRatioContainer/UpgradeTextureButton
@onready var upgrade_label: Label = $VBoxContainer/HBoxContainer/UpgradeAspectRatioContainer/UpgradeLabel
@onready var close_button: TextureButton = $VBoxContainer/CloseAspectRatioContainer/CloseTextureButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_button_pressed},
	{SignalUtil.WHO: upgrade_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_upgrade_button_pressed},
	{SignalUtil.WHO: sell_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_sell_button_pressed}
]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tower = get_parent() as ITower
	sell_price = tower.sell_price
	sell_label.text = str(sell_price)+"$"
	if !tower.available_upgrade.is_empty():
		var upg: IUpgrade = tower.available_upgrade[0].instantiate()
		upgrade_price = upg.price
		upgrade_label.text = str(upgrade_price)+"$"
		_load_upgrade_description(tower.available_upgrade[0])
		upg.queue_free()
	else:
		upgrade_button.disabled = true
		# Change upgrade button to gray rbg #525252
		upgrade_button.modulate = Color(0.325, 0.325, 0.325)  # Gray color
		upgrade_label.text = "MAX"
	SignalUtil.connects(signals)

## Loads and displays the upgrade description panel
func _load_upgrade_description(upgrade_scene: PackedScene) -> void:
	var description_scene: PackedScene = load("res://scenes/ui/menus/tower_upgrade/tower_upgrade_description.tscn")
	if description_scene == null:
		Log.trace(Log.Level.ERROR, "Failed to load tower upgrade description scene")
		return
	
	description_instance = description_scene.instantiate()
	
	# Position the description panel on the right side of the screen, anchored to the right edge
	description_instance.layout_mode = 1
	description_instance.anchors_preset = 9  # Preset for right edge (anchor_right = 1.0)
	description_instance.anchor_left = 0.55
	description_instance.anchor_top = 0.0
	description_instance.anchor_right = 1.0
	description_instance.anchor_bottom = 1.0
	description_instance.offset_left = 0.0
	description_instance.offset_top = 0.0
	description_instance.offset_right = 0.0
	description_instance.offset_bottom = 0.0
	
	# Add to the global HUD instead of to the tower, so it stays fixed on screen
	if Global.hud != null:
		Global.hud.add_child(description_instance)
	else:
		add_child(description_instance)
	
	# Animate slide-in from the left
	_animate_description(true)
	
	# Pass the tower instance and find its scene by checking the scene tree
	description_instance.setup(tower, upgrade_scene)


func _on_close_button_pressed():
	# Also remove the description panel from HUD
	await _animate_description(false)
	queue_free()


func _on_upgrade_button_pressed():
	tower.start_upgrade(tower.available_upgrade[0])
	_on_close_button_pressed()


func _animate_description(show: bool) -> void:
	if description_instance == null:
		return
	if _description_tween and _description_tween.is_running():
		_description_tween.kill()
	
	var viewport_size := get_viewport_rect().size
	var target_x := viewport_size.x * 0.55
	var hidden_x := viewport_size.x + description_instance.size.x
	var start_x := hidden_x if show else description_instance.global_position.x
	var end_x := target_x if show else hidden_x
	
	description_instance.global_position = Vector2(start_x, description_instance.global_position.y) if show else description_instance.global_position
	_description_tween = create_tween()
	_description_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if show else Tween.EASE_IN)
	_description_tween.tween_property(description_instance, "global_position:x", end_x, 0.25)
	if not show:
		await _description_tween.finished
		description_instance.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		var inside_menu := get_global_rect().has_point(pos)
		var inside_desc := description_instance != null and description_instance.get_global_rect().has_point(pos)
		if not inside_menu and not inside_desc:
			_on_close_button_pressed()


func _on_sell_button_pressed():
	tower.sell_tower()
	queue_free()
