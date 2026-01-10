extends CanvasLayer

signal selected()

var card_list:Array[Card] = []
var selected_card:Card = null

func _ready() -> void:
	init_card()
	hide_card()
	var i:int = 0
	for iter:Card in card_list:
		var card_instance:TextureRect = TextureRect.new()
		card_instance.texture = iter.cover
		card_instance.set_meta("card", iter)
		card_instance.mouse_filter = Control.MOUSE_FILTER_STOP
		$card_list.add_child(card_instance)
		card_instance.connect("gui_input", card_input.bind(card_instance))
		card_instance.position.y = -400
		card_instance.position.x = i * 200
		i += 1

func add_card(card:Card) -> void:
	var card_instance:TextureRect = TextureRect.new()
	card_instance.position.y = -400
	card_instance.position.x = card_list.size() * 200
	card_instance.texture = card.cover
	card_instance.mouse_filter = Control.MOUSE_FILTER_STOP
	card_instance.set_meta("card", card)
	$card_list.add_child(card_instance)
	card_instance.connect("gui_input", card_input.bind(card_instance))
	card_list.push_back(card)

func init_card() -> void:
	var card_1:CardTarot = CardTarot.new()
	card_1.cover = load("res://assets/texture/piece_pawn.svg")
	card_1.piece = ord("p")
	card_1.actor = load("res://scene/actor/piece_pawn_black.tscn").instantiate().set_larger_scale()
	card_list.push_back(card_1)
	var card_2:CardTarot = CardTarot.new()
	card_2.cover = load("res://assets/texture/piece_queen.svg")
	card_2.piece = ord("q")
	card_2.actor = load("res://scene/actor/piece_queen_black.tscn").instantiate().set_larger_scale()
	card_list.push_back(card_2)

func reset() -> void:
	for iter:Card in card_list:
		iter.reset()

func card_input(_event:InputEvent, card_instance:TextureRect) -> void:
	if _event is InputEventMouseButton:
		if !_event.pressed && _event.button_index == MOUSE_BUTTON_LEFT:
			select_card(card_instance)

# 这里需要切实地让player感知到自己选了这张牌
func select_card(card_instance:TextureRect) -> void:
	selected_card = card_instance.get_meta("card")
	selected.emit()

func show_card() -> void:
	visible = true
	for iter:TextureRect in $card_list.get_children():
		iter.get_meta("card").show_up(iter)

func hide_card() -> void:
	visible = false
