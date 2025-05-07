## © [2024] A7 Studio. All rights reserved. Trademark.

class_name WaveStepCheckEnemies extends WaveStep

# core
func _init(in_data: Dictionary) -> void:
	super._init(WaveStep.Order.CHECK_ENEMIES, in_data)

# public
func exec() -> void:
	pass

func is_over() -> bool:
	return ILevel.current_level._enemies_alive == 0

# private

# signal

# event

# setget 
