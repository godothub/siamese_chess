extends Actor
class_name Barrier

@export var breakable:bool = false

func _ready() -> void:
	piece_type = ord('*') if breakable else ord('#')
	var model_count:int = 0
	for iter:Node in get_children():
		if iter is Node3D && iter.name.is_valid_int():
			iter.visible = false
			model_count += 1
	var index:int = randi() % model_count
	var node_path:String = "%d" % index
	get_node(node_path).visible = true
