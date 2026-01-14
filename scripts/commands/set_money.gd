## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Sets the player's in-game money amount.
## Can only be used when a level is active. Updates the [member ILevel.coins] value.
extends ICommand


# Public functions
func description() -> String:
	return "Sets the current amount of coins available to the player."


func get_args() -> Array[Dictionary]:
	return [{"name": "amount", "type": Types.ARG_INT}]


# Private functions
func _execute(console: Console, args: Array) -> int:
	if not ILevel.current_level:
		console.push_error("You must be in a level to use this command.")
		return ERR_UNKNOWN_BEHAVIOR

	var amount: int = int(args[0])
	if amount < 0:
		console.push_error("Money amount cannot be negative.")
		return ERR_UNKNOWN_BEHAVIOR

	ILevel.current_level.coins = amount
	console.push_text("Set coins to: %d" % amount)

	return OK
