extends Document
# 插画作品，只保存路径，而非其图像数据
var path:String = ""

func parse(_data:String) -> void:
	var data_dict:Dictionary = JSON.parse_string(_data)
	draw_lines(data_dict["lines"])
	path = data_dict["path"]
	$sprite.texture = load(path)

func stringify() -> String:
	var data_dict:Dictionary = {}
	data_dict["path"] = path
	data_dict["lines"] = get_lines()
	return JSON.stringify(data_dict)
