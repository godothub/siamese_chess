@tool
extends LevelEvent
class_name EventActor

@export var piece:int = 0
@export var meta:Dictionary = {}
@export var instance:Actor = null
@export var enabled:bool = true

func on_start() -> void:
	if !enabled:
		return
	var by:int = Progress.get_value(level.name + ":" + level.chessboard.vector3_to_name(position), level.chessboard.vector3_to_x88(position))
	if by == -1:
		return
	if piece == 0:
		return
	level.chessboard.state.add_piece(by, piece)
	
	if instance:
		for iter:Variant in meta:
			instance.change_meta(iter, meta[iter])
		level.chessboard.add_piece_instance(instance, by)

func _ready() -> void:
	pass

func set_actor_meta(_meta:Dictionary) -> void:
	meta = _meta

func on_exit() -> void:
	if instance:
		var by:int = level.chessboard.get_piece_instance_x88(instance)
		Progress.set_value(level.name + ":" + level.chessboard.vector3_to_name(position), by)
