extends Document
class_name Notable

class NotablePage extends RefCounted:
	var lines:Array = []

var notable_page_list:Array[NotablePage] = []

func parse(data:Dictionary) -> void:
	var data_arr:Array = data["notable"]
	for iter:Dictionary in data_arr:
		var page:NotablePage = NotablePage.new()
		page.lines = iter["lines"]
		notable_page_list.push_back(page)

func dict() -> Dictionary:
	var data:Dictionary = {}
	var data_arr:Array = []
	for page:NotablePage in notable_page_list:
		var iter:Dictionary = {}
		iter["lines"] = page.lines
		data_arr.push_back(iter)
	data["notable"] = data_arr
	return data

func new_page() -> void:
	var page:NotablePage = NotablePage.new()
	notable_page_list.push_back(page)

func set_lines(index:int, lines:Array) -> void:
	notable_page_list[index].lines = lines
	content_changed.emit()
