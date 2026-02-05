extends MarkerEvent

var taken:bool = false
@export var cover:Texture2D = null
@export var actor:PackedScene = null
@export var card_piece:int = 0
@export var comment:String = ""
@export var progress_key:String = ""

func _ready() -> void:
	taken = Progress.has_key(progress_key) && Progress.get_value(progress_key)
	visible = !taken

func event() -> void:
	if taken:
		level.change_state("explore_idle")
		return
	taken = true
	Progress.set_value(progress_key, true)
	match card_piece:
		ord("q"):
			Progress.accumulate("storage_queen", 1)
		ord("r"):
			Progress.accumulate("storage_rook", 1)
		ord("b"):
			Progress.accumulate("storage_bishop", 1)
		ord("n"):
			Progress.accumulate("storage_knight", 1)
		ord("p"):
			Progress.accumulate("storage_pawn", 1)
	visible = false
	Dialog.push_dialog(comment, "HINT_GET_PIECE", false, false, false)
	level.change_state("explore_idle")
