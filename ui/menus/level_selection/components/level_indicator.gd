## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Small level indicator on level selection menu
## @experimental
class_name LevelIndicator extends TextureButton

signal selected(indicator: LevelIndicator)

enum Status {
	CURRENT,
	COMPLETED,
	LOCKED,
}

## Palette row of the grey dot ([code]level_dot.png[/code]) for each status, the base is recolored by the palette swap shader.
const ROWS: Dictionary[LevelIndicator.Status, GameButton.Palette] = {
	LevelIndicator.Status.CURRENT: GameButton.Palette.ORANGE,
	LevelIndicator.Status.COMPLETED: GameButton.Palette.GREEN,
	LevelIndicator.Status.LOCKED: GameButton.Palette.BLUE,
}

var level: int = 0
var status: LevelIndicator.Status = LevelIndicator.Status.CURRENT

@onready var label: Label = $Label
@onready var _material: ShaderMaterial = material as ShaderMaterial

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: self, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_pressed}
]


func _ready() -> void:
	assert(label != null, "label node not found")
	assert(_material != null, "A LevelIndicator needs the palette ShaderMaterial.")


func configure(in_level: int, in_status: LevelIndicator.Status) -> void:
	level = in_level
	status = in_status
	SignalUtil.connects(signals)
	update()
	ButtonEffects.apply(self)


func update() -> void:
	label.text = str(level)
	disabled = status == LevelIndicator.Status.LOCKED
	_material.set_shader_parameter(&"palette_row", ROWS[status])


func _on_pressed() -> void:
	selected.emit(self)
