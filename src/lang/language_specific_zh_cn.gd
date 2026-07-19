extends LanguageSpecific
class_name LanguageSpecificZhCN

const map:Dictionary = {
	ord("K"): "PIECE_WHITE_KING",
	ord("Q"): "PIECE_WHITE_QUEEN",
	ord("R"): "白居",
	ord("B"): "PIECE_WHITE_BISHOP",
	ord("N"): "PIECE_WHITE_KNIGHT",
	ord("P"): "PIECE_WHITE_PAWN",
	ord("k"): "PIECE_BLACK_KING",
	ord("q"): "PIECE_BLACK_QUEEN",
	ord("r"): "黑居",
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
	"K": "王",
	"Q": "后",
	"R": "居",	# “车”在象棋中的读音
	"B": "象",
	"N": "马",
	"P": "兵",
	"a": " A ",
	"b": " B ",
	"c": " C ",
	"d": " D ",
	"e": " E ",
	"f": " F ",
	"g": " G ",
	"h": " H ",
	"1": "一",
	"2": "二",
	"3": "三",
	"4": "四",
	"5": "五",
	"6": "六",
	"7": "七",
	"8": "八",
	"x": "吃",
	"+": "将军",
	"=": "升变为",
	"#": "将杀",
	"O-O": "短易位",
	"O-O-O": "长易位",
	"-": "空"
}

static func piece_to_pronounce(piece:int) -> String:
	return TranslationServer.translate(map.get(piece))

static func move_name_to_pronounce(move_name:String) -> String:
	if move_name == "O-O" || move_name == "O-O-O":
		return char_to_pronounce[move_name]
	var output:String = ""
	for i:int in move_name.length():
		output += char_to_pronounce[move_name[i]]
	return output

static func position_name_to_pronounce(position_name:String) -> String:
	var output:String = ""
	for i:int in position_name.length():
		output += char_to_pronounce[position_name[i]]
	return output
