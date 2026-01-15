extends Challenge

func start_monitoring() -> void:
	super.start_monitoring()

func on_tower_placed(tower: Node) -> void:
	# Check if tower is a trap
	if "trap" in tower.name.to_lower():
		fail()
