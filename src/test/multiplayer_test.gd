extends Level

@onready var http_request_move = $http_request_move
@onready var http_request_enter = $http_request_enter
@onready var http_event_source = HTTPEventSource.new()
var moved_by_remote:bool = false
var cookies:String = "Cookie: "
var my_uuid:String = ""
var users:Dictionary = {}

func _ready() -> void:
	super._ready()
	$event_explore.connect("move_executed", send_move)
	http_event_source.connect_to_url("https://api.famulan.uk:5001/stream")
	http_event_source.connect("event", on_server_sent_event)
	http_request_enter.connect("request_completed", on_request_completed_enter)
	http_request_enter.request("https://api.famulan.uk:5001/room", ["Content-Type:application/json"], HTTPClient.METHOD_GET)

func _process(_delta:float) -> void:
	http_event_source.poll()

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		var from:Vector3 = get_viewport().get_camera_3d().project_ray_origin(event.position)
		var to:Vector3 = get_viewport().get_camera_3d().project_ray_normal(event.position) * 200
		$ray_cast_3d.global_position = from
		$ray_cast_3d.target_position = to
		$ray_cast_3d.collision_mask = 3
		$ray_cast_3d.force_raycast_update()
		if $ray_cast_3d.is_colliding():
			$chessboard.area_input(self, $ray_cast_3d.get_collider(), true, event.pressed, $ray_cast_3d.get_collision_point(), $ray_cast_3d.get_collision_normal())
	if event is InputEventMouseMotion:
		var from:Vector3 = get_viewport().get_camera_3d().project_ray_origin(event.position)
		var to:Vector3 = get_viewport().get_camera_3d().project_ray_normal(event.position) * 200
		$ray_cast_3d.global_position = from
		$ray_cast_3d.target_position = to
		$ray_cast_3d.collision_mask = 3
		$ray_cast_3d.force_raycast_update()
		if $ray_cast_3d.is_colliding():
			$chessboard.area_input(self, $ray_cast_3d.get_collider(), false, event.button_mask & MOUSE_BUTTON_MASK_LEFT, $ray_cast_3d.get_collision_point(), $ray_cast_3d.get_collision_normal())

func send_move(move:int) -> void:
	var body:String = JSON.stringify({"move": Chess.x88_to_name(Chess.to(move))})
	http_request_move.cancel_request()
	var error:int = http_request_move.request("https://api.famulan.uk:5001/room/move", ["Content-Type:application/json", cookies], HTTPClient.METHOD_POST, body)
	await http_request_move.request_completed
	if error != OK:
		push_error(error_string(error))

func on_request_completed_enter(_result:int, _response_code:int, _headers:PackedStringArray, _body:PackedByteArray) -> void:
	if _response_code != 200:
		print("Network error")
		return
	var regex:RegEx = RegEx.new()
	regex.compile("client_id=(([0-9a-f\\-])*);")
	for iter:String in _headers:
		if iter.begins_with("Set-Cookie:"):
			var result:RegExMatch = regex.search(iter)
			my_uuid = result.get_string(1)
			cookies = "Cookie:" + iter.substr(11)
			break
	var body:String = _body.get_string_from_utf8()
	print(body)
	var data:Dictionary = JSON.parse_string(body)
	for iter:String in data["users"]:
		create_user(iter, Chess.name_to_x88(data["users"][iter]["by"]))

func on_server_sent_event(sse:ServerSentEvent) -> void:
	var data:Dictionary = JSON.parse_string(sse.data)
	if sse.type == "move":
		if users.has(data["message"]["user"]):
			users[data["message"]["user"]].move($chessboard.name_to_vector3(data["message"]["move"]))
		else:
			create_user(data["message"]["user"], Chess.name_to_x88(data["message"]["move"]))
	if sse.type == "new_guest":
		create_user(data["message"])

func create_user(uuid:String, by:int = 0) -> void:
	if uuid == my_uuid:
		return
	var instance:Actor = load("res://scene/actor/cheshire.tscn").instantiate()
	users[uuid] = instance
	$chessboard.add_child(instance)
	instance.position = $chessboard.x88_to_vector3(by)
