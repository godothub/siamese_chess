extends CanvasLayer
class_name Toast

signal confirmed()

const packed_scene:PackedScene = preload("res://scene/toast.tscn")
var text:String = ""
var blackscreen_interval:float = 0.3
var tween:Tween = null

static func create_instance(_text:String) -> Toast:
	var instance:Toast = packed_scene.instantiate()
	instance.text = _text
	return instance

func _ready() -> void:
	$texture_rect/margin_container/label.text = text
	$texture_rect/margin_container/label.visible = false
	tween = create_tween()
	tween.tween_interval(blackscreen_interval)
	tween.tween_property($texture_rect/margin_container/label, "visible", true, 0)
	Narrative.speak(tr(text))

func _unhandled_input(_event:InputEvent) -> void:
	if tween && tween.is_running():
		return
	if _event is InputEventMouseButton || _event is InputEventKey:
		confirmed.emit()
		tween.kill()
		tween = create_tween()
		tween.tween_property($texture_rect/margin_container/label, "visible", false, 0)
		tween.tween_interval(blackscreen_interval)
		tween.tween_callback(queue_free)
	get_viewport().set_input_as_handled()
