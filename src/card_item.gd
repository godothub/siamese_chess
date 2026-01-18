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
	visible = false
	var card:CardTarot = CardTarot.new()
	card.cover = cover
	card.piece = card_piece
	card.actor = actor.instantiate().set_larger_scale()
	HoldCard.add_card(card)
	Dialog.push_dialog(comment, "HINT_GET_PIECE", false, false, false)
	level.change_state("explore_idle")
