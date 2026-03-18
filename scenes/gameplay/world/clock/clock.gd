## © [2024] A7 Studio. All rights reserved. Trademark.
## A tick-based clock system for managing scheduled callbacks in a Godot scene.
##
## NOTES:
## - `tick_rate` defines the interval in seconds between each tick (default: 0.1s).
## - 10 ticks = 1 second
## - The system supports multiple subscribers with independent tick intervals.
## - Internally uses a lightweight `_sub` class to track subscriptions.
##
## EXAMPLE:
## func _ready():
##     var id = $Clock.subscribe(my_function, 5)  # Call `my_function` every 5 ticks
## 
## func my_function():
##     print("Ticked!")
class_name Clock extends Node

var tick_rate: float = 0.1

var _subscribers: Array[_sub] = []
var _last_id: int = 0

@onready var timer: Timer = $Timer


class _sub:
	var _uid: int
	var _i: int
	var _count: int
	var _callback: Callable

	func _init(in_uid: int, callback: Callable, tick_count: int) -> void:
		assert(tick_count > 0)

		_uid = in_uid
		_count = tick_count
		_i = tick_count
		_callback = callback

	func next() -> void:
		_i -= 1
		if _i == 0:
			_exec()	

	func uid() -> int:
		return _uid
	
	func _exec() -> void:
		_i = _count
		_callback.call()


# core
func _ready() -> void:
	_configure()


# public
func start() -> void:
	if ILevel.current_level == null: return
	Log.trace(Log.Level.INFO, "Starting clock");
	timer.connect("timeout", _on_timer_timeout)
	timer.start()


func stop() -> void:
	if ILevel.current_level == null: return
	Log.trace(Log.Level.INFO, "Stoping clock");
	timer.disconnect("timeout", _on_timer_timeout)
	timer.stop()


func subscribe(callback: Callable, tick_count: int = 1) -> int:
	Log.trace(Log.Level.DEBUG, "Subscribing to %s every %d tick(s) -> SUB(%d)" %[callback, tick_count, _last_id+1]);
	_last_id += 1
	var sub := _sub.new(_last_id, callback, tick_count)
	_subscribers.append(sub)
	return _last_id


func unsubscribe(id: int) -> bool:
	for i in range(_subscribers.size()):
		if _subscribers[i].uid() == id:
			_subscribers.remove_at(i)
			return true
	return false


# private
func _configure() -> void:
	stop()
	timer.wait_time = tick_rate
	_subscribers = []


func _tick() -> void:
	for s in _subscribers:
		s.next()


# signal
func _on_timer_timeout() -> void:
	_tick()


# event


# setget
