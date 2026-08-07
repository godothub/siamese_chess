extends LevelEvent
class_name EventTitle

@export_multiline var text:String = ""

var expression:Expression = Expression.new()

func _ready() -> void:
	var error:int = expression.parse(text, ["Level", "Chess", "Setting", "Progress"])
	if error != OK:
		printerr(expression.get_error_text())
		return

func on_start() -> void:
	var result:Variant = expression.execute([level, Chess, Setting, Progress], self)
	if expression.has_execute_failed():
		printerr(expression.get_error_text())
		return
	var text_translated = result
	var by:int = level.chessboard.vector3_to_x88(position)
	level.title[by] = text_translated
