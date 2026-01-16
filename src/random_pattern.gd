extends Resource

@export var map:PackedStringArray = []
@export var type:String = "default"
@export var connection:Array = [
	{
		"by": 0x73,
		"rotation": 0,
		"type": "default"
	}
]

func create_state(pattern_seed:int) -> State:
	seed(pattern_seed)
	var state:State = State.new()
	for i:int in 64:
		if map[i].length():	#长度为0的不能做除法
			var piece:int = map[i].unicode_at(randi() % map[i].length())
			if piece != ord(" "):
				state.add_piece(Chess.to_x88(i), piece)
	return state

func create_piece_instance(chessboard:Chessboard) -> void:
	pass
