class_name ServerSentEvent
## This is a data class holding the information of a Server Sent Event.[br]
## These events are dispatched and created by a [HTTPEventSource]

## The type of event. Defaults to [code]"message"[/code] if not specified by the server.
var type: String = "message"

## The data sent by the server. Only if this field is specified by the server, the event is actually dispatched.
var data: String

## A event id optionally specified by the server to indicate some sort of state.[br]
## When reconnecting to the server this id is automatically sent along to keep going from where you left off.
var last_event_id: String
