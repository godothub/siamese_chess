extends LevelEvent
class_name EventNarrative

# 表达式，返回字符串
@export_multiline var text:String = ""

@export var start_now:bool = true
@export var emit_cmd:String = ""

@onready var regex_emit_cmd:RegEx = null

var expression:Expression = Expression.new()

func _ready() -> void:
	regex_emit_cmd = RegEx.create_from_string(emit_cmd)
	var error:int = expression.parse(text, ["Level", "Chess", "Setting", "Progress"])
	if error != OK:
		printerr(expression.get_error_text())
		return
	if emit_cmd != "":
		Terminal.connect("command_received", on_command_received)

func on_init() -> void:
	if start_now:
		read()

func read(use_toast:bool = false) -> void:
	var result:Variant = expression.execute([level, Chess, Setting, Progress], self)
	if expression.has_execute_failed():
		printerr(expression.get_error_text())
		return
	var text_translated:String = result
	if use_toast:
		Terminal.print(text_translated)
	else:
		#toast自己已经speak过了
		Narrative.speak(text_translated)

func on_command_received(cmd:String) -> void:
	if regex_emit_cmd.search(cmd):
		read(true)
