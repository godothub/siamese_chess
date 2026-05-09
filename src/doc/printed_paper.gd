extends Notable

class PrintedPage extends RefCounted:
	var path:String = ""
	var scene:PackedScene = null

var current_page:int = 0
var current_page_instance:PrintedPage = null
var instance:Node = null

var page_list:Array = []

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
	current_page = 0
	current_page_instance = page_list[page_index()]
	instance = current_page_instance.scene.instantiate()
	add_child(instance)


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
	turn_page(page_count() - 1)

func turn_page(_page:int) -> void:
	super.turn_page(_page)
	current_page = _page
	current_page_instance = page_list[current_page]
	instance.queue_free()
	instance = current_page_instance.scene.instantiate()
	add_child(instance)

func page_count() -> int:
	return page_list.size()

func page_index() -> int:
	return current_page
