import json
import os
import argparse
import re
import random
from .models import GenConfig, Difficulty, MapStyle, GameData
from .adjuster import MapAdjuster
from .godot_exporter import GodotExporter

def get_next_map_path(maps_dir: str) -> str:
    if not os.path.exists(maps_dir): os.makedirs(maps_dir)
    existing_files = os.listdir(maps_dir)
    max_num = 0
    pattern = re.compile(r"map_(\d+)\.tscn")
    for f in existing_files:
        match = pattern.match(f)
        if match:
            num = int(match.group(1))
            if num > max_num: max_num = num
    return os.path.join(maps_dir, f"map_{max_num + 1:02d}.tscn")

def load_game_data(path: str) -> GameData:
    if not os.path.exists(path):
        return GameData(enemies={"ene.01": {"max_health": 20, "speed": 45}}, towers={}, upgrades={})
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        return GameData(enemies=data.get("enemies", {}), towers=data.get("towers", {}), upgrades=data.get("upgrades", {}))

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    parser = argparse.ArgumentParser(description="Procedural Map Generator")
    
    parser.add_argument("--width", type=int, default=25)
    parser.add_argument("--height", type=int, default=15)
    parser.add_argument("--difficulty", type=str, default="medium")
    parser.add_argument("--style", type=str, default="many_turns")
    parser.add_argument("--enemies", type=str, default="fast")
    parser.add_argument("--num_paths", type=int, default=1)
    parser.add_argument("--decor_density", type=float, default=0.05)
    parser.add_argument("--build_density", type=float, default=0.2)
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--min-len", type=int)
    parser.add_argument("--max-buildable", type=int)
    parser.add_argument("--force-choke", action="store_true")
    
    maps_dir = os.path.join(script_dir, "maps")
    parser.add_argument("--export", type=str, default=get_next_map_path(maps_dir))
    
    args = parser.parse_args()
    
    # Permet de reproduire exactement une génération.
    if args.seed is not None:
        random.seed(args.seed)
        print(f"INFO: Using generation seed {args.seed}")

    config = GenConfig(
        width=args.width, height=args.height,
        difficulty=Difficulty(args.difficulty),
        style=MapStyle(args.style),
        enemy_types=args.enemies.split(","),
        player_level=1,
        num_paths=args.num_paths,
        decoration_density=args.decor_density,
        buildable_density=args.build_density,
        min_path_length=args.min_len,
        max_buildable_zones=args.max_buildable,
        force_chokepoints=args.force_choke
    )
    
    game_data = load_game_data(os.path.join(script_dir, "game_data.json"))
    adjuster = MapAdjuster(game_data)
    final_map = adjuster.generate_balanced_map(config)
    
    exporter = GodotExporter()
    exporter.export_to_tscn(final_map, args.export)
    print(f"SUCCESS: Map exported to {args.export}")

if __name__ == "__main__":
    main()
