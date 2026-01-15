## © [2026] A7 Studio. All rights reserved. Trademark.

extends Challenge

# "N" rats.
const N: int = 5

func check_completion() -> bool:
    # Logic based on base damage taken (which corresponds to rats passing)
    if not ILevel.current_level:
        return false

    var damage_taken = 20 - ILevel.current_level.health
    return damage_taken == N
