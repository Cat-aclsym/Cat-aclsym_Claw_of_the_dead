## © [2024] A7 Studio. All rights reserved. Trademark.
## The TransitionFactory class creates instances of the Transition class
## It encapsulates the logic for creating transitions in a single place following the Factory Design Pattern

class_name TransitionFactory extends Object


# core


# public
## Static method to create and return a new Transition instance
## [param tr_from]: The state from which the transition begins
## [param tr_to]: The state to which the transition leads
## [param new_callback]: A Callable object which will be executed when this transition is performed
static func create(tr_from: State, tr_to: State, new_callback: Callable) -> Transition:
	return Transition.new(tr_from, tr_to, new_callback)


# private


# signal


# event


# setget

