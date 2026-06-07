@icon("res://addons/http_event_source/HTTPEventSource.svg")
class_name HTTPEventSource
## A GDScript implementation of a SSE client.  [br]
## It is supposed to work very similar to the JavaScript Web API called [url=https://developer.mozilla.org/en-US/docs/Web/API/EventSource]EventSource[/url] [br]
## Like the Web API it is pretty hassle free and automatically reconnects when there is an error.
## It completely implements the [url=https://html.spec.whatwg.org/multipage/server-sent-events.html]Spec[/url], including Last-Event-ID and retry timeouts. [br]
## To use it, first call [method connect_to_url] and then keep polling to receive new events using [method poll] [br]
## To listen to events, either connect to the godot signals ([signal event] or [signal message]) or alternatively
## use the JS-like API with [member onevent], [member onmessage] or [method add_event_listener] [br]

# Spec: https://html.spec.whatwg.org/multipage/server-sent-events.html

## This signal emits a [ServerSentEvent] every time when an event of type [code]"message"[/code] is received. See 
signal message(event: ServerSentEvent)

## This signal emits a [ServerSentEvent] every time when an event is received. Including events of type [code]"message"[/code][br]
## To listen only to events of a specific type either check for the [member ServerSentEvent.type] each time a event is received
## or alternatively use the [method add_event_listener] method.
signal event(message: ServerSentEvent)

## Used by the [member ready_state] property to indicate the state of the connection [br]
## [br] Also see [url]https://developer.mozilla.org/en-US/docs/Web/API/EventSource/readyState[/url]
enum EventSourceState {
	CONNECTING, ## The connection is not yet open or reconnecting.
	OPEN, ## The connection is open and ready to communicate.
	CLOSED ## The connection is closed or couldn't be opened.
}

## Alternative way to match [enum EventSourceState]
const STATE_CONNECTING := EventSourceState.CONNECTING
## Alternative way to match [enum EventSourceState]
const STATE_OPEN := EventSourceState.OPEN
## Alternative way to match [enum EventSourceState]
const STATE_CLOSED := EventSourceState.CLOSED

## A [Callable] that shall be called when an event of type [code]"message"[/code] is received from the server.[br]
## It receives one argument of type [ServerSentEvent].
var onmessage: Callable = func(a): pass

## A [Callable] that shall be called every time an event is received from the server. This includes events of type [code]"message"[/code]. [br]
## It receives one argument of type [ServerSentEvent].
var onevent: Callable = func(a): pass

## This read-only property returns a enum of type [enum EventSourceState] to indicate the currect state of connection.[br]
## The state will only ever change from [constant STATE_CONNECTING] to [constant STATE_OPEN] when regularly polling using [method poll] [br]
## [br] Also see [url]https://developer.mozilla.org/en-US/docs/Web/API/EventSource/readyState[/url]
var ready_state: EventSourceState:
	get:
		if _closed: return STATE_CLOSED
		match _http_client.get_status():
			HTTPClient.STATUS_BODY, HTTPClient.STATUS_CONNECTED, HTTPClient.STATUS_REQUESTING:
				return STATE_OPEN
			_: return STATE_CONNECTING

## This read-only property returns a string representing the URL of the source [br]
## [br] Also see [url]https://developer.mozilla.org/en-US/docs/Web/API/EventSource/url[/url]
var url: String:
	get():
		var u = _host
		if _port > 0:
			u += ":"
			u += str(_port)
		u += _path
		return u

## This property allows overwriting the default HTTP Method, to be used [br]
## If you want to keep the default method (GET; POST when a payload is provided), set this property to [member HTTPClient.METHOD_MAX] [br]
## This is a [b]non standard property[/b] and not defined in the official specifications
var request_method_overwrite: HTTPClient.Method = HTTPClient.METHOD_MAX

## This property defines whether the Event Source should automatically try to reconnect to the Server. [br]
## You should consider setting this property to false, when using the non standard payloads and POST methods,
## as automatic reconnects might cause duplicate requests to the Server endpoints
var automatic_reconnect: bool = true

## This method needs to be called regularly to establish a connection, reconnect on error and receive new events.
func poll() -> void:
	
	if _closed:
		return
	
	_http_client.poll()
	
	match _http_client.get_status():
		HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_REQUESTING:
			pass
		HTTPClient.STATUS_DISCONNECTED, HTTPClient.STATUS_CONNECTION_ERROR:
			if automatic_reconnect:
				_start_connection()
			else:
				stop()
		HTTPClient.STATUS_CONNECTED:
			_start_request()
		HTTPClient.STATUS_BODY:
			_poll_body()
		HTTPClient.STATUS_CANT_RESOLVE:
			push_error("DNS Error: Can't resolve Hostname. Stopping HTTPEventSource")
			stop()
		HTTPClient.STATUS_CANT_CONNECT:
			push_error("Can't establish HTTP Connection. Stopping HTTPEventSource")
			stop()
		HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			push_error("TLS Handshake Error. Stopping HTTPEventSource")
			stop()

