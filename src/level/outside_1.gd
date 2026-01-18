extends "res://src/level/outside.gd"


func _ready() -> void:
	super._ready()
	interact_list[0x12] = {"CARNATION_TALK": interact_with_carnation}
	title[0x12] = "CHAR_CARNATION"
	interact_list[0x13] = {"CARNATION_TALK": interact_with_carnation}
	title[0x13] = "CHAR_CARNATION"
	interact_list[0x23] = {"CARNATION_TALK": interact_with_carnation}
	title[0x23] = "CHAR_CARNATION"
	interact_list[0x33] = {"CARNATION_TALK": interact_with_carnation}
	title[0x33] = "CHAR_CARNATION"
	interact_list[0x32] = {"CARNATION_TALK": interact_with_carnation}
	title[0x32] = "CHAR_CARNATION"

func interact_with_carnation() -> void:
	$player.force_set_camera($camera_carnation)
	match randi() % 2:
		0:
			Dialog.push_dialog("CARNATION_TALK_0_0", "", true, true)
			await Dialog.on_next
			Dialog.push_dialog("CARNATION_TALK_0_1", "", true, true)
			$player.force_set_camera($camera_carnation_2)
			await Dialog.on_next
		1:
			Dialog.push_dialog("CARNATION_TALK_1_0", "", true, true)
			await Dialog.on_next
			Dialog.push_dialog("CARNATION_TALK_1_1", "", true, true)
			await Dialog.on_next
	$player.force_set_camera($camera)
	change_state.call_deferred("explore_idle")
