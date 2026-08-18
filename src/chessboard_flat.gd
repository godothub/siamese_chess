extends Panel
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
@onready var item_list:ItemList = $sprite_chessboard/margin_container/item_list

func _ready() -> void:
	draw()

func draw() -> void:
	item_list.clear()
	var empty_image:Image = Image.create_empty(124, 124, true, Image.FORMAT_RGBA8)
	var empty_texture:Texture2D = ImageTexture.create_from_image(empty_image)
	for i:int in 64:
		item_list.add_icon_item(empty_texture, false)
	if !state:
		return
	var piece_position:PackedInt32Array = state.get_all_pieces()
	for by:int in piece_position:
		var by_piece:int = state.get_piece(by)
		if !piece_path.has(String.chr(by_piece)):
			continue
		var piece_texture:Texture = load(piece_path[String.chr(by_piece)])
		item_list.set_item_icon(Chess.x88_to_c64(by), piece_texture)

func set_state(_state:State) -> void:
	state = _state.duplicate()
	if is_inside_tree():
		draw()
