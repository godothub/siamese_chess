extends CanvasLayer

var template_list:Dictionary = {
	"printed": "res://scene/printed_paper.tscn",
	"history": "res://scene/history.tscn",
	"draft": "res://scene/draft.tscn",
	"piece": "res://scene/model.tscn",
	"inspectable": "res://scene/model.tscn"
}

var document:Document = null
var document_list:PackedStringArray = []
var button_list:Array[Button] = []

func _ready() -> void:
	visible = false
	$texture_rect/button_close.connect("button_up", close)
	$texture_rect/h_box_container/button_rename.connect("button_up", rename_pressed)
	$texture_rect/h_box_container/button_add_empty.connect("button_up", add_empty_pressed)
	$texture_rect/h_box_container/button_duplicate.connect("button_up", duplicate_pressed)
	$texture_rect/h_box_container/button_delete.connect("button_up", delete_pressed)

func open() -> void:
	$texture_rect/button_close.grab_focus()
	visible = true
	update_list()

func update_list() -> void:
	for iter:Button in button_list:
		iter.queue_free()
	button_list.clear()
	document_list.clear()
	if !is_instance_valid(document):
		$texture_rect/document_browser.visible = false
	var dir:DirAccess = DirAccess.open("user://archive/")
	if !dir:
		DirAccess.make_dir_absolute("user://archive/")
		dir = DirAccess.open("user://archive/")
	dir.list_dir_begin()
	var file_name:String = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			document_list.push_back(file_name)
		file_name = dir.get_next()

	for iter:String in document_list:
		var button = Button.new()
		button.text = iter
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		button.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.6, 0.6, 0.6, 1))
		button.add_theme_font_size_override("font_size", 30)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_font_override("font", preload("res://assets/fonts/FangZhengShuSongJianTi-1.ttf"))
		button.connect("button_up", open_document.bind(iter))
		$texture_rect/scroll_container/v_box_container.add_child(button)
		button_list.push_back(button)
	
func open_document(filename:String) -> void:
	if is_instance_valid(document):
		document.save_file()
	filename = filename.get_file()
	var filename_splited:PackedStringArray = filename.split(".")	# 模板.名称.json
	document = load(template_list[filename_splited[0]]).instantiate()
	document.set_filename(filename)
	document.load_file()
	$texture_rect/document_browser.set_document(document)
	$texture_rect/document_browser.visible = true

func close() -> void:
	$texture_rect/document_browser.visible = false
	visible = false

func rename_pressed() -> void:
	if !is_instance_valid(document):
		return
	var filename_splited:PackedStringArray = document.get_filename().split(".")
	var text_input_instance:TextInput = TextInput.create_text_input_instance("重命名：", filename_splited[1])
	add_child(text_input_instance)
	await text_input_instance.confirmed
	filename_splited[1] = text_input_instance.text
	document.clear_file()
	document.set_filename(".".join(filename_splited))
	document.save_file()
	update_list()

func duplicate_pressed() -> void:
	if !is_instance_valid(document):
		return
	var filename_splited:PackedStringArray = document.get_filename().split(".")
	filename_splited[1] += "-dup"
	document.set_filename(".".join(filename_splited))
	document.save_file()
	update_list()

func delete_pressed() -> void:
	if !is_instance_valid(document):
		return
	document.clear_file()
	document.queue_free()
	update_list()

func add_empty_pressed() -> void:
	document = Document.new()
	document.set_filename("draft.%d.json" % Time.get_unix_time_from_system())
	document.save_file()
	update_list()
