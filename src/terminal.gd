extends CanvasLayer

# 指令操作，这个地方发送指令，其他类型在有需要时通过信号进行接收

signal command_received(cmd:String)

func _ready() -> void:
	visible = false
	$texture_rect_top/margin_container/line_edit.connect("text_submitted", exec)

func _unhandled_input(_event:InputEvent) -> void:
	if _event is InputEventKey && _event.pressed:
		if _event.is_action_pressed("terminal") && !visible:
			open()
			get_viewport().set_input_as_handled()
		if _event.is_action_pressed("ui_cancel") && visible:
			close()
			get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	$texture_rect_top/margin_container/line_edit.text = ""
	$texture_rect_top/margin_container/line_edit.grab_focus()

func close() -> void:
	visible = false

func exec(cmd:String) -> void:
	close()
	command_received.emit(cmd)
