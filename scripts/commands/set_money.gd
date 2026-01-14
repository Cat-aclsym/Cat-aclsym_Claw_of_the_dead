## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Sets the player's in-game money amount.
## Can only be used when a level is active. Updates the [member ILevel.coins] value.
extends ICommand


# public
func description() -> String:
	return "Set in game money."


func get_args() -> Array[Dictionary]:
	return [{"name": "amount", "type": Types.ARG_INT}]


# private
func _execute(console: Console, args: Array) -> int:
	if not ILevel.current_level:
		console.push_error("You must be in a level to use this method")
		return ERR_UNCONFIGURED

	var amount: int = int(args[0])
	assert(amount >= 0, "Money amount cannot be negative")

	ILevel.current_level.coins = amount

	return OK
