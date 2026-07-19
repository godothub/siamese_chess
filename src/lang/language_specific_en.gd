extends LanguageSpecific
class_name LanguageSpecificEN

const map:Dictionary = {
	ord("K"): "PIECE_WHITE_KING",
	ord("Q"): "PIECE_WHITE_QUEEN",
	ord("R"): "PIECE_WHITE_ROOK",
	ord("B"): "PIECE_WHITE_BISHOP",
	ord("N"): "PIECE_WHITE_KNIGHT",
	ord("P"): "PIECE_WHITE_PAWN",
	ord("k"): "PIECE_BLACK_KING",
	ord("q"): "PIECE_BLACK_QUEEN",
	ord("r"): "PIECE_BLACK_ROOK",
	ord("b"): "PIECE_BLACK_BISHOP",
	ord("n"): "PIECE_BLACK_KNIGHT",
	ord("p"): "PIECE_BLACK_PAWN",
	ord("#"): "PIECE_BARRIER",
	ord("*"): "PIECE_BREAKABLE_BARRIER",
	ord("|"): "WALL_FILE",
	ord("-"): "WALL_RANK",
	ord("+"): "WALL_DIAG"
}

const char_to_pronounce:Dictionary = {
	"K": "King",
	"Q": "Queen",
	"R": "Rook",
	"B": "Bishop",
	"N": "Knight",
	"P": "Pawn",
	"a": "A",
	"b": "B",
	"c": "C",
	"d": "D",
	"e": "E",
	"f": "F",
	"g": "G",
	"h": "H",
	"1": "one",
	"2": "two",
	"3": "three",
	"4": "four",
	"5": "five",
	"6": "six",
	"7": "seven",
	"8": "eight",
	"x": "takes",
	"+": "check",
	"=": "promote to",
	"#": "checkmate",
	"O-O": "short castle",
	"O-O-O": "long castle",
	"-": "empty"
}

static func piece_to_pronounce(piece:int) -> String:
	return TranslationServer.translate(map.get(piece))

static func move_name_to_pronounce(move_name:String) -> String:
	if move_name == "O-O" || move_name == "O-O-O":
		return char_to_pronounce[move_name]
	var output:String = ""
	for i:int in move_name.length():
		output += char_to_pronounce[move_name[i]] + " "	# 英语需要空格
	return output

static func position_name_to_pronounce(position_name:String) -> String:
	var output:String = ""
	for i:int in position_name.length():
		output += char_to_pronounce[position_name[i]] + " "
	return output
