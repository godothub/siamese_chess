extends Level

@onready var standard_history_document:Document = load("res://src/doc/history.gd").new()
@onready var standard_chessboard:Chessboard = $table_0/chessboard_standard
@onready var edit_event:MarkerProcedure = $marker_edit
@onready var game_event:MarkerProcedure = $marker_game
var standard_player_group:int = 0

func _ready() -> void:
	super._ready()
	standard_history_document.set_filename("history.match_with_yulan.json")
	standard_history_document.load_file()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))
	
	standard_chessboard.set_enabled(false)
	$player.add_inspectable_item(standard_chessboard)
	$pastor.play_animation("thinking")
	edit_event.connect("procedure_end", select_turn)
	game_event.connect("procedure_end", game_end)

func interact_pastor() -> void:
	change_state("yulan_game")
	$player.force_set_camera($camera_pastor)

	var from:int = Chess.c64_to_x88(Chess.first_bit($chessboard.state.get_bit(player_king)))
	if from != 0x54:
		$chessboard.execute_move(Chess.create(from, 0x54, 0))
		await $chessboard.animation_finished
	$chessboard.set_enabled(false)
	standard_chessboard.set_enabled(true)
	$chessboard/pieces/cheshire.set_position($chessboard.name_to_vector3("e2"))
	$chessboard/pieces/cheshire.set_rotation(Vector3(0, PI / 2, 0))
	$chessboard/pieces/cheshire.play_animation("thinking")
	$player.force_set_camera($camera_chessboard)

	standard_chessboard.state = Chess.create_initial_state()
	standard_chessboard.remove_piece_set()
	standard_chessboard.add_default_piece_set()
	edit_event.start()

func select_turn(result:String) -> void:
	if result == "canceled":
		game_end()
		return
	Dialog.on_select.connect(func (_selected:String) -> void:
		match _selected:
			"SELECTION_CANCEL":
				game_end()
				return
			"SELECTION_PLAY_AS_WHITE":
				standard_player_group = 0
			"SELECTION_PLAY_AS_BLACK":
				standard_player_group = 1
			"SELECTION_PLAY_AS_RANDOM":
				standard_player_group = randi() % 2
		if standard_player_group == 0:
			standard_chessboard.rotation.y = 0
		else:
			standard_chessboard.rotation.y = PI
		game_event.player_group = standard_player_group
		game_event.start()
	, CONNECT_ONE_SHOT)
	Dialog.push_selection(["SELECTION_PLAY_AS_BLACK", "SELECTION_PLAY_AS_WHITE", "SELECTION_PLAY_AS_RANDOM", "SELECTION_CANCEL"], "", true, false)

func game_end(_result:String = "") -> void:
	$player.force_set_camera($camera)
	$chessboard/pieces/cheshire.play_animation("battle_idle")
	$chessboard/pieces/cheshire.set_position($chessboard.name_to_vector3("e3"))
	$chessboard.set_enabled(true)
	standard_chessboard.set_enabled(false)
	change_state("")
