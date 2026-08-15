extends Panel

var standard_yulan:bool = false
var two_rook_yulan:bool = false
var queen_yulan:bool = false
var rook_yulan:bool = false
var pawn_yulan:bool = false
var two_bishop_yulan:bool = false
var bishop_knight_yulan:bool = false
var standard_carnation:bool = false
var two_rook_carnation:bool = false
var queen_carnation:bool = false
var rook_carnation:bool = false
var pawn_carnation:bool = false
var two_bishop_carnation:bool = false
var bishop_knight_carnation:bool = false
var memory_carnation:int = 0
var position_carnation:float = false

func _ready() -> void:
	find_document()
	$texture_rect/rich_text_label.text = tr("DOCUMENT_CONTENT_BASEMENT_RECORD").format({
		"standard_yulan": "√" if standard_yulan else "",
		"two_rook_yulan": "√" if two_rook_yulan else "",
		"queen_yulan": "√" if queen_yulan else "",
		"rook_yulan": "√" if rook_yulan else "",
		"pawn_yulan": "√" if pawn_yulan else "",
		"two_bishop_yulan": "√" if two_bishop_yulan else "",
		"bishop_knight_yulan": "√" if bishop_knight_yulan else "",
		"standard_carnation": "√" if standard_carnation else "",
		"two_rook_carnation": "√" if two_rook_carnation else "",
		"queen_carnation": "√" if queen_carnation else "",
		"rook_carnation": "√" if rook_carnation else "",
		"pawn_carnation": "√" if pawn_carnation else "",
		"two_bishop_carnation": "√" if two_bishop_carnation else "",
		"bishop_knight_carnation": "√" if bishop_knight_carnation else "",
		"memory_carnation": "%d" % memory_carnation,
		"position_carnation": "%f" % position_carnation
	})

func find_document() -> void:
	if FileAccess.file_exists("user://archive/history.cafe.json"):
		var history:History = History.new()
		history.set_filename("history.cafe.json")
		history.load_file()
		for page:History.HistoryPage in history.page_list:
			if page.fen == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1":
				if page.white == "CHAR_LOTUS" && page.result == "checkmate_white" || page.black == "CHAR_LOTUS" && page.result == "checkmate_black":
					standard_yulan = true
			if page.fen.begins_with("8/8/8/3k4/8/8/8/R3K2R w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				two_rook_yulan = true
			if page.fen.begins_with("4k3/8/8/8/8/8/8/3QK3 w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				queen_yulan = true
			if page.fen.begins_with("4k3/8/8/8/8/8/8/R3K3 w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				rook_yulan = true
			if page.fen.begins_with("4k3/8/8/8/8/8/3PK3/8 w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				pawn_yulan = true
			if page.fen.begins_with("4k3/8/8/8/8/8/8/2B1KB2 w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				two_bishop_yulan = true
			if page.fen.begins_with("4k3/8/8/8/8/8/8/4KBN1 w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				bishop_knight_yulan = true
	if FileAccess.file_exists("user://archive/history.garden.json"):
		var history:History = History.new()
		history.set_filename("history.cafe.json")
		history.load_file()
		for page:History.HistoryPage in history.page_list:
			if page.fen == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1":
				if page.white == "CHAR_LOTUS" && page.result == "checkmate_white" || page.black == "CHAR_LOTUS" && page.result == "checkmate_black":
					standard_carnation = true
			if page.fen.begins_with("8/8/8/3k4/8/8/8/R3K2R w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				two_rook_carnation = true
			if page.fen.begins_with("4k3/8/8/8/8/8/8/3QK3 w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				queen_carnation = true
			if page.fen.begins_with("4k3/8/8/8/8/8/8/R3K3 w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				rook_carnation = true
			if page.fen.begins_with("4k3/8/8/8/8/8/3PK3/8 w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				pawn_carnation = true
			if page.fen.begins_with("4k3/8/8/8/8/8/8/2B1KB2 w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				two_bishop_carnation = true
			if page.fen.begins_with("4k3/8/8/8/8/8/8/4KBN1 w") && page.white == "CHAR_LOTUS" && page.result == "checkmate_white":
				bishop_knight_carnation = true
