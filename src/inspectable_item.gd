extends Node3D
class_name InspectableItem

var button_list:Array[Area3D] = []
var enabled:bool = true

func _ready() -> void:
	for iter:Area3D in find_children("*", "Area3D"):
		button_list.push_back(iter)
		iter.add_user_signal("input")
		iter.connect("input", area_input)
	set_enabled(true)

func set_enabled(_enabled:bool) -> void:
	enabled = _enabled
	for iter:Area3D in button_list:
		if _enabled:
			iter.collision_layer |= 2
		else:  
			iter.collision_layer &= ~2		

func button_input(_button:String, _pressed:bool) -> void:	# 无非就是上、下、左、右、确认
	pass

func area_input(_from:Node3D, _to:Area3D, _instant:bool, _pressed:bool, _event_position:Vector3, _normal:Vector3) -> void:
	pass
