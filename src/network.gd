extends Node

# 统一的服务器地址
var server:String = "https://api.famulan.uk:5000"

func post_request(url:String, query:Dictionary, content_type:String, body:PackedByteArray, response:Callable) -> void:
	var temp_instance:HTTPClient = HTTPClient.new()
	var query_string:String = temp_instance.query_string_from_dict(query)
	var http_request:HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	var path:String = server + url + "?" + query_string
	print(path)
	print(query)
	http_request.connect("request_completed", receive_response.bind(http_request, path, response))
	http_request.request_raw(path, ["Content-Type: " + content_type], HTTPClient.METHOD_POST, body)

func get_request(url:String, query:Dictionary, response:Callable) -> void:
	var temp_instance:HTTPClient = HTTPClient.new()
	var query_string:String = temp_instance.query_string_from_dict(query)
	var http_request:HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	var path:String = server + url + "?" + query_string
	print(path)
	print(query)
	http_request.connect("request_completed", receive_response.bind(http_request, path, response))
	http_request.request(path, [], HTTPClient.METHOD_GET)

func receive_response(_result:int, _response_code:int, _header:PackedStringArray, body:PackedByteArray, http_request:HTTPRequest, path:String, callback:Callable) -> void:
	if _result != HTTPRequest.RESULT_SUCCESS:
		pass
	print("received %s body size %d" % [path, body.size()])
	callback.call(body)
	http_request.queue_free()
