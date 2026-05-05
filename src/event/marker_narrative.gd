extends MarkerEvent
class_name MarkerNarrative

# 表达式，返回bool，支持使用Level、Petting、Progress、Chess这几个对象
@export_multiline() var condition:String = ""
var condition_expression:Expression = Expression.new()
# 填写语音ID，所以无需multiline
@export var text:String = ""
# 表达式，返回Variant
@export var placeholder:Dictionary = {}
#尤其小心：不同语言存在语序区别，占位符需要以键值对为准
var placeholder_expression:Dictionary[String, Expression] = {}

func _ready() -> void:
	if condition:
		var error:int = condition_expression.parse(condition, ["Level", "Setting", "Progress", "Chess"])
		if error != OK:
			printerr(condition_expression.get_error_text())
			return
	for key:String in placeholder:
		var expression:Expression = Expression.new()
		var error:int = expression.parse(placeholder[key], ["Level", "Setting", "Progress", "Chess"])
		if error != OK:
			printerr(expression.get_error_text())
			return
		placeholder_expression[key] = expression

func on_start() -> void:
	if !Setting.get_value("text_to_speech"):
		return
	if condition:
		var result:Variant = condition_expression.execute([level, Setting, Progress, Chess])
		if condition_expression.has_execute_failed():
			printerr(condition_expression.get_error_text())
			return
		if !result:
			return
	var text_translated:String = tr(text)
	var placeholder_result:Dictionary = {}
	for key:String in placeholder_expression:
		var result:Variant = placeholder_expression[key].execute([level, Setting, Progress, Chess])
		if placeholder_expression[key].has_execute_failed():
			printerr(placeholder_expression[key].get_error_text())
			return
		placeholder_result[key] = result
	text_translated = text_translated.format(placeholder_result)
	DisplayServer.tts_speak(text_translated, Setting.get_value("voice"))
