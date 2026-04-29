import random
from typing import List, Tuple, Optional
from .models import GameMap, TileType, Path, Difficulty

class MapGenerator:
    def __init__(self, width: int, height: int):
        self.width, self.height = width, height

    def apply_paths_to_map(self, game_map: GameMap, paths_data: List[Tuple[Tuple[int, int], Tuple[int, int], List[Tuple[int, int]]]]):
        for spawn, exit_pt, pts in paths_data:
            game_map.paths.append(Path(pts))
            for x, y in pts: game_map.set_tile_type(x, y, TileType.PATH)
            game_map.set_tile_type(spawn[0], spawn[1], TileType.SPAWN)
            game_map.set_tile_type(exit_pt[0], exit_pt[1], TileType.EXIT)

    def apply_borders(self, game_map: GameMap):
        for x in range(self.width):
            for y in range(self.height):
                tile = game_map.get_tile(x, y)
                if tile.type in [TileType.PATH, TileType.SPAWN, TileType.EXIT]: continue
                # Eau à l'extrémité absolue
                if x == 0 or x == self.width - 1 or y == 0 or y == self.height - 1:
                    tile.type = TileType.WATER
                # Sable juste après l'eau
                elif x == 1 or x == self.width - 2 or y == 1 or y == self.height - 2:
                    tile.type = TileType.SAND

    def generate_buildable_zones(
        self,
        game_map: GameMap,
        density: float,
        enemy_types: List[str],
        difficulty: Optional[Difficulty] = None
    ):
        all_pts = []
        for p in game_map.paths: all_pts.extend(p.points)
        path_set = set(all_pts)
        potential: List = []
        for p in game_map.paths:
            for i, (px, py) in enumerate(p.points):
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nx, ny = px + dx, py + dy
                    tile = game_map.get_tile(nx, ny)
                    if tile and tile.type == TileType.EMPTY:
                        if tile not in potential: potential.append(tile)

        # Calcule un score identique à celui utilisé en runtime GDScript.
        # Cela rend la génération beaucoup plus cohérente et réduit l'aléatoire.
        for tile in potential:
            tile.score = self._calculate_tile_score(game_map, tile.x, tile.y)

        potential.sort(key=lambda t: t.score, reverse=True)
        effective_density = self._difficulty_density_multiplier(difficulty) * density
        effective_density = max(0.0, min(effective_density, 1.0))
        max_b = int(len(potential) * effective_density)
        minimum_buildable = self._minimum_buildable_target(game_map, difficulty)
        max_b = max(max_b, min(minimum_buildable, len(potential)))
        for i, tile in enumerate(potential):
            if i < max_b: tile.type = TileType.BUILDABLE

        # Filet de sécurité: garantir un minimum de zones posables
        # même si les règles de sélection sont trop strictes.
        current_buildable = sum(
            1 for x in range(game_map.width)
            for y in range(game_map.height)
            if game_map.get_tile(x, y) and game_map.get_tile(x, y).type == TileType.BUILDABLE
        )
        if current_buildable < minimum_buildable:
            for tile in potential:
                if current_buildable >= minimum_buildable:
                    break
                if tile.type == TileType.BUILDABLE:
                    continue
                tile.type = TileType.BUILDABLE
                current_buildable += 1

    def _calculate_tile_score(self, game_map: GameMap, x: int, y: int) -> float:
        score = 0.0

        # 1) Distance minimale aux chemins (plus proche = meilleur)
        min_dist = float("inf")
        for path in game_map.paths:
            for px, py in path.points:
                dist = ((x - px) ** 2 + (y - py) ** 2) ** 0.5
                if dist < min_dist:
                    min_dist = dist

        score += 10.0 / (min_dist + 1.0)

        # 2) Nombre de chemins "couverts" (distance <= 2.5)
        paths_in_range = 0
        for path in game_map.paths:
            for px, py in path.points:
                dist = ((x - px) ** 2 + (y - py) ** 2) ** 0.5
                if dist <= 2.5:
                    paths_in_range += 1
                    break

        score += paths_in_range * 5.0
        return score

    def add_decorations(self, game_map: GameMap, density: float):
        # Désactivé temporairement pour préserver la lisibilité:
        # on évite d'ajouter des obstacles décoratifs qui brouillent
        # les zones constructibles.
        return

    def _distance_to_nearest_path(self, game_map: GameMap, x: int, y: int) -> float:
        min_dist = float("inf")
        for path in game_map.paths:
            for px, py in path.points:
                dist = ((x - px) ** 2 + (y - py) ** 2) ** 0.5
                if dist < min_dist:
                    min_dist = dist
        return min_dist

    def _decoration_biome_score(self, game_map: GameMap, x: int, y: int) -> float:
        edge_dist = min(x, self.width - 1 - x, y, self.height - 1 - y)
        edge_score = 1.0 - max(0.0, min(float(edge_dist) / 8.0, 1.0))

        coastal_score = 0.0
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                if dx == 0 and dy == 0:
                    continue
                nx, ny = x + dx, y + dy
                tile = game_map.get_tile(nx, ny)
                if tile is None:
                    continue
                if tile.type == TileType.WATER:
                    coastal_score += 0.18
                elif tile.type == TileType.SAND:
                    coastal_score += 0.08
        coastal_score = max(0.0, min(coastal_score, 1.0))

        noise = self._tile_noise01(x, y, 41)
        return max(0.0, min(edge_score * 0.35 + coastal_score * 0.45 + noise * 0.20, 1.0))

    def _tile_noise01(self, x: int, y: int, salt: int) -> float:
        h = abs((x * 73856093) ^ (y * 19349663) ^ (salt * 83492791))
        return float(h % 1000) / 999.0

    def _difficulty_density_multiplier(self, difficulty: Optional[Difficulty]) -> float:
        # Rend la génération globalement moins facile.
        if difficulty == Difficulty.HARD:
            return 0.50
        if difficulty == Difficulty.MEDIUM:
            return 0.70
        if difficulty == Difficulty.EASY:
            return 0.90
        return 0.75

    def _minimum_buildable_target(self, game_map: GameMap, difficulty: Optional[Difficulty]) -> int:
        area = game_map.width * game_map.height
        base_min = max(6, int(round(float(area) * 0.02)))
        if difficulty == Difficulty.HARD:
            return min(base_min, 12)
        if difficulty == Difficulty.MEDIUM:
            return min(base_min + 2, 14)
        return min(base_min + 4, 18)
