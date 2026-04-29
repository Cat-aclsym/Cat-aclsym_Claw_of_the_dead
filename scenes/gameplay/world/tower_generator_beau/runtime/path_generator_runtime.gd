## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Générateur de chemins pour les ennemis en runtime.
## Portage GDScript de path_generator.py

class_name PathGeneratorRuntime
extends RefCounted

var width: int
var height: int
var rng: RandomNumberGenerator

func _init(w: int, h: int, random_gen: RandomNumberGenerator = null):
	width = w
	height = h
	if random_gen != null:
		rng = random_gen
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()

## Génère plusieurs chemins selon le style et le nombre demandé.
## Retourne Array de [spawn: Vector2i, exit: Vector2i, points: Array[Vector2i]]
func generate_paths(style: int, num_paths: int) -> Array:
	var all_paths_data: Array = []
	var used_spawns: Array[int] = []
	var used_exits: Array[int] = []
	
	for i in range(num_paths):
		# Génération des points de spawn/exit (éviter les bords eau/sable)
		var spawn_y = _get_unique_y(used_spawns, 2, height - 3)
		used_spawns.append(spawn_y)
		var spawn = Vector2i(0, spawn_y)
		
		var exit_y = _get_unique_y(used_exits, 2, height - 3)
		used_exits.append(exit_y)
		var exit_pt = Vector2i(width - 1, exit_y)
		
		# Collecter les points existants pour éviter les collisions
		var existing_points: Array[Vector2i] = []
		for path_data in all_paths_data:
			existing_points.append_array(path_data[2])
		
		# Générer le chemin avec A* pondéré
		var obstacles_array: Array[Vector2i] = []
		if i > 0:
			obstacles_array = existing_points
		var path_points = weighted_a_star(
			spawn, 
			exit_pt, 
			style, 
			obstacles_array
		)
		
		all_paths_data.append([spawn, exit_pt, path_points])
	
	return all_paths_data

func _get_unique_y(used: Array[int], min_y: int, max_y: int) -> int:
	var y = rng.randi_range(min_y, max_y)
	while used.has(y):
		y = rng.randi_range(min_y, max_y)
	return y

## Algorithme A* pondéré avec anti-backtracking
func weighted_a_star(start: Vector2i, end: Vector2i, style: int, obstacles: Array[Vector2i]) -> Array[Vector2i]:
	var pq: Array[Array] = []  # Priority queue: [[priority, pos], ...]
	var came_from: Dictionary = {}
	var cost_so_far: Dictionary = {}
	var weights = _generate_style_weights(style)
	
	pq.append([0.0, start])
	came_from[start] = null
	cost_so_far[start] = 0.0
	
	while pq.size() > 0:
		# Trier par priorité (plus petit d'abord)
		pq.sort_custom(func(a, b): return a[0] < b[0])
		var current_data = pq.pop_front()
		var current: Vector2i = current_data[1]
		
		if current == end:
			break
		
		# Explorer les voisins
		for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var neighbor = current + dir
			
			if neighbor.x < 0 or neighbor.x >= width or neighbor.y < 0 or neighbor.y >= height:
				continue
			
			# Éviter les obstacles (autres chemins)
			if obstacles.has(neighbor):
				continue
			
			# Anti-backtracking : pénalité élevée pour aller vers la gauche
			var backtrack_penalty = 0.0
			if dir.x < 0:
				backtrack_penalty = 50.0
			
			# Éviter les bords haut/bas pour laisser place aux bordures
			var edge_penalty = 0.0
			if neighbor.y <= 1 or neighbor.y >= height - 2:
				edge_penalty = 10.0
			
			var weight = weights.get(neighbor, 0.0)
			var step_cost = 1.0 + weight + backtrack_penalty + edge_penalty + rng.randf() * 0.5
			var new_cost = cost_so_far[current] + step_cost
			
			if not cost_so_far.has(neighbor) or new_cost < cost_so_far[neighbor]:
				cost_so_far[neighbor] = new_cost
				var priority = new_cost + _heuristic(neighbor, end)
				pq.append([priority, neighbor])
				came_from[neighbor] = current
	
	# Reconstruire le chemin
	var path: Array[Vector2i] = []
	var curr = end
	while curr != null:
		path.append(curr)
		curr = came_from.get(curr, null)
	path.reverse()
	# Nettoyage ultra-sûr: supprimer uniquement les doublons consécutifs.
	var cleaned: Array[Vector2i] = []
	for p in path:
		if cleaned.size() == 0 or p != cleaned[cleaned.size() - 1]:
			cleaned.append(p)
	return cleaned

func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _generate_style_weights(style: int) -> Dictionary:
	var weights: Dictionary = {}
	
	if style == 1:  # MapStyle.MANY_TURNS
		for x in range(width):
			for y in range(height):
				if (x + y) % 2 == 0:
					weights[Vector2i(x, y)] = 2.0
	elif style == 2:  # MapStyle.CHOKEPOINTS
		for x in range(4, width - 4, 4):
			var gap_y = rng.randi_range(2, height - 3)
			for y in range(height):
				if y != gap_y and y != gap_y + 1:
					weights[Vector2i(x, y)] = 15.0
	
	# Ajouter du bruit aléatoire partout
	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)
			if not weights.has(pos):
				weights[pos] = 0.0
			weights[pos] += rng.randf()
	
	return weights
