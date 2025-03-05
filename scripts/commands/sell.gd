## © [2024] A7 Studio. All rights reserved. Trademark.
extends ICommand

# public
## Return le nom de la command
func command_token() -> String:
	return "sell_tower"


## Return descript de la command
func description() -> String:
	return "Sell a tower. Pass the tower's name. e.g sell_tower tower_1"


## Return une list des types d'arguments attendu. e.g [ICommand.Types.ARG_INT, ICommand.Types.ARG_INT]
func expected_args_types() -> Array[ICommand.Types]:
	return [ICommand.Types.ARG_STRING]


# private
## Method éxécuté lors de l'appel de la commande.
## Rajouter '_' derrière `console` ou `args` si ils ne sont pas utilisées
## Return <0 en cas d'erreur
func _execute(console: Console, args: Array) -> int:

	var tower_name: String = args[0]

	var tower: ITower = ILevel.current_level.get_tower_by_name(tower_name)
	if not tower:
		console.push_error("Tower not found")
		return ERR_UNCONFIGURED

	if not tower.available_upgrade:
		console.push_error("No upgrades available for this tower")
		return ERR_UNCONFIGURED

	tower.sell_tower()

	return OK
