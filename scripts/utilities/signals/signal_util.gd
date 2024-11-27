## © 2024 A7 Studio. All rights reserved. Trademark.
##
## A utility class for handling signal connections in a structured way.
## Provides a centralized approach to connect signals using a dictionary format.
class_name SignalUtil
extends Node

## Dictionary key for the signal emitter node.
const WHO: String = "who"
## Dictionary key for the signal name to connect.
const WHAT: String = "what"
## Dictionary key for the callback method to be called when the signal is emitted.
const TO: String = "to"

## Connects multiple signals using a dictionary-based configuration.
## [br][br]
## Example usage:
## [codeblock]
## var signals: Array[Dictionary] = [
##     {SignalUtil.WHO: self, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_body_entered}
## ]
## SignalUtil.connects(signals)
## [/codeblock]
##
## @param signals An array of dictionaries where each dictionary contains signal connection information.
##               Each dictionary must contain three keys: WHO (node emitting the signal),
##               WHAT (signal name), and TO (callback method).
static func connects(signals: Array[Dictionary]) -> void:
    for signal_info in signals:
        assert(
            WHO in signal_info.keys(),
            "Signal dictionary must contain a '{0}' key".format([WHO])
        )
        assert(
            WHAT in signal_info.keys(),
            "Signal dictionary must contain a '{0}' key".format([WHAT])
        )
        assert(
            TO in signal_info.keys(),
            "Signal dictionary must contain a '{0}' key".format([TO])
        )

        signal_info[WHO].connect(signal_info[WHAT], signal_info[TO])

        Log.trace(
            Log.Level.DEBUG,
            "Connecting signal {node}.{signal} to {callback}".format({
                "node": signal_info[WHO],
                "signal": signal_info[WHAT],
                "callback": signal_info[TO]
            })
        )

# private


# signal


# event


# setget
