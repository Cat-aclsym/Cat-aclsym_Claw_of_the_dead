extends Label

var _to: int = -1

# core
func _process(delta: float) -> void:
	if _to == -1: return
	_update()


# functionnal
func start(delay: float) -> void:
	_to = floor(Time.get_unix_time_from_system() + delay)
	visible = true
	_update()
	
# internal
func _update() -> void:
	if Time.get_unix_time_from_system() > _to:
		_to = -1
		visible = false
		return
		
	# Calculate the time remaining until _to
	var time_remaining: float = _to - Time.get_unix_time_from_system()

	# Extract seconds and milliseconds
	var sec: int = floor(time_remaining)
	var ms: int = floor((time_remaining - sec) * 10)

	text = "New wave in {0}.{1}s".format([sec, ms])
