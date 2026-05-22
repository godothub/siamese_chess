extends Notable
class_name PhotoPaper

class PhotoPage extends RefCounted:
	var image:Image = Image.new()

var page_list:Array[PhotoPage] = []

func parse(data:Dictionary) -> void:
	super.parse(data)
	page_list.clear()
	var data_arr:Array = data["photo"]
	for iter:Dictionary in data_arr:
		var page:PhotoPage = PhotoPage.new()
		page.image.load_png_from_buffer(Marshalls.base64_to_raw(iter["data"]))
		page_list.push_back(page)

func dict() -> Dictionary:
	var data:Dictionary = super.dict()
	var data_arr:Array = []
	for iter:PhotoPage in page_list:
		data_arr.push_back({"data": Marshalls.raw_to_base64(iter.image.save_png_to_buffer())})
	data["photo"] = data_arr
	return data

func set_image(index:int, _image:Image) -> void:
	page_list[index].image = _image
	content_changed.emit()

func new_page() -> void:
	super.new_page()
	var page:PhotoPage = PhotoPage.new()
	page_list.push_back(page)

func page_count() -> int:
	return page_list.size()
