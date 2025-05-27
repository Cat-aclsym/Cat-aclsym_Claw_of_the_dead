extends Control

class_name TowerUpgradeMenu

var sell_price: int
var upgrade_price: int
var tower: ITower

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

	var upg: IUpgrade = tower.available_upgrade[0].instantiate()
	upgrade_price = upg.price

	upgrade_label.text = str(upgrade_price)+"$"

	SignalUtil.connects(signals)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_close_button_pressed():
	queue_free()

func _on_upgrade_button_pressed():
	tower.start_upgrade(tower.available_upgrade[0])
	_on_close_button_pressed()

func _on_sell_button_pressed():
	tower.sell_tower()
	queue_free()
