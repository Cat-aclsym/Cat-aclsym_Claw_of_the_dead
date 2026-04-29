from enum import Enum
from dataclasses import dataclass, field
from typing import List, Tuple, Dict, Optional

class TileType(Enum):
    EMPTY = 0
    PATH = 1
    BUILDABLE = 2
    SPAWN = 3
    EXIT = 4
    OBSTACLE = 5
    WATER = 6
    SAND = 7

@dataclass
class Tile:
    x: int
    y: int
    type: TileType = TileType.EMPTY
    score: float = 0.0

@dataclass
class Path:
    points: List[Tuple[int, int]] = field(default_factory=list)
    @property
    def length(self) -> int:
        return len(self.points)

class MapStyle(Enum):
    LONG_PATH = "long_path"
    MANY_TURNS = "many_turns"
    CHOKEPOINTS = "chokepoints"
    OPEN = "open"
    S_CURVE = "s_curve"
    SPIRAL = "spiral"
    ZIG_ZAG = "zig_zag"

class Difficulty(Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"

@dataclass
class GenConfig:
    width: int
    height: int
    difficulty: Difficulty
    enemy_types: List[str]
    player_level: int
    style: MapStyle
    num_paths: int = 1
    decoration_density: float = 0.05
    buildable_density: float = 0.2
    min_path_length: Optional[int] = None
    max_buildable_zones: Optional[int] = None
    force_chokepoints: bool = False

@dataclass
class GameData:
    enemies: Dict[str, dict]
    towers: Dict[str, dict]
    upgrades: Dict[str, dict]

class GameMap:
    def __init__(self, width: int, height: int):
        self.width = width
        self.height = height
        self.grid = [[Tile(x, y) for y in range(height)] for x in range(width)]
        self.paths: List[Path] = []
        self.spawns: List[Tuple[int, int]] = []
        self.exits: List[Tuple[int, int]] = []

    def get_tile(self, x: int, y: int) -> Tile:
        if 0 <= x < self.width and 0 <= y < self.height:
            return self.grid[x][y]
        return None

    def set_tile_type(self, x: int, y: int, t_type: TileType):
        tile = self.get_tile(x, y)
        if tile:
            tile.type = t_type
            if t_type == TileType.SPAWN:
                if (x, y) not in self.spawns: self.spawns.append((x, y))
            elif t_type == TileType.EXIT:
                if (x, y) not in self.exits: self.exits.append((x, y))

    def __str__(self):
        chars = {
            TileType.EMPTY: ".", 
            TileType.PATH: "#", 
            TileType.BUILDABLE: "B", 
            TileType.SPAWN: "S", 
            TileType.EXIT: "E", 
            TileType.OBSTACLE: "X",
            TileType.WATER: "W",
            TileType.SAND: "A"
        }
        lines = []
        for y in range(self.height):
            line = "".join(chars[self.grid[x][y].type] for x in range(self.width))
            lines.append(line)
        return "\n".join(lines)
