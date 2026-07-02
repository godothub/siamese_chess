extends Level

var state:State = null
var initial_state:State = null

func _ready() -> void:
	super._ready()
	Player.force_set_camera($camera_3d)
	chessboard.set_enabled(true)
	while !is_instance_valid(state):
		var text_input_instance:TextInput = TextInput.create_text_input_instance("输入FEN格式的布局：", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
		add_child(text_input_instance)
		await text_input_instance.confirmed
		state = Chess.parse(text_input_instance.text)
	initial_state = state.duplicate()
	chessboard.set_state(state.duplicate())
	chessboard.add_default_piece_set()
	$procedure_game.start()

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey && event.is_pressed() && event.keycode == KEY_R:
		reset()

func reset() -> void:
	state = initial_state.duplicate()
	chessboard.set_state(initial_state)
	chessboard.remove_piece_set()
	chessboard.add_default_piece_set()
