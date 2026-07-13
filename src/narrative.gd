extends Node

func speak(content:String, interrupted:bool = false) -> void:
	if Setting.get_value("text_to_speech"):
		DisplayServer.tts_speak(content, Setting.get_value("voice"), Setting.get_value("text_to_speech_volume"), Setting.get_value("text_to_speech_pitch") / 100.0, Setting.get_value("text_to_speech_speed") / 100.0, 0, interrupted)
	print(content)

func stop() -> void:
	DisplayServer.tts_stop()
