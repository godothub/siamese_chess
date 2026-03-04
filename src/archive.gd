extends CanvasLayer

var template_list:Dictionary = {
	"printed": "res://scene/printed_paper.tscn",
	"photo": "res://scene/photo_paper.tscn",
	"history": "res://scene/history.tscn",
	"draft": "res://scene/draft.tscn",
	"piece": "res://scene/model.tscn",
	"inspectable": "res://scene/model.tscn"
}

var document:Document = null
var document_list:PackedStringArray = []
var button_list:Array[Button] = []
var mouse_move_start:Vector2 = Vector2()
var mouse_moved:bool = false
var scroll_velocity:float = 0

func _ready() -> void:
	visible = false
	$texture_rect/button_close.connect("pressed", close)
	$texture_rect/h_box_container/button_rename.connect("pressed", rename_pressed)
	$texture_rect/h_box_container/button_add_empty.connect("pressed", add_empty_pressed)
	$texture_rect/h_box_container/button_duplicate.connect("pressed", duplicate_pressed)
	$texture_rect/h_box_container/button_delete.connect("pressed", delete_pressed)
	$texture_rect/scroll_container.connect("gui_input", scroll_container_input)
	set_process(false)

func _process(_delta:float) -> void:
	$texture_rect/scroll_container.scroll_vertical -= scroll_velocity
	scroll_velocity = max(0, abs(scroll_velocity) - 1) if scroll_velocity > 0 else -max(0, abs(scroll_velocity) - 1)

func open() -> void:
	set_process(true)
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
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.connect("pressed", func () -> void:
			if !mouse_moved:
				open_document(iter)
		)
		button.connect("gui_input", button_input)
		$texture_rect/scroll_container/v_box_container.add_child(button)
		button_list.push_back(button)

func button_input(event:InputEvent) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_move_start = event.global_position
			mouse_moved = false

func scroll_container_input(event:InputEvent) -> void:
	if event is InputEventMouseMotion && (event.button_mask & MOUSE_BUTTON_MASK_LEFT) && (mouse_moved || event.global_position.distance_squared_to(mouse_move_start) > 400):
		mouse_moved = true
		scroll_velocity = event.relative.y

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
	set_process(false)

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
