## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Enums pour la génération de maps en runtime.

enum TileType {
	EMPTY = 0,
	PATH = 1,
	BUILDABLE = 2,
	SPAWN = 3,
	EXIT = 4,
	OBSTACLE = 5,
	WATER = 6,
	SAND = 7
}

enum MapStyle {
	LONG_PATH,
	MANY_TURNS,
	CHOKEPOINTS,
	OPEN,
	S_CURVE,
	SPIRAL,
	ZIG_ZAG
}

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}
