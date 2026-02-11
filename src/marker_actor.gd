@tool
extends Marker3D
class_name MarkerActor

@export var piece:int = 0
@export var actor:PackedScene = null
@export var meta:Dictionary = {}

func _ready() -> void:
	if Engine.is_editor_hint():
		var new_instance:Actor = instantiate()
		if new_instance:
			add_child(new_instance)

func instantiate() -> Actor:
	if !is_instance_valid(actor):
		return null
	var new_instance:Actor = actor.instantiate()
	for iter:Variant in meta:
		new_instance.set_meta(iter, meta[iter])
	return new_instance
