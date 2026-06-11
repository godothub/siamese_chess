extends Node3D
class_name Level

var player_group:int = 1
var player_all:int = 0
var player_king:int = 0
var enemy_all:int = 0
var enemy_king:int = 0

@onready var chessboard:Chessboard = $chessboard
var teleport:Dictionary = {}
var events:Array = []
var title:Dictionary[int, String] = {}

func _ready() -> void:
	player_all = ord("A") if player_group == 0 else ord("a")
	player_king = ord("K") if player_group == 0 else ord("k")
	enemy_all = ord("a") if player_group == 0 else ord("A")
	enemy_king = ord("k") if player_group == 0 else ord("K")

	var state:State = State.new()
	chessboard.set_state(state)
	Player.add_inspectable_item(chessboard)
	for node:Node in get_children():
		if node is MarkerEvent:
			events.push_back(node)
			node.on_init()
	Progress.create_if_not_exist("obtains", 0)
	Progress.create_if_not_exist("wins", 0)
	event_start.call_deferred()

func change_state(state:String) -> void:
	for event:MarkerEvent in events:
		event.on_change_state(state)

func event_start() -> void:
	for iter:MarkerEvent in events:
		iter.on_start()

func sync_to_global() -> void:
	ThirdEye3D.set_state(chessboard.state)
	var king_by:int = Chess.c64_to_x88(Chess.first_bit(chessboard.state.get_bit(player_king)))
	var king_position:Vector3 = chessboard.chessboard_piece[king_by].global_position
	king_position += Vector3(0, 1.6, 0)
	var king_rotation:Vector3 = chessboard.chessboard_piece[king_by].global_rotation
	FilmCamera.move_camera(king_position, king_rotation)

var available_events:Dictionary = {}

func show_selection() -> void:
	var by:int = Chess.c64_to_x88(Chess.first_bit(chessboard.state.get_bit(player_king)))
	var selections:PackedStringArray = []
	available_events.clear()
	for iter:MarkerEvent in events:
		var selection:String = iter.show_selection()
		if selection != "":
			available_events[selection] = iter
			selections.push_back(selection)
	selections.erase("")
	Dialog.push_selection(selections, title.get(by, ""), false, false)
