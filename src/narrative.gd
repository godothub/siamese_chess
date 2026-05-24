extends Node

func speak(content:String, interrupted:bool = false) -> void:
	DisplayServer.tts_speak(content, Setting.get_value("voice"), 50, 1, 1, 0, interrupted)
