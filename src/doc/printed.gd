extends Notable
class_name Printed

class PrintedPage extends RefCounted:
	var path:String = ""
	var scene:PackedScene = null

var page_list:Array[PrintedPage] = []

func _ready() -> void:
	pass

func parse(data:Dictionary) -> void:
	super.parse(data)
	var data_arr:Array = data["printed"]
	for iter:Dictionary in data_arr:
		var page:PrintedPage = PrintedPage.new()
		page.path = iter["path"]
		page.scene = load(page.path)
		page_list.push_back(page)

func dict() -> Dictionary:
	var data:Dictionary = super.dict()
	var data_arr:Array = []
	for iter:PrintedPage in page_list:
		data_arr.push_back({"path": iter.path})
	data["printed"] = data_arr
	return data

func new_page() -> void:
	super.new_page()
	var page:PrintedPage = PrintedPage.new()
	page_list.push_back(page)

func page_count() -> int:
	return page_list.size()
