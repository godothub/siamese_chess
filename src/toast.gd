extends CanvasLayer
class_name Toast

signal confirmed()

const packed_scene:PackedScene = preload("res://scene/toast.tscn")
var text:String = ""
var blackscreen_interval:float = 0.3

static func create_instance(_text:String) -> Toast:
	var instance:Toast = packed_scene.instantiate()
	instance.text = _text
	return instance

func _ready() -> void:
	$texture_rect/label.text = text
	$texture_rect/label.visible = false
	var tween:Tween = create_tween()
	tween.tween_interval(blackscreen_interval)
	tween.tween_property($texture_rect/label, "visible", true, 0)

func _input(_event:InputEvent) -> void:
	if _event is InputEventMouseButton || _event is InputEventKey:
		confirmed.emit()
		var tween:Tween = create_tween()
		tween.tween_property($texture_rect/label, "visible", false, 0)
		tween.tween_interval(blackscreen_interval)
		tween.tween_callback(queue_free)
	get_viewport().set_input_as_handled()
