import os
from .models import GameMap, TileType

class GodotExporter:
    def __init__(self, tile_size: int = 64):
        self.tile_size = tile_size
        # Mapping TileType vers IDs Godot
        self.tile_mapping = {
            TileType.EMPTY: 0,      # Grass
            TileType.PATH: 4,       # Way
            TileType.BUILDABLE: 1,  # Gravel
            TileType.SPAWN: 4,
            TileType.EXIT: 4,
            TileType.WATER: 3,      # Water
            TileType.SAND: 2        # Sand
        }

    def export_to_tscn(self, game_map: GameMap, filename: str):
        curves_tscn = []
        paths_nodes_tscn = []
        for i, path in enumerate(game_map.paths):
            curve_id = f"Curve2D_gen_{i}"
            pts = []
            for x, y in path.points:
                px, py = (x - y) * 32, (x + y) * 16
                pts.extend([0, 0, 0, 0, px, py])
            curves_tscn.append(f'[sub_resource type="Curve2D" id="{curve_id}"]\n_data = {{"points": PackedVector2Array({", ".join(map(str, pts))})}}\npoint_count = {len(path.points)}')
            paths_nodes_tscn.append(f'[node name="Path2D_{i}" type="Path2D" parent="Paths" index="{i}"]\nposition = Vector2(-32, 62)\ncurve = SubResource("{curve_id}")')

        layer0_data = [] # Terrain & Bordures d'eau
        layer1_data = [] # Vagues animées
        
        for x in range(game_map.width):
            for y in range(game_map.height):
                tile = game_map.get_tile(x, y)
                source_id = self.tile_mapping.get(tile.type, 0)
                grid_index = self._get_grid_index(x, y)
                ax, ay = self._get_default_atlas_coords(tile.type, x, y)
                
                if tile.type == TileType.WATER:
                    ax = self._get_water_border_ax(game_map, x, y)
                    
                    # Layer 1 : Animation fluide (Source 5, Atlas 0,0)
                    # Format: index, (ax << 16) | source, ay
                    layer1_data.extend([grid_index, 5, 0])

                # FORMAT GODOT 4.4 : [index, (ax << 16) | source, ay]
                source_composite = (ax << 16) | source_id
                layer0_data.extend([grid_index, source_composite, ay])

        tscn_content = f"""[gd_scene load_steps={len(game_map.paths) + 2} format=3 uid="uid://procedural_map"]
[ext_resource type="PackedScene" uid="uid://crdosg1fmycsi" path="res://scenes/gameplay/world/map/i_map.tscn" id="1_ja0gd"]
{"\n".join(curves_tscn)}
[node name="IMap" instance=ExtResource("1_ja0gd")]
[node name="TileMapPlains" parent="." index="1"]
layer_0/tile_data = PackedInt32Array({", ".join(map(str, layer0_data))})
layer_1/tile_data = PackedInt32Array({", ".join(map(str, layer1_data))})
{"\n".join(paths_nodes_tscn)}
"""
        with open(filename, "w", encoding="utf-8") as f: f.write(tscn_content)

    def _get_grid_index(self, x: int, y: int) -> int:
        return (y << 16) | x

    def _get_default_atlas_coords(self, tile_type: TileType, x: int, y: int) -> tuple[int, int]:
        # Mode ultra lisible: pas de variation atlas pour éviter le rendu "pierreux".
        return 0, 0

    def _get_water_border_ax(self, game_map: GameMap, x: int, y: int) -> int:
        """Retourne la coordonnée X atlas pour les bordures d'eau.
        Cette logique est partagée avec le runtime GDScript pour garder
        un rendu cohérent entre export Python et génération en jeu.
        """
        if x == 0:
            return 2
        if y >= game_map.height - 1:
            return 4
        if y == 0:
            return 3
        if x == game_map.width - 1:
            return 4
        return 1
