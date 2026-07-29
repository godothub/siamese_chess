extends Level

@onready var standard_chessboard:Chessboard = $garden_steel_table/chessboard
var standard_player_group:int = 0
var signal_container:SignalContainer = SignalContainer.new()

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/405135__mjeno__autumn-forest-leaves-falling-close-to-pond-iii-loopable.wav"))
	Player.force_set_camera($camera)
	$event_actor_carnation.instance.play_animation("sit_and_think")
	standard_chessboard.set_enabled(false)
	$chessboard.set_enabled(true)

func interact_carnation() -> void:
	change_state("game")
	var carnation_pos:Vector3 = $event_actor_carnation.global_position
	var current_position_2d:Vector2 = Vector2(global_position.x, global_position.z)
	var target_position_2d:Vector2 = Vector2(carnation_pos.x, carnation_pos.z)
	var target_angle:float = -current_position_2d.angle_to_point(target_position_2d) + PI / 2
	target_angle = global_rotation.y + angle_difference(global_rotation.y, target_angle)
	$event_explore.instance.get_node("animation_tree").active = false
	$event_actor_carnation.instance.get_node("animation_tree").active = false
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_dialog_demo.procedure_end, dialog_demo_end)
	$procedure_dialog_demo.start()

func dialog_demo_end(_result:String) -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision_demo.procedure_end, decision_demo_end)
	$procedure_decision_demo.start()

func decision_demo_end(_result:String) -> void:
	signal_container.disconnect_all()
	match _result:
		"CARNATION_TALK_DEMO_MATCH":
			blindfold_chess()
		"CARNATION_TALK_DEMO_POSITIONING":
			position_practice()
		"CARNATION_TALK_DEMO_MEMORIZING":
			memory_practice()
		"CARNATION_TALK_DEMO_CANCEL":
			interact_carnation_end()
		"":
			interact_carnation_end()

func blindfold_chess(_result:String = "") -> void:
	standard_chessboard.set_enabled(false)
	$chessboard.set_enabled(false)
	standard_chessboard.state = Chess.create_initial_state()
	standard_chessboard.add_default_piece_set()
	Player.force_set_camera($camera_chessboard)
	blindfold_side_decision()

func blindfold_side_decision(_result:String = "") -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision_side.procedure_end, blindfold_decision_end)
	$procedure_decision_side.start()

func blindfold_decision_end(_result:String) -> void:
	match _result:
		"":
			interact_carnation_end()
			return
		"CARNATION_TALK_DEMO_HOW_TO_PLAY":
			signal_container.add_connection($procedure_dialog_blindfold_help.procedure_end, blindfold_side_decision)
			$procedure_dialog_blindfold_help.start()
			return
		"SELECTION_PLAY_AS_WHITE":
			$procedure_game.player_group = 0
		"SELECTION_PLAY_AS_BLACK":
			$procedure_game.player_group = 1
		"SELECTION_PLAY_AS_RANDOM":
			$procedure_game.player_group = randi() % 2
		"CARNATION_TALK_DEMO_EDIT":
			standard_chessboard.set_enabled(true)
			$chessboard.set_enabled(false)
			signal_container.add_connection($procedure_edit_game.procedure_end, blindfold_side_decision)
			$procedure_edit_game.start()
			return
	if $procedure_game.player_group == 0:
		$procedure_game.white_name = "CHAR_LOTUS"
		$procedure_game.black_name = "CHAR_CARNATION"
		standard_chessboard.rotation.y = -PI / 2
	else:
		$procedure_game.white_name = "CHAR_CARNATION"
		$procedure_game.black_name = "CHAR_LOTUS"
		standard_chessboard.rotation.y = PI / 2
	
	$procedure_game.recorder_name = "CHAR_LOTUS"
	standard_chessboard.remove_piece_set()
	standard_chessboard.set_enabled(true)
	$chessboard.set_enabled(false)
	$event_actor_carnation.instance.get_node("animation_tree").active = true
	$event_actor_carnation.instance.play_animation("sit_and_think")
	Player.force_set_camera($camera_chessboard)
	signal_container.add_connection($procedure_game.procedure_end, blindfold_game_end)
	$procedure_game.start()

func blindfold_game_end(_result:String) -> void:
	signal_container.disconnect_all()
	if _result == "":
		interact_carnation_end()
		return
	signal_container.add_connection(Dialog.on_next, interact_carnation_end)
	match _result:
		"checkmate_black":
			Dialog.push_dialog("HINT_BLACK_CHECKMATE", "CHAR_CARNATION", true, true)
		"checkmate_white":
			Dialog.push_dialog("HINT_WHITE_CHECKMATE", "CHAR_CARNATION", true, true)
		"stalemate_black":
			Dialog.push_dialog("HINT_DRAW", "CHAR_CARNATION", true, true)
		"stalemate_white":
			Dialog.push_dialog("HINT_DRAW", "CHAR_CARNATION", true, true)
		"50_moves":
			Dialog.push_dialog("HINT_DRAW", "CHAR_CARNATION", true, true)
		"cleared_black":
			Dialog.push_dialog("HINT_BLACK_CLEARED", "CHAR_CARNATION", true, true)
		"cleared_white":
			Dialog.push_dialog("HINT_WHITE_CLEARED", "CHAR_CARNATION", true, true)

