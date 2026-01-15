extends Challenge

func start_monitoring() -> void:
	super.start_monitoring()

func on_damage_taken(amount: int) -> void:
	# If any damage is taken, fail
	if amount > 0:
		fail()
