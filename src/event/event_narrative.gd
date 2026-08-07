extends LevelEvent
class_name EventNarrative

# 表达式，返回字符串
@export_multiline var text:String = ""

@export var start_now:bool = true
@export var emit_cmd:String = ""

var expression:Expression = Expression.new()

func _ready() -> void:
	var error:int = expression.parse(text, ["Level", "Chess", "Setting", "Progress"])
	if error != OK:
		printerr(expression.get_error_text())
		return
	if emit_cmd != "":
		Terminal.connect("command_received", on_command_received)

func on_init() -> void:
	if start_now:
		read()

func read() -> void:
	var result:Variant = expression.execute([level, Chess, Setting, Progress], self)
	if expression.has_execute_failed():
		printerr(expression.get_error_text())
		return
	var text_translated = result
	Narrative.speak(text_translated)

func on_command_received(cmd:String) -> void:
	if cmd == emit_cmd:
		read()
