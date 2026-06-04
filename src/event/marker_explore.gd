extends MarkerEvent
class_name MarkerExplore

var player_group:int = 1
var player_all:int = 0
var player_king:int = 0
var enemy_all:int = 0
var enemy_king:int = 0

@export var chessboard:Chessboard = null
var state_machine:StateMachine = StateMachine.new()

var travel_path:PackedInt32Array = []

func _ready() -> void:
	player_all = ord("A") if player_group == 0 else ord("a")
	player_king = ord("K") if player_group == 0 else ord("k")
	enemy_all = ord("a") if player_group == 0 else ord("A")
	enemy_king = ord("k") if player_group == 0 else ord("K")
	state_machine.name = "explore"
	state_machine.add_state("free", state_ready_free, state_exit_free)
	state_machine.add_state("travel", state_ready_travel)
	state_machine.add_state("stop", state_ready_stop)

func on_start() -> void:
	super.on_start()
	state_machine.change_state("free")

func on_change_state(state:String) -> void:
	if state != "":
		state_machine.change_state("stop")
	else:
		state_machine.change_state("free")

func state_ready_free(_arg:Dictionary) -> void:
	Clock.pause()
	state_machine.state_signal_connect(chessboard.click_empty, travel_to)
	state_machine.state_signal_connect(Dialog.on_select, func(_selected:String) -> void:
		level.available_events[_selected].on_selection.call_deferred()
		level.show_selection.call_deferred()
	)
	state_machine.state_signal_connect(chessboard.hovered, func (_selected:int) -> void:
		if level.title.has(_selected):
			Dialog.push_title(level.title[_selected])
		else:
			Dialog.push_title("")
	)
	level.show_selection()
	level.sync_to_global()

func state_exit_free() -> void:
	Dialog.clear()

func state_ready_travel(_arg:Dictionary) -> void:
	if travel_path.size():
		chessboard.execute_move(travel_path[-1])
		travel_path.resize(travel_path.size() - 1)
	state_machine.state_signal_connect(chessboard.click_empty, travel_to)
	state_machine.state_signal_connect(chessboard.animation_finished, func () -> void:
		if travel_path.size():
			state_machine.change_state.call_deferred("travel")
		else:
			state_machine.change_state.call_deferred("free")
	)

func travel_to(_by:int) -> void:
	var from:int = Chess.c64_to_x88(Chess.first_bit(chessboard.state.get_bit(player_king)))
	var path:PackedInt32Array = Chess.generate_path(chessboard.state, from)
	var path_to:PackedInt32Array = []
	var iter:int = _by
	while iter != from:
		if path[Chess.x88_to_c64(iter)] == -1:
			return
		path_to.push_back(Chess.create(path[Chess.x88_to_c64(iter)], iter, 0))
		iter = path[Chess.x88_to_c64(iter)]
	if !path_to.size():
		return
	Narrative.speak(tr("TRAVEL_TO").format({"by": Localization.position_name_to_pronounce(Chess.x88_to_name(_by))}), false)
	travel_path = path_to
	state_machine.change_state("travel")

func state_ready_stop(_arg:Dictionary) -> void:
	pass
