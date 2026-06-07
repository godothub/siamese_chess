extends Level

@onready var http_request_move = $http_request_move
@onready var http_event_source = HTTPEventSource.new()
var moved_by_remote:bool = false

func _ready() -> void:
	super._ready()
	$marker_explore.connect("move_executed", send_move)
	http_request_move.connect("request_completed", on_request_completed_move)
	http_event_source.connect_to_url("http://127.0.0.1:5000/stream")
	http_event_source.connect("event", on_server_sent_event)

func _process(_delta:float) -> void:
	http_event_source.poll()

func send_move(move:int) -> void:
	var body:String = JSON.stringify({"move": Chess.x88_to_name(Chess.to(move))})
	var error:int = http_request_move.request("http://127.0.0.1:5000/room/move", ["Content-Type:application/json"], HTTPClient.METHOD_POST, body)
	await http_request_move.request_completed
	if error != OK:
		push_error(error_string(error))

func on_request_completed_move(_result:int, _response_code:int, _headers:PackedStringArray, _body:PackedByteArray) -> void:
	pass

func on_server_sent_event(sse:ServerSentEvent) -> void:
	var data:Dictionary = JSON.parse_string(sse.data)
	if sse.type == "move":
		$marker_explore.travel_to(Chess.name_to_x88(data["message"]), true)
