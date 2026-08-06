extends CanvasLayer

# 指令操作，这个地方发送指令，其他类型在有需要时通过信号进行接收

signal command_received(cmd:String)

var limit:int = 1024

var history:Array[String] = [""]

var history_index:int = -1

var console_thread:Thread = null

func _ready() -> void:
	visible = false
	$texture_rect_top/margin_container/line_edit.connect("gui_input", line_edit_input)
	$texture_rect_top/margin_container/line_edit.connect("text_submitted", exec)
	$texture_rect_top/margin_container/line_edit.connect("text_changed", enter)
	if OS.get_cmdline_args().has("--terminal"):
		console_thread = Thread.new()
		console_thread.start(listen_stdin)

func _unhandled_input(_event:InputEvent) -> void:
	if _event.is_action_pressed("terminal") && !visible:
		open()
		get_viewport().set_input_as_handled()
	if _event.is_action_pressed("ui_cancel") && visible:
		close()
		get_viewport().set_input_as_handled()

func line_edit_input(_event:InputEvent) -> void:
	if _event is InputEventKey && _event.pressed:
		if _event.is_action_pressed("terminal") && !visible:
			open()
			get_viewport().set_input_as_handled()
		if _event.is_action_pressed("ui_cancel") && visible:
			close()
			get_viewport().set_input_as_handled()
		if _event.keycode == KEY_UP && visible:
			history_index -= 1
			history_index = clamp(history_index, 0, history.size() - 1)
			$texture_rect_top/margin_container/line_edit.text = history[history_index]
			get_viewport().set_input_as_handled()
		if _event.keycode == KEY_DOWN && visible:
			history_index += 1
			history_index = clamp(history_index, 0, history.size() - 1)
			$texture_rect_top/margin_container/line_edit.text = history[history_index]
			get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	history[-1] = ""
	$texture_rect_top/margin_container/line_edit.text = ""
	history_index = history.size() - 1
	$texture_rect_top/margin_container/line_edit.grab_focus()

func close() -> void:
	visible = false

func listen_stdin() -> void:
	while true:
		var cmd:String = OS.read_string_from_stdin()
		exec.call_deferred(cmd)

func exec(cmd:String) -> void:
	close()
	if cmd != "":
		command_received.emit(cmd)
		history.push_back("")
	while history.size() > limit:
		history.pop_front()

func enter(cmd:String) -> void:
	history[-1] = cmd
	history_index = history.size() - 1
