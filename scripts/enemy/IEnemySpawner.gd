extends Node2D

## Preload the default zombie scene. This scene should implement the IEnemy interface.
## @property PackedScene default_zombie_scene - The default zombie scene.
var default_zombie_scene: PackedScene = preload("res://scenes/enemy/default_enemy_scene.tscn")

## Array storing different types of zombies. Currently, it only includes 'default'.
## @property Array zombie_types - List of zombie types.
var zombie_types: Array = ['default']

## Called when the node is added to the scene.
## Initializes the enemy and sets up the path for the enemy to follow.
func _ready():
    ## Instantiate the default enemy scene.
    ## @local IEnemy enemy - The instantiated enemy.
    var enemy: IEnemy = default_zombie_scene.instantiate()

    ## Get the Path2D node. This path defines where the enemy will move.
    ## Ensure 'Path2D' node exists in the scene tree.
    ## @local Path2D path - The path node.
    var path: Path2D = get_node('Path2D')

    ## Get the PathFollow2D node from the Path2D. This node allows the enemy to follow the path.
    ## @local PathFollow2D path_follow - The path follow node.
    var path_follow: PathFollow2D = path.get_node('PathFollow2D')

    ## Assign the path_follow to the enemy's path property.
    enemy.path = path_follow

    ## Call the spawn_enemy function to add the enemy to the path.
    spawn_enemy(path_follow, enemy)

## Adds the enemy as a child to the path_follow node.
## @param PathFollow2D path - The path follow node.
## @param IEnemy enemy - The enemy to be added to the path.
func spawn_enemy(path: PathFollow2D, enemy: IEnemy):
    path.add_child(enemy)
