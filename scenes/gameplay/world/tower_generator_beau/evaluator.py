import json
from typing import Dict, List
from .models import GameMap, TileType, GameData, Difficulty

class MapEvaluator:
    def __init__(self, game_data: GameData):
        self.game_data = game_data

    def evaluate(self, game_map: GameMap, difficulty_target: Difficulty, enemy_types: List[str]) -> float:
        """
        Simulates a standard wave and returns a difficulty score.
        0.0 = Very Easy (All enemies die quickly)
        1.0 = Very Hard (Most enemies reach the exit)
        """
        # 1. Place 'virtual' towers on best buildable spots
        buildable_tiles = []
        for x in range(game_map.width):
            for y in range(game_map.height):
                tile = game_map.get_tile(x, y)
                if tile.type == TileType.BUILDABLE:
                    buildable_tiles.append(tile)
        
        # Sort by strategic score
        buildable_tiles.sort(key=lambda t: t.score, reverse=True)
        
        # Use first N tiles for towers (budget depends on player level/difficulty)
        # For evaluation, we only use a few towers to avoid killing everything instantly
        tower_count = 3 
        placed_towers = buildable_tiles[:tower_count]
        
        # 2. Pick representative enemies
        enemies_to_test = []
        if not enemy_types:
            enemies_to_test.append("ene.01")
        else:
            # Add a mix of enemies
            for et in enemy_types:
                if et == "fast": enemies_to_test.append("ene.03") # Rat
                elif et == "tank": enemies_to_test.append("ene.02") # Fat
                elif et == "boss": enemies_to_test.append("big_daddy")
                else: enemies_to_test.append("ene.01") # Default

        # 3. Simulation
        total_health = 0
        total_escaped_health = 0
        
        for enemy_key in enemies_to_test:
            enemy_stats = self.game_data.enemies.get(enemy_key, self.game_data.enemies.get("ene.01", {"max_health": 20, "speed": 45}))
            hp = enemy_stats["max_health"]
            speed = enemy_stats["speed"]
            total_health += hp
            
            # Simplified simulation: 
            # Distribute enemy health across all paths
            escaped_for_this_enemy = 0
            hp_per_path = hp / len(game_map.paths)

            for path in game_map.paths:
                remaining_hp = hp_per_path
                for px, py in path.points:
                    time_in_tile = 10.0 / speed 
                    
                    for tower_tile in placed_towers:
                        dist = ((tower_tile.x - px)**2 + (tower_tile.y - py)**2)**0.5
                        if dist <= 2.5: # Range
                            damage = 2 * time_in_tile
                            remaining_hp -= damage
                    
                    if remaining_hp <= 0:
                        remaining_hp = 0
                        break
                escaped_for_this_enemy += remaining_hp
            
            total_escaped_health += escaped_for_this_enemy

        # 4. Final score
        actual_difficulty = total_escaped_health / total_health if total_health > 0 else 0
        return actual_difficulty

    def get_difficulty_range(self, difficulty: Difficulty) -> tuple:
        if difficulty == Difficulty.EASY:
            return (0.1, 0.3)
        elif difficulty == Difficulty.MEDIUM:
            return (0.4, 0.6)
        else:
            return (0.7, 0.9)
