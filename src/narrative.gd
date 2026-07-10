extends Node

func speak(content:String, interrupted:bool = false) -> void:
	assert(content != "")
	if Setting.get_value("text_to_speech"):
		DisplayServer.tts_speak(content, Setting.get_value("voice"), 50, 1, 1, 0, interrupted)
	print(content)

func stop() -> void:
	DisplayServer.tts_stop()
