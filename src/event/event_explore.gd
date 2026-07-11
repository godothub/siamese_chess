extends LevelEvent
class_name EventExplore

signal move_executed(move:int)
signal animation_finished()

@export var chessboard:Chessboard = null
@export var instance:Actor = null
var state_machine:StateMachine = StateMachine.new()
var cheshire_by:int = -1
var dont_move:bool = false

var travel_path:PackedInt32Array = []

func _ready() -> void:
	cheshire_by = Progress.get_value("player_by", chessboard.vector3_to_x88(position))
	Progress.connect("value_changed", receive_value_change)
	instance.global_position = chessboard.x88_to_vector3(cheshire_by)
	chessboard.button_input_pointer = cheshire_by
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
	dont_move = false
	state_machine.state_signal_connect(chessboard.click_empty, travel_to)
	state_machine.state_signal_connect(Dialog.on_select, func(_selected:String) -> void:
		if level.available_events.has(_selected):
			level.available_events[_selected].on_selection()
		level.show_selection()
	)
	state_machine.state_signal_connect(chessboard.hovered, func (_selected:int) -> void:
		if level.title.has(_selected):
			Dialog.push_title(level.title[_selected])
		else:
			Dialog.push_title("")
	)
	level.show_selection()
	sync_to_global()

func state_exit_free() -> void:
	#Dialog.clear()
	pass

func state_ready_travel(_arg:Dictionary) -> void:
	if travel_path.size():
		instance.move(chessboard.x88_to_vector3(travel_path[-1]))
		cheshire_by = travel_path[-1]
		travel_path.resize(travel_path.size() - 1)
	state_machine.state_signal_connect(chessboard.click_empty, travel_to)
	state_machine.state_signal_connect(chessboard.hovered, func (_selected:int) -> void:
		if level.title.has(_selected):
			Dialog.push_title(level.title[_selected])
		else:
			Dialog.push_title("")
	)
	state_machine.state_signal_connect(instance.animation_finished, func () -> void:
		if travel_path.size():
			state_machine.change_state.call_deferred("travel")
		else:
			animation_finished.emit()
			if dont_move:
				state_machine.change_state.call_deferred("stop")
			else:
				state_machine.change_state.call_deferred("free")
	)

func travel_to(_by:int, no_signal:bool = false) -> void:
	var path:PackedInt32Array = Chess.generate_path(chessboard.state, cheshire_by)
	var path_to:PackedInt32Array = []
	var iter:int = _by
	while iter != cheshire_by:
		if path[Chess.x88_to_c64(iter)] == -1:
			return
		path_to.push_back(iter)
		iter = path[Chess.x88_to_c64(iter)]
	if !path_to.size():
		return
	Narrative.speak(tr("TRAVEL_TO").format({"by": Localization.position_name_to_pronounce(Chess.x88_to_name(_by))}), false)
	travel_path = path_to
	Progress.set_value("player_by", _by, true)
	if !no_signal:
		move_executed.emit(Chess.create(cheshire_by, _by, 0))
	state_machine.change_state("travel")

func state_ready_stop(_arg:Dictionary) -> void:
	dont_move = true

func sync_to_global() -> void:
	ThirdEye3D.set_state(chessboard.state)
	var cheshire_position:Vector3 = instance.global_position
	cheshire_position += Vector3(0, 1.6, 0)
	var cheshire_rotation:Vector3 = instance.global_rotation
	FilmCamera.move_camera(cheshire_position, cheshire_rotation)

func receive_value_change(key:String, value:Variant) -> void:
	if key == "player_by":
		travel_to(value, false)