## Use this method to connect to your server from which you want to receive events.
## Call this method when you have connected all signals you want and added all event listeners you need,[br]
## but before starting to [method poll] (This order is not a requirement but best practice).[br]
## Takes a [param url] to the server you want to connect to. [br]
## The two additional parameters [param custom_headers] and [param payload] are [b]non standard[/b] and extend the SSE specification. [br]
## [param custom_headers] allows sending additional headers to the server, e.g. [code]custom_headers: ["Authorization: Bearer <token>"] [/code] [br]
## When the [param payload] parameter is provided as a non-empty string, the SSE Request is initiated via a POST request
func connect_to_url(url: String, custom_headers: PackedStringArray = PackedStringArray(), payload: String = "") -> Error:
	if not _closed:
		return ERR_ALREADY_IN_USE
	
	if _parse_url(url) != OK:
		return ERR_PARSE_ERROR
	
	_closed = false
	
	_headers = custom_headers
	_headers.append("Accept: text/event-stream")
	
	_payload = payload
	
	return _start_connection()

## Close the connection to the server and stop receiving new events. [br]
## Reusing this Node after stop is possible but [b]be aware[/b] that all event listeners
## stay active between connections and need to be cleared manually if desired.
func stop() -> void:
	_http_client.close()
	_closed = true
	_retry_time = 2000
	_block_data = ""
	_block_event = ""
	_block_id = ""

## Use this to add event listeners in the Web API style [br]
## Takes the [param event_type] to define which event to listen to and
## a [param callback] that will be called with a single argument of type [ServerSentEvent] whenever this type of event is dispatched.
func add_event_listener(event_type: String, callback: Callable) -> void:
	if not _listeners.has(event_type):
		_listeners[event_type] = [ callback ]
	else:
		_listeners[event_type].append(callback)

## Use this to remove a single event listener. [br]
## Use the same arguments as when you added the event listeners when calling [method add_event_listener]. [br]
## [b]Be aware[/b] that this will not work for local [Callable]s that are recreated when trying to remove it again. To remove those use [method clear_event_listeners]
func remove_event_listener(event_type: String, callback: Callable) -> Error:
	if not _listeners.has(event_type) or _listeners[event_type].length() == 0:
		push_error("There are no listeners for event_type '%s'" % [ event_type ])
		return ERR_DOES_NOT_EXIST
	var callback_pos: int = _listeners[event_type].rfind(callback)
	
	if callback_pos < 0:
		push_error("The callback was not found. Make sure that you're not using a local callable")
		return ERR_DOES_NOT_EXIST
	
	_listeners[event_type].pop_at(callback_pos)
	
	return OK

## Use this to remove multiple event listeners. [br]
## If [param event_type] is specified, it removes the listeners for this type of event. If not specified [i]all[/i] event listeners are removed.
func clear_event_listeners(event_type: String = "") -> void:
	if event_type.is_empty():
		_listeners.clear()
	else:
		_listeners.erase(event_type)

## Use this to proxy your connection.[br]
## This uses the same underlying logic as [method HTTPClient.set_http_proxy]
func set_http_proxy(host: String, port: int) -> void:
	_http_client.set_http_proxy(host, port)

## Use this to proxy your connection using HTTPS.[br]
## This uses the same underlying logic as [method HTTPClient.set_https_proxy]
func set_https_proxy(host: String, port: int) -> void:
	_http_client.set_https_proxy(host, port)

## Use this to define custiom TLS Options, like self signed certificates or similar.[br]
## See [TLSOptions]
func set_tls_options(client_options: TLSOptions) -> void:
	_tls_options = client_options


## PRIVATE MEMBERS AND METHODS.                      ##
## THESE ARE INTERNAL AND SHOULD NOT BE USED BY HAND ##
## YOU CAN COLLAPSE THE FOLLOWING REGION             ##
#region Private

var _http_client := HTTPClient.new()

var _host: String
var _port: int = -1
var _path: String

var _tls_options: TLSOptions = null
var _headers: PackedStringArray

var _payload: String = ""

var _last_event_id: String = ""

var _closed: bool = true

var _listeners: Dictionary = {}

var _block_data := ""
var _block_event := ""
var _block_id := ""

var _retry_time: int = 2000
var _last_time_success: int = -_retry_time

var _response_header_checked: bool = false

func _set_success() -> void:
	_last_time_success = Time.get_ticks_msec()

func _retry_allowed() -> bool:
	return Time.get_ticks_msec() > _last_time_success + _retry_time

