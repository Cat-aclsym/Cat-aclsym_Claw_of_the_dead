extends Challenge

func start_monitoring() -> void:
	super.start_monitoring()
	# Always completes on victory
	pass

func check_completion() -> bool:
	return true
