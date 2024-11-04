class_name SignalUtil extends Node

const WHO: String = "who"
const WHAT: String = "what"
const TO: String = "to"


# core


# public
## e.g
## var signals: Array[Dictionary] = [
## 	{SignalUtil.WHO: self, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_body_entered}
## ]
static func connects(signals: Array[Dictionary]) -> void:
    for s in signals:
        assert(WHO in s.keys())
        assert(WHAT in s.keys())
        assert(TO in s.keys())

        s[WHO].connect(s[WHAT], s[TO])

        Log.trace(Log.Level.DEBUG, "Connecting {node}.{signal} to {callback}".format({
            "node": s[WHO],
            "signal": s[WHAT],
            "callback": s[TO]
        }));

# private


# signal


# event


# setget

