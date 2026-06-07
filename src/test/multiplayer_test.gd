extends Level

func _ready() -> void:
	super._ready()
	$marker_explore.connect("move_executed", send_move)
	$http_request.connect("request_completed", on_request_completed)

func send_move(move:int) -> void:
	var body:String = JSON.stringify({"move": Chess.x88_to_name(Chess.to(move))})
	$http_request.request("http://127.0.0.1:5000/room/move", ["Content-Type:application/json"], HTTPClient.METHOD_POST, body)

func on_request_completed(_result:int, _response_code:int, _headers:PackedStringArray, _body:PackedByteArray) -> void:
	pass
