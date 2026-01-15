extends Node2D
class_name ChessboardFlat

var piece_path:Dictionary = {
	"K": "res://assets/texture/cburnett/wK.svg",
	"Q": "res://assets/texture/cburnett/wQ.svg",
	"R": "res://assets/texture/cburnett/wR.svg",
	"B": "res://assets/texture/cburnett/wB.svg",
	"N": "res://assets/texture/cburnett/wN.svg",
	"P": "res://assets/texture/cburnett/wP.svg",
	"k": "res://assets/texture/cburnett/bK.svg",
	"q": "res://assets/texture/cburnett/bQ.svg",
	"r": "res://assets/texture/cburnett/bR.svg",
	"b": "res://assets/texture/cburnett/bB.svg",
	"n": "res://assets/texture/cburnett/bN.svg",
	"p": "res://assets/texture/cburnett/bP.svg",
	"*": "res://assets/texture/siamesepiece/bX.svg",
	'#': "res://assets/texture/siamesepiece/bY.svg",
}

var state:State = null
var upper_left:Vector2 = Vector2(52, 52)
var pieces:Array[Sprite2D] = []

func draw() -> void:
	for iter:Sprite2D in pieces:
		iter.queue_free()
	pieces.clear()
	var piece_position:PackedInt32Array = state.get_all_pieces()
	for by:int in piece_position:
		var by_piece:int = state.get_piece(by)
		if !piece_path.has(String.chr(by_piece)):
			continue
		var piece_texture:Texture = load(piece_path[String.chr(by_piece)])
		var piece_instance:Sprite2D = Sprite2D.new()
		piece_instance.position = upper_left + Vector2(by % 16, by / 16) * 128
		piece_instance.texture = piece_texture
		piece_instance.centered = false
		pieces.push_back(piece_instance)
		add_child(piece_instance)

func set_state(_state:State) -> void:
	state = _state.duplicate()
	draw()
