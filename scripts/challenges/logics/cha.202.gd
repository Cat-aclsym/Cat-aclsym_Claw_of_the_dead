## © [2026] A7 Studio. All rights reserved. Trademark.

extends Challenge

func check_completion() -> bool:
    if not ILevel.current_level:
        return false
    return ILevel.current_level.health == 1
