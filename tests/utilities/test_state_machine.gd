## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The state machine moves along the allowed transitions only and ticks the callback of its current state.
extends GdUnitTestSuite

var _ticked: Array[String] = []


func before_test() -> void:
	_ticked.clear()


func test_the_initial_state_is_the_current_state() -> void:
	var machine: StateMachine = _build_machine()

	assert_str(machine.current_state_id).is_equal("IDLE")


func test_an_allowed_transition_changes_the_state() -> void:
	var machine: StateMachine = _build_machine()

	assert_bool(machine.toggle_state("RUN")).is_true()
	assert_str(machine.current_state_id).is_equal("RUN")


func test_an_unallowed_transition_is_refused() -> void:
	var machine: StateMachine = _build_machine()
	machine.toggle_state("RUN")

	# The transitions are one way
	assert_bool(machine.toggle_state("IDLE")).is_false()
	assert_str(machine.current_state_id).is_equal("RUN")


func test_an_unknown_state_is_refused() -> void:
	var machine: StateMachine = _build_machine()

	assert_bool(machine.toggle_state("FLY")).is_false()
	assert_str(machine.current_state_id).is_equal("IDLE")


func test_a_tick_runs_the_callback_of_the_current_state_only() -> void:
	var machine: StateMachine = _build_machine()

	# IDLE has no callback
	machine.tick()
	assert_array(_ticked).is_empty()

	machine.toggle_state("RUN")
	machine.tick()
	machine.tick()
	assert_array(_ticked).contains_exactly(["RUN", "RUN"])


func test_a_tick_callback_can_change_the_state() -> void:
	var machine: StateMachine = StateMachine.new()
	machine.add_state("A", func() -> void: machine.toggle_state("B"), true)
	machine.add_state("B")
	machine.allow("A", "B")

	machine.tick()

	assert_str(machine.current_state_id).is_equal("B")


func _build_machine() -> StateMachine:
	var machine: StateMachine = StateMachine.new()
	machine.add_state("IDLE", Callable(), true)
	machine.add_state("RUN", func() -> void: _ticked.append("RUN"))
	machine.allow("IDLE", "RUN")
	return machine
