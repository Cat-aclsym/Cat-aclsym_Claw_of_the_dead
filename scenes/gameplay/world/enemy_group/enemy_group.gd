## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Contains metadata for a group of enemies to spawn.
class_name EnemyGroup
extends Node


## List of enemies to spawn
@export var enemies: Array[ScenesLoader.EnemyId] = []

## Delay in second between enemies spawn
@export_range(0.1, 10.0) var in_delay: float = 0.1

## Delay in second before next group
@export_range(0.1, 10.0) var out_delay: float = 0.1

## Modifiers applies to all enemies in group [br]
## e.g : [code]{"damage": +15}[/code]
## @experimental
@export var modifiers: Dictionary = {} # TODO
