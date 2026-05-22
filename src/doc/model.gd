extends Document
class_name Model

var model_path:String = ""

func parse(data:Dictionary) -> void:
	set_model(data["path"])

func dict() -> Dictionary:
	var data:Dictionary = {}
	data["path"] = model_path
	return data

func set_model(_model_path:String) -> void:
	model_path = _model_path
	content_changed.emit()
