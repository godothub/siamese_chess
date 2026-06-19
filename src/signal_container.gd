extends RefCounted
class_name SignalContainer

class SignalMethodMap extends RefCounted:
	var key:Signal = Signal()
	var value:Callable = Callable()

var	connection_list:Array[SignalMethodMap] = []

func add_connection(_signal:Signal, _method:Callable) -> void:
	_signal.connect(_method)
	assert(_signal.is_connected(_method))
	var signal_method_map:SignalMethodMap = SignalMethodMap.new()
	signal_method_map.key = _signal
	signal_method_map.value = _method
	connection_list.push_back(signal_method_map)
	pass

func disconnect_all() -> void:
	for connection:SignalMethodMap in connection_list:
		connection.key.disconnect(connection.value)
	connection_list.clear()
