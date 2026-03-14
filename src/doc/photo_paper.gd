extends Document

var image:Image = Image.new()

func parse(data:String) -> void:
	var data_dict:Dictionary = JSON.parse_string(data)
	image.load_png_from_buffer(Marshalls.base64_to_raw(data_dict["data"]))
	$sprite_2d.texture = ImageTexture.create_from_image(image)
	draw_lines(data_dict["lines"])

func stringify() -> String:
	var data_dict:Dictionary = {}
	data_dict["data"] = Marshalls.raw_to_base64(image.save_png_to_buffer())
	data_dict["lines"] = get_lines()
	return JSON.stringify(data_dict)

func get_rect() -> Rect2:
	return $sprite_2d.get_rect() * $sprite_2d.transform
