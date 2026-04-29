import random
import heapq
from typing import List, Tuple, Dict
from .models import GameMap, TileType, MapStyle, Difficulty, Path

class PathGenerator:
    def __init__(self, width: int, height: int):
        self.width = width
        self.height = height

    def generate_paths(self, style: MapStyle, num_paths: int) -> List[Tuple[Tuple[int, int], Tuple[int, int], List[Tuple[int, int]]]]:
        all_paths_data = []
        used_spawns = set()
        used_exits = set()

        for i in range(num_paths):
            # Paths start and end at the very edges (x=0 and x=width-1)
            # but we'll try to keep them away from the top/bottom water/sand borders (y=0,1 and y=h-1,h-2)
            spawn_y = random.randint(2, self.height - 3)
            while spawn_y in used_spawns: spawn_y = random.randint(2, self.height - 3)
            used_spawns.add(spawn_y)
            spawn = (0, spawn_y)

            exit_y = random.randint(2, self.height - 3)
            while exit_y in used_exits: exit_y = random.randint(2, self.height - 3)
            used_exits.add(exit_y)
            exit_pt = (self.width - 1, exit_y)
            
            existing_points = []
            for _, _, pts in all_paths_data: existing_points.extend(pts)
            
            path = self._weighted_a_star(spawn, exit_pt, style, obstacles=existing_points if i > 0 else None)
            all_paths_data.append((spawn, exit_pt, path))
            
        return all_paths_data

    def _weighted_a_star(self, start: Tuple[int, int], end: Tuple[int, int], style: MapStyle, obstacles: List[Tuple[int, int]] = None) -> List[Tuple[int, int]]:
        if obstacles is None: obstacles = []
        pq = [(0, start)]
        came_from = {start: None}
        cost_so_far = {start: 0}
        weights = self._generate_style_weights(style)

        while pq:
            _, current = heapq.heappop(pq)
            if current == end: break

            for dx, dy in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                neighbor = (current[0] + dx, current[1] + dy)
                if 0 <= neighbor[0] < self.width and 0 <= neighbor[1] < self.height:
                    if neighbor in obstacles: continue
                    
                    # --- ANTI-BACKTRACKING ---
                    # Very high penalty for moving left (away from exit)
                    backtrack_penalty = 0
                    if dx < 0: 
                        backtrack_penalty = 50.0
                    
                    # Also avoid top/bottom edges to leave space for borders
                    edge_penalty = 0
                    if neighbor[1] <= 1 or neighbor[1] >= self.height - 2:
                        edge_penalty = 10.0

                    step_cost = 1 + weights.get(neighbor, 0) + backtrack_penalty + edge_penalty + random.uniform(0, 0.5)
                    new_cost = cost_so_far[current] + step_cost
                    
                    if neighbor not in cost_so_far or new_cost < cost_so_far[neighbor]:
                        cost_so_far[neighbor] = new_cost
                        priority = new_cost + self._heuristic(neighbor, end)
                        heapq.heappush(pq, (priority, neighbor))
                        came_from[neighbor] = current

        path = []
        curr = end
        while curr is not None:
            path.append(curr); curr = came_from.get(curr)
        path.reverse()
        # Nettoyage ultra-sûr: supprimer uniquement les doublons consécutifs.
        cleaned = []
        for p in path:
            if not cleaned or p != cleaned[-1]:
                cleaned.append(p)
        return cleaned

    def _heuristic(self, a: Tuple[int, int], b: Tuple[int, int]) -> float:
        return abs(a[0] - b[0]) + abs(a[1] - b[1])

    def _generate_style_weights(self, style: MapStyle) -> Dict[Tuple[int, int], float]:
        weights = {}
        if style == MapStyle.MANY_TURNS:
            for x in range(self.width):
                for y in range(self.height):
                    if (x + y) % 2 == 0: weights[(x, y)] = 2.0
        elif style == MapStyle.CHOKEPOINTS:
            for x in range(4, self.width - 4, 4):
                gap_y = random.randint(2, self.height - 3)
                for y in range(self.height):
                    if y != gap_y and y != gap_y + 1: weights[(x, y)] = 15.0
        
        for x in range(self.width):
            for y in range(self.height):
                if (x, y) not in weights: weights[(x, y)] = 0
                weights[(x, y)] += random.uniform(0, 1.0)
        return weights
