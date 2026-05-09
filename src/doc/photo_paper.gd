extends Notable

class PhotoPage extends RefCounted:
	var image:Image = Image.new()

var page_list:Array[PhotoPage] = []
var current_page:int = 0
var current_page_instance:PhotoPage = null

func parse(data:Dictionary) -> void:
	super.parse(data)
	page_list.clear()
	current_page = 0
	var data_arr:Array = data["photo"]
	for iter:Dictionary in data_arr:
		var page:PhotoPage = PhotoPage.new()
		page.image.load_png_from_buffer(Marshalls.base64_to_raw(iter["data"]))
		page_list.push_back(page)
	current_page_instance = page_list[current_page]
	$sprite_2d.texture = ImageTexture.create_from_image(current_page_instance.image)

func dict() -> Dictionary:
	var data:Dictionary = super.dict()
	var data_arr:Array = []
	for iter:PhotoPage in page_list:
		data_arr.push_back({"data": Marshalls.raw_to_base64(iter.image.save_png_to_buffer())})
	data["photo"] = data_arr
	return data

func set_image(_image:Image) -> void:
	current_page_instance.image = _image
	$sprite_2d.texture = ImageTexture.create_from_image(current_page_instance.image)

func new_page() -> void:
	super.new_page()
	var page:PhotoPage = PhotoPage.new()
	page_list.push_back(page)
	current_page = page_list.size() - 1
	current_page_instance = page

func turn_page(_page:int) -> void:
	super.turn_page(_page)
	current_page = _page
	current_page_instance = page_list[current_page]
	$sprite_2d.texture = ImageTexture.create_from_image(current_page_instance.image)

func page_count() -> int:
	return page_list.size()

func page_index() -> int:
	return current_page
