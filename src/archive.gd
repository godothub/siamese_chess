extends CanvasLayer

var document_view_list:Dictionary = {
	"printed": "res://scene/doc/printed.tscn",
	"photo": "res://scene/doc/photo.tscn",
	"history": "res://scene/doc/history.tscn",
	"draft": "res://scene/doc/draft.tscn",
	"piece": "res://scene/doc/model.tscn",
	"inspectable": "res://scene/doc/model.tscn"
}

var document_data_list:Dictionary = {
	"printed": "res://src/doc/printed.gd",
	"photo": "res://src/doc/photo.gd",
	"history": "res://src/doc/history.gd",
	"draft": "res://src/doc/notable.gd",
	"piece": "res://src/doc/model.gd",
	"inspectable": "res://src/doc/model.gd"
}

var document:Document = null
var document_view:DocumentView = null
var document_list:PackedStringArray = []
var button_list:Array[Button] = []
var mouse_move_start:Vector2 = Vector2()
var mouse_moved:bool = false
var scroll_velocity:float = 0
var current_button:Button = null

@onready var regex_help:RegEx = RegEx.create_from_string("(?i:^\\s*(help|\\?)\\s*$)")
@onready var regex_about:RegEx = RegEx.create_from_string("(?i:^\\s*about\\s*$)")
@onready var regex_open:RegEx = RegEx.create_from_string("^\\s*(?i:open)\\s*(?P<file>\\S+)\\s*$")
@onready var regex_close:RegEx = RegEx.create_from_string("(?i:^\\s*close\\s*$)")
@onready var regex_list:RegEx = RegEx.create_from_string("(?i:^\\s*archive\\s*$)")

func _ready() -> void:
	visible = false
	$texture_rect/button_close.connect("pressed", close)
	$texture_rect/button_close.connect("mouse_entered", read_title.bind("ICON_CLOSE"))
	$texture_rect/button_close.connect("focus_entered", read_title.bind("ICON_CLOSE"))
	$texture_rect/scroll_container.connect("gui_input", scroll_container_input)
	$texture_rect/document_browser.connect("hidden", func () -> void:
		if current_button:
			current_button.grab_focus()
		else:
			$texture_rect/button_close.grab_focus()
	)
	Terminal.connect("command_received", on_command_received)
	set_physics_process(false)

func _physics_process(_delta:float) -> void:
	$texture_rect/scroll_container.scroll_vertical -= scroll_velocity
	scroll_velocity = max(0, abs(scroll_velocity) - 1) if scroll_velocity > 0 else -max(0, abs(scroll_velocity) - 1)
	if Input.is_action_just_pressed("ui_cancel") && !$texture_rect/document_browser.visible:
		close()

func open() -> void:
	$audio_stream_player_open.play()
	set_physics_process(true)
	$texture_rect/button_close.grab_focus()
	document = null
	visible = true
	update_list()

func update_list() -> void:
	for iter:Button in button_list:
		iter.queue_free()
	button_list.clear()
	document_list.clear()
	if !is_instance_valid(document):
		$texture_rect/document_browser.close()
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
		var button:Button = Button.new()
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
				current_button = button
				open_document(iter)
		)
		button.connect("mouse_entered", read_title.bind(iter))
		button.connect("focus_entered", read_title.bind(iter))
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

func read_title(text:String) -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr(text), true)

func open_document(filename:String) -> void:
	filename = filename.get_file()
	if !FileAccess.file_exists("user://archive/" + filename):
		return
	$audio_stream_player_confirm.play()
	$texture_rect/document_browser.close()
	var filename_splited:PackedStringArray = filename.split(".")	# 模板.名称.json
	document = load(document_data_list[filename_splited[0]]).new()
	document_view = load(document_view_list[filename_splited[0]]).instantiate()
	document.set_filename(filename)
	document.load_file()
	document_view.set_document(document)
	$texture_rect/document_browser.set_document_view(document_view)
	$texture_rect/document_browser.open()

func close() -> void:
	$audio_stream_player_confirm.play()
	$audio_stream_player_close.play()
	$texture_rect/document_browser.close()
	visible = false
	set_physics_process(false)

func on_command_received(cmd:String) -> void:
	if regex_about.search(cmd):
		open_about()
		return
	if regex_help.search(cmd):
		open_help()
		return
	if regex_list.search(cmd):
		update_list()
		Terminal.print("\n".join(document_list))
	if visible && regex_close.search(cmd):
		close()
		return
	var regex_open_result:RegExMatch = regex_open.search(cmd)
	if regex_open_result:
		if !FileAccess.file_exists("user://archive/" + regex_open_result.get_string("file")):
			Terminal.print(tr("ARCHIVE_FILE_NOT_FOUND"))
			return
		if !visible:
			Narrative.speak(tr("ARCHIVE_FILE_OPENED"))
			open()
		open_document(regex_open_result.get_string("file"))
		return

func open_about() -> void:
	var path:String = "user://archive/printed.siamesechess.json"
	var file_content:Dictionary = {
		"notable": [{"lines": []}, {"lines": []}, {"lines": []}],
		"printed": [
			{"path": "res://assets/archive/welcome.tscn"},
			{"path": "res://assets/archive/about_this_program.tscn"},
			{"path": "res://assets/archive/credits.tscn"}
		]
	}
	if !FileAccess.file_exists(path):
		var dir:DirAccess = DirAccess.open("user://archive/")
		if !dir:
			DirAccess.make_dir_absolute("user://archive/")
			dir = DirAccess.open("user://archive/")
		var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(file_content))
		file.close()
	Archive.open()
	Archive.open_document(path)

func open_help() -> void:
	var path:String = "user://archive/printed.manual.json"
	var file_content:Dictionary = {
		"notable": [{"lines": []}, {"lines": []}, {"lines": []}, {"lines": []}, {"lines": []}],
		"printed": [
			{"path": "res://assets/archive/manual.tscn"},
			{"path": "res://assets/archive/manual_general.tscn"},
			{"path": "res://assets/archive/manual_control_mouse_touch.tscn"},
			{"path": "res://assets/archive/manual_control_keyboard_gamepad.tscn"},
			{"path": "res://assets/archive/manual_terminal.tscn"}
		]
	}
	if !FileAccess.file_exists(path):
		var dir:DirAccess = DirAccess.open("user://archive/")
		if !dir:
			DirAccess.make_dir_absolute("user://archive/")
			dir = DirAccess.open("user://archive/")
		var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(file_content))
		file.close()
	Archive.open()
	Archive.open_document(path)
