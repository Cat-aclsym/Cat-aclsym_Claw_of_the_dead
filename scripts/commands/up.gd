## © [2024] A7 Studio. All rights reserved. Trademark.
extends ICommand

# public
## Return descript de la command
func description() -> String:
	return "Upgrade a tower."


func get_args() -> Array[Dictionary]:
	return [
		{"name": "tower_name", "type": Types.ARG_STRING},
		{"name": "path", "type": Types.ARG_INT, "optional": true}
	]


# private
## Method éxécuté lors de l'appel de la commande.
## Rajouter '_' derrière `console` ou `args` si ils ne sont pas utilisées
## Return <0 en cas d'erreur
func _execute(console: Console, args: Array) -> int:

	var tower_name: String = args[0]
	var upgrade_path: int = int(args[1]) if args.size() > 1 else 1

	var tower: ITower = ILevel.current_level.map.get_tower_by_name(tower_name)
	if not tower:
		console.push_error("Tower not found")
		return ERR_UNCONFIGURED

	if not tower.available_upgrade:
		console.push_error("No upgrades available for this tower")
		return ERR_UNCONFIGURED

	tower.start_upgrade(tower.available_upgrade[upgrade_path-1])

	return OK
