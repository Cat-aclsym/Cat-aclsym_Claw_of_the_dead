class_name TransitionFactory extends Object


# core


# public
static func create(tr_from: State, tr_to: State, new_callback: Callable) -> Transition:
	return Transition.new(tr_from, tr_to, new_callback)


# private


# signal


# event


# setget

