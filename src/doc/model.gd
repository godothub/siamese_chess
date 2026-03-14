extends Document
class_name Model

var model_path:String = ""
var model_instance:Node3D = null

func parse(_data:String) -> void:
	var data_dict:Dictionary = JSON.parse_string(_data)
	set_model(data_dict["path"])

func stringify() -> String:
	var data_dict:Dictionary = {}
	data_dict["path"] = model_path
	return JSON.stringify(data_dict)

func set_model(_model_path:String) -> void:
	if is_instance_valid(model_instance):
		model_instance.queue_free()
	model_path = _model_path
	model_instance = load(model_path).instantiate()
	$sub_viewport.add_child(model_instance)
