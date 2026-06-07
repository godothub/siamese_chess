# Godot HTTPEventSource for SSE
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Z8Z7AO1BI)
## What is this?

This is a GDScript implementation of the of EventSource Web API available in Browsers and JavaScript for reading Server Sent Event Streams (SSE).
This implementation comes with exhaustive docs that you can view inside the Godot Editor by pressing `F1`
It completely implements the [Spec](https://html.spec.whatwg.org/multipage/server-sent-events.html),  including Last-Event-ID and retry timeouts.

---
## How to use

First add this plugin to your godot project into the `res://addons/http_event_source` folder.

Then you can use the `HTTPEventSource` class, very similar to how you would use the [EventSource](https://developer.mozilla.org/en-US/docs/Web/API/EventSource) in JavaScript, except that you need to regularly call the `HTTPEventSource.poll()` method to update the event stream.

To see how it fully works, its best to view the in-editor docs but here's a little example script on how to use it:

```gd
extends Node

var http_event_source: HTTPEventSource

func _ready() -> void:
	http_event_source = HTTPEventSource.new()
	http_event_source.connect_to_url("http://127.0.0.1:8080/test-sse")
	http_event_source.event.connect(func(ev: ServerSentEvent):
		print("-- TYPE --")
		print(ev.type)
		print("-- DATA --")
		print(ev.data)
		print("--      --\n")
	)


func _process(delta: float) -> void:
	http_event_source.poll()

```
---
## Non-Standard extensions

This plugin also has non-standard extensions to the specs, namely alternative HTTP-methods (e.g. POST), request bodies and HTTP-headers.

To see how to use them, visit the docs from inside the Godot Editor

---

## Support

Please support me on [Ko-fi](https://ko-fi.com/Z8Z7AO1BI) if this helps you with your project.  
And always remember to include the MIT [LICENSE](LICENSE) information when releasing your game to the public.