func position_practice(_result:String = "") -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision_side.procedure_end, position_practice_decision_end)
	$procedure_decision_side.start()

func position_practice_decision_end(_result:String) -> void:
	signal_container.disconnect_all()
	match _result:
		"":
			interact_carnation_end()
			return
		"CARNATION_TALK_DEMO_HOW_TO_PLAY":
			signal_container.add_connection($procedure_dialog_positioning_help.procedure_end, position_practice)
			$procedure_dialog_positioning_help.start()
			return
		"SELECTION_PLAY_AS_WHITE":
			standard_player_group = 0
		"SELECTION_PLAY_AS_BLACK":
			standard_player_group = 1
		"SELECTION_PLAY_AS_RANDOM":
			standard_player_group = randi() % 2
	if standard_player_group == 0:
		standard_chessboard.rotation.y = -PI / 2
	else:
		standard_chessboard.rotation.y = PI / 2
	position_practice_start()

var question:int = -1
var score:int = 0
func position_practice_start() -> void:
	standard_chessboard.set_enabled(true)
	$chessboard.set_enabled(false)
	$event_actor_carnation.instance.get_node("animation_tree").active = true
	$event_actor_carnation.instance.play_animation("sit_and_think")
	Player.force_set_camera($camera_chessboard)
	signal_container.add_connection(standard_chessboard.click_empty, func (_selected:int) -> void:
		if _selected == question:
			question = Chess.c64_to_x88(randi() % 64)
			score += 1
			Dialog.push_title(tr("CARNATION_TALK_DEMO_POSITIONING_FORMAT").format({"pos": Chess.x88_to_name(question), "score": score}))
	)
	Clock.set_time(60, 0)
	signal_container.add_connection(Clock.timeout, position_practice_end)
	Clock.resume()
	question = Chess.c64_to_x88(randi() % 64)
	Dialog.push_title(tr("CARNATION_TALK_DEMO_POSITIONING_FORMAT").format({"pos": Chess.x88_to_name(question), "score": score}))

func position_practice_end() -> void:
	signal_container.disconnect_all()
	signal_container.add_connection(Dialog.on_next, interact_carnation_end)
	Dialog.push_dialog(tr("CARNATION_TALK_DEMO_POSITIONING_RESULT").format({"score": score}), "CHAR_CARNATION", true, true, false)

func memory_practice(_result:String = "") -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision_difficulty.procedure_end, memory_practice_decision_end)
	$procedure_decision_difficulty.start()

var memory_state:State = null
var memory_answer:String = ""

func memory_practice_decision_end(_result:String) -> void:
	signal_container.disconnect_all()
	Player.force_set_camera($camera_chessboard)
	match _result:
		"CARNATION_TALK_DEMO_MEMORIZING_EASY":
			memory_state = Chess.create_random_state(3)
		"CARNATION_TALK_DEMO_MEMORIZING_MEDIUM":
			memory_state = Chess.create_random_state(6)
		"CARNATION_TALK_DEMO_MEMORIZING_HARD":
			memory_state = Chess.create_random_state(10)
		"CARNATION_TALK_DEMO_HOW_TO_PLAY":
			signal_container.add_connection($procedure_dialog_memorize_help.procedure_end, memory_practice)
			$procedure_dialog_memorize_help.start()
			return
	
	standard_chessboard.set_enabled(true)
	$chessboard.set_enabled(false)
	$event_actor_carnation.instance.get_node("animation_tree").active = true
	$event_actor_carnation.instance.play_animation("sit_and_think")
	standard_chessboard.remove_piece_set()
	standard_chessboard.set_state(memory_state)
	standard_chessboard.add_default_piece_set()
	memory_answer = Chess.stringify(memory_state)
	memory_answer = memory_answer.split(" ")[0]
	signal_container.add_connection($procedure_decision_memory.procedure_end, memory_practice_recite)
	$procedure_decision_memory.start()

func memory_practice_recite(_selection:String) -> void:
	signal_container.disconnect_all()
	standard_chessboard.remove_piece_set()
	standard_chessboard.set_state(State.new())
	signal_container.add_connection($procedure_edit_memory.procedure_end, memory_practice_result)
	$procedure_edit_memory.start()

func memory_practice_result(_result:String) -> void:
	signal_container.disconnect_all()
	standard_chessboard.remove_piece_set()
	standard_chessboard.set_state(memory_state)
	standard_chessboard.add_default_piece_set()
	signal_container.add_connection(Dialog.on_next, interact_carnation_end)
	if _result.split(" ")[0] == memory_answer:
		Dialog.push_dialog(tr("CARNATION_TALK_DEMO_MEMORIZING_CORRECT"), "CHAR_CARNATION", true, true, false)
	else:
		Dialog.push_dialog(tr("CARNATION_TALK_DEMO_MEMORIZING_INCORRECT"), "CHAR_CARNATION", true, true, false)

func interact_carnation_end() -> void:
	signal_container.disconnect_all()
	Player.force_set_camera($camera)
	$event_explore.instance.get_node("animation_tree").active = true
	$event_actor_carnation.instance.get_node("animation_tree").active = true
	$event_explore.instance.play_animation("battle_idle")
	$event_explore.instance.set_position($chessboard.name_to_vector3("d6"))
	$chessboard.set_enabled(true)
	standard_chessboard.set_enabled(false)
	change_state("")