func _check_content_type() -> Error:
	if _response_header_checked: return OK
	_response_header_checked = true
	
	var response_headers_dict := _http_client.get_response_headers_as_dictionary()
	for header: String in response_headers_dict.keys():
		var value: String = response_headers_dict[header]
		if header.to_lower() == "content-type":
			if value.containsn("text/event-stream"):
				return OK # All good!
			else:
				push_error("Received invalid content type from server. Stopping HTTPEventSource. Got '%s'" % [value])
				return ERR_INVALID_DATA
	
	push_error("No Content-Type header found in response from the server. 'Content-Type: text/event-stream' is a requirement. Stopping HTTPEventSource.")
	return ERR_INVALID_DATA

func _poll_body() -> void:
	
	if _check_content_type() != OK:
		stop()
		return
	
	var body := _read_body_to_end()
	
	if body.size() <= 0: return
	
	_parse_body(body.get_string_from_utf8())

func _read_body_to_end() -> PackedByteArray:
	var total := PackedByteArray()
	while true:
		var read := _http_client.read_response_body_chunk()
		if read.size() == 0:
			return total
		total.append_array(read)
	
	return PackedByteArray()

func _parse_body(body: String) -> void:
	var lines := _text_to_lines(body)
	
	for line in lines:
		
		# https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
		
		if line.is_empty():
			_submit_block()
			continue
		
		var colon_split := line.split(":", true, 1)
		var field := colon_split[0]
		var value := ""
		if colon_split.size() == 2:
			value = colon_split[1]
			if value.begins_with(" "):
				value = value.substr(1)
		
		# https://html.spec.whatwg.org/multipage/server-sent-events.html#processField
		match field:
			"event":
				_block_event = value
			"data":
				_block_data += value
				_block_data += "\n"
			"id":
				_block_id = value
			"retry":
				if value.is_valid_int() and not (value.begins_with("-") or value.begins_with("+")):
					_retry_time = value.to_int()

# https://html.spec.whatwg.org/multipage/server-sent-events.html#dispatchMessage
func _submit_block() -> void:
	_set_success()
	_last_event_id = _block_id
	if not _block_data.is_empty():
		
		if _block_data.ends_with("\n"):
			_block_data = _block_data.substr(0, _block_data.length() - 1)
		
		var event = ServerSentEvent.new()
		event.data = _block_data
		event.last_event_id = _last_event_id
		if not _block_event.is_empty():
			event.type = _block_event
		_signal_event(event)
	
	_block_data = ""
	_block_event = ""

func _signal_event(ev: ServerSentEvent) -> void:
	var listeners : Array[Callable] = [ onevent ]
	
	if _listeners.has(ev.type):
		listeners.append_array(_listeners[ev.type])
	
	if ev.type == "message":
		listeners.append(onmessage)
		message.emit.call_deferred(ev)
	
	for lis in listeners:
		lis.call_deferred(ev)
	
	event.emit.call_deferred(ev)

func _start_connection() -> Error:
	if not _retry_allowed(): return ERR_BUSY
	_set_success()
	var err := _http_client.connect_to_host(_host, _port, _tls_options)
	if err == ERR_INVALID_PARAMETER:
		push_error("Invalid host. Got: '%s'" % [ _host ])
		stop()
	return err

func _start_request():
	if not _retry_allowed(): return
	_set_success()
	
	var header := _headers.duplicate()
	if not _last_event_id.is_empty():
		header.append("Last-Event-ID: " + _last_event_id)
	
	_response_header_checked = false
	
	var method := HTTPClient.METHOD_GET
	if _payload.length() > 0:
		method = HTTPClient.METHOD_POST
	if request_method_overwrite < HTTPClient.METHOD_MAX:
		method = request_method_overwrite
	_http_client.request(method, _path, header, _payload)

func _text_to_lines(text: String) -> PackedStringArray:
	if text.contains("\r\n"):
		return text.split("\r\n")
	elif text.contains("\n"):
		return text.split("\n")
	elif text.contains("\r"):
		return text.split("\r")
	else:
		return PackedStringArray([ text ])

func _parse_url(url: String) -> Error:
	var host_start := 0
	
	if url.begins_with("http://"):
		host_start = 7
	elif url.begins_with("https://"):
		host_start = 8
	else:
		push_error("Invalid http protocol. 'http://' or 'https://' are required. Got: '%s'" % [ url ])
		return ERR_PARSE_ERROR
	
	var path_start := url.findn("/", host_start)
	
	if path_start == host_start:
		push_error("Invalid hostname. Got: '%s'" % [ url ])
		return ERR_PARSE_ERROR
	elif path_start == -1:
		path_start = url.length()
		_path = "/"
	else:
		_path = url.substr(path_start)
	
	var host_and_port := url.substr(0, path_start).split(":", true, 2)
	
	_host = host_and_port[0] + ":" + host_and_port[1]
	if host_and_port.size() > 2:
		if not host_and_port[2].is_valid_int():
			push_error("Invalid port. Got: '%s'" % [ host_and_port[2] ])
			return ERR_PARSE_ERROR
		_port = host_and_port[2].to_int()
	
	return OK

#endregion
