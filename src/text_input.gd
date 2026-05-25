extends CanvasLayer
class_name TextInput

signal confirmed(text:String)	# -1表示取消

var hint:String = "请输入："
var default:String = ""
var text:String = ""
var has_cancel:bool = true

const packed_scene:PackedScene = preload("res://scene/text_input.tscn")

static func create_text_input_instance(_hint:String, _default:String = "") -> TextInput:
	var instance:TextInput = packed_scene.instantiate()
	instance.hint = _hint
	instance.default = _default
	return instance

func _ready() -> void:
	$texture_rect/line_edit.connect("text_submitted", submit)
	$texture_rect/label.text = hint
	$texture_rect/label.visible = false
	$texture_rect/line_edit.visible = false
	$texture_rect/line_edit.text = default
	var tween:Tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property($texture_rect/label, "visible", true, 0)
	tween.tween_property($texture_rect/line_edit, "visible", true, 0)
	tween.tween_callback($texture_rect/line_edit.grab_focus)

func _unhandled_input(_event:InputEvent) -> void:
	get_viewport().set_input_as_handled()

func submit(_text:String) -> void:
	text = _text
	confirmed.emit(text)
	var tween:Tween = create_tween()
	tween.tween_property($texture_rect/label, "visible", false, 0)
	tween.tween_property($texture_rect/line_edit, "visible", false, 0)
	tween.tween_interval(0.3)
	tween.tween_callback(queue_free)
