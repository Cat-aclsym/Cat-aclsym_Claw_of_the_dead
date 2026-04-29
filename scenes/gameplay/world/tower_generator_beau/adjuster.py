import json
from .models import GameMap, GenConfig, GameData, Difficulty, TileType
from .path_generator import PathGenerator
from .map_generator import MapGenerator
from .evaluator import MapEvaluator

class MapAdjuster:
    def __init__(self, game_data: GameData):
        self.game_data = game_data
        self.evaluator = MapEvaluator(game_data)

    def generate_balanced_map(self, config: GenConfig) -> GameMap:
        max_attempts = 10
        best_map = None
        best_score_delta = float("inf")
        attempt = 0

        target_range = self.evaluator.get_difficulty_range(config.difficulty)
        target_center = (target_range[0] + target_range[1]) / 2.0

        while attempt < max_attempts:
            game_map = GameMap(config.width, config.height)
            path_gen = PathGenerator(config.width, config.height)
            paths_data = path_gen.generate_paths(config.style, config.num_paths)
            
            map_gen = MapGenerator(config.width, config.height)
            # 1. Apply paths first
            map_gen.apply_paths_to_map(game_map, paths_data)
            # 2. Apply borders (respects paths)
            map_gen.apply_borders(game_map)
            # 3. Add zones and decorations
            map_gen.generate_buildable_zones(
                game_map,
                config.buildable_density,
                config.enemy_types,
                config.difficulty
            )
            map_gen.add_decorations(game_map, config.decoration_density)

            if not self._satisfies_constraints(game_map, config):
                attempt += 1
                continue

            score = self.evaluator.evaluate(game_map, config.difficulty, config.enemy_types)

            # Si score dans l'intervalle, on accepte immédiatement.
            if target_range[0] <= score <= target_range[1]:
                return game_map

            # Sinon, on garde la map la plus proche du "milieu" de la target range.
            score_delta = abs(score - target_center)
            if score_delta < best_score_delta:
                best_score_delta = score_delta
                best_map = game_map

            attempt += 1
            
        # Au cas où toutes les maps auraient échoué contraintes:
        # fallback sur la dernière map générée (best_map peut être None si tout échoue).
        if best_map is not None:
            return best_map
        return game_map

    def _satisfies_constraints(self, game_map: GameMap, config: GenConfig) -> bool:
        # Contraintes path length
        if config.min_path_length is not None:
            path_lengths = [len(p.points) for p in game_map.paths]
            if any(l < config.min_path_length for l in path_lengths):
                return False

        # Contraintes buildables max (selon config max_buildable_zones)
        if config.max_buildable_zones is not None:
            buildable_count = 0
            for x in range(game_map.width):
                for y in range(game_map.height):
                    if game_map.get_tile(x, y).type == TileType.BUILDABLE:
                        buildable_count += 1
            if buildable_count > config.max_buildable_zones:
                return False

        return True