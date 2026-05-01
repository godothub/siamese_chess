@tool
extends MarkerEvent
class_name MarkerActor

@export var piece:int = 0
@export var actor:PackedScene = null: set = set_actor, get = get_actor
@export var meta:Dictionary = {}
var editor_instance:Actor = null

func on_init() -> void:
	var by:int = level.chessboard.vector3_to_x88(position)
	level.chessboard.state.add_piece(by, piece)
	var instance:Actor = instantiate()
	instance.transform = transform
	if is_instance_valid(instance):
		level.chessboard.add_piece_instance(instance, by)

func _ready() -> void:
	if Engine.is_editor_hint():
		var new_instance:Actor = instantiate()
		if new_instance:
			editor_instance = new_instance
			for key:Variant in meta:
				new_instance.set_meta(key, meta[key])
			add_child(new_instance)

func instantiate() -> Actor:
	if !is_instance_valid(actor):
		return null
	var new_instance:Actor = actor.instantiate()
	for iter:Variant in meta:
		new_instance.set_meta(iter, meta[iter])
	return new_instance

func set_actor(_actor:PackedScene) -> void:
	actor = _actor
	if Engine.is_editor_hint():
		if editor_instance:
			editor_instance.queue_free()
		var new_instance:Actor = instantiate()
		if new_instance:
			editor_instance = new_instance
			for key:Variant in meta:
				new_instance.set_meta(key, meta[key])
			add_child(new_instance)

func set_actor_meta(_meta:Dictionary) -> void:
	meta = _meta
	if Engine.is_editor_hint():
		if editor_instance:
			for key:Variant in meta:
				editor_instance.set_meta(key, meta[key])

func get_actor() -> PackedScene:
	return actor
