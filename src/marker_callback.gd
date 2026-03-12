extends MarkerSelection
class_name MarkerCallback

@export var node:Node = null
@export var method_name:StringName = ""
@export var arg:Array = []

func event() -> void:
	await node.callv(method_name, arg)
