## © [2024] A7 Studio. All rights reserved. Trademark.
extends ICommand

# public
## Return le nom de la command
func command_token() -> String:
	return "up_tower"


## Return descript de la command
func description() -> String:
	return "Upgrade a tower. Pass the tower's name and the upgrade path (default 1, higher if available). e.g up_tower tower_1 1"


## Return une list des types d'arguments attendu. e.g [ICommand.Types.ARG_INT, ICommand.Types.ARG_INT]
func expected_args_types() -> Array[ICommand.Types]:
	return [ICommand.Types.ARG_STRING, ICommand.Types.ARG_INT]


# private
## Method éxécuté lors de l'appel de la commande.
## Rajouter '_' derrière `console` ou `args` si ils ne sont pas utilisées
## Return <0 en cas d'erreur
func _execute(console: Console, args: Array) -> int:

	var tower_name: String = args[0]
	var upgrade_path: int = int(args[1])

	var tower: ITower = ILevel.current_level.get_tower_by_name(tower_name)
	if not tower:
		console.push_error("Tower not found")
		return ERR_UNCONFIGURED

	if not tower.available_upgrade:
		console.push_error("No upgrades available for this tower")
		return ERR_UNCONFIGURED

	tower.start_upgrade(tower.available_upgrade[upgrade_path-1])

	return OK
