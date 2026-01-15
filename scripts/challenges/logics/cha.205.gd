## © [2026] A7 Studio. All rights reserved. Trademark.

extends Challenge

const MAX_SECONDS: int = 180 # 3 minutes

func check_completion() -> bool:
    if not ILevel.current_level:
        return false

    var elapsed = floor(ILevel.current_level.end_time - ILevel.current_level.start_time)
    return elapsed < MAX_SECONDS
