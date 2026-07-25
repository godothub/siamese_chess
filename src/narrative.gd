extends Node

class LanguageVoiceList:
	var system_name:PackedStringArray = []
	var system_key:PackedStringArray = []
	var online_name:PackedStringArray = []
	var online_key:PackedStringArray = []
	var ready:bool = false

var language_voice_list:Dictionary[String, LanguageVoiceList] = {}
var request_tts:HTTPRequest = HTTPRequest.new()
var audio_stream_player_tts:AudioStreamPlayer = AudioStreamPlayer.new()
var mutex:Mutex = Mutex.new()
var content_queue:Array = []

func _ready() -> void:
	add_child(request_tts)
	add_child(audio_stream_player_tts)
	update_voice_list()
	request_tts.connect("request_completed", tts_request_result)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, tts_utterance_end)

func update_voice_list() -> void:
	mutex.lock()
	for lang:String in Setting.languages.keys():
		language_voice_list[lang] = LanguageVoiceList.new()
		language_voice_list[lang].system_name = DisplayServer.tts_get_voices_for_language(lang)
		language_voice_list[lang].system_key = DisplayServer.tts_get_voices_for_language(lang)
		var espeak_lang:String = "en" if lang == "en" else "zh"
		Network.get_request("/voice_list", {"lang": espeak_lang}, voice_list_request_result.bind(lang))
	mutex.unlock()

func voice_list_request_result(_body:PackedByteArray, lang:String) -> void:
	var result = _body.get_string_from_utf8()
	var result_splited = result.split(",")
	language_voice_list[lang].online_name.clear()
	language_voice_list[lang].online_key.clear()
	for i:int in range(0, result_splited.size(), 2):
		language_voice_list[lang].online_name.push_back(result_splited[i])
	for i:int in range(1, result_splited.size(), 2):
		language_voice_list[lang].online_key.push_back(result_splited[i])
	language_voice_list[lang].ready = true

func get_voice_list() -> PackedStringArray:
	match Setting.get_value("text_to_speech_type"):
		0:
			return language_voice_list[TranslationServer.get_locale()].system_name
		1:
			if language_voice_list[TranslationServer.get_locale()].ready:
				return language_voice_list[TranslationServer.get_locale()].online_name
			return ["-"]
		2:
			return ["-"]	# 剪贴板不用自行选声音
	return []

func set_voice(index:int) -> void:
	match Setting.get_value("text_to_speech_type"):
		0:
			if index < language_voice_list[TranslationServer.get_locale()].system_key.size():
				Setting.set_value("voice", language_voice_list[TranslationServer.get_locale()].system_key[index])
		1:
			if index < language_voice_list[TranslationServer.get_locale()].online_key.size():
				Setting.set_value("voice", language_voice_list[TranslationServer.get_locale()].online_key[index])

func speak(content:String, interrupted:bool = false) -> void:
	if interrupted:
		if Setting.get_value("text_to_speech_type") == 0:
			DisplayServer.tts_stop()
		if Setting.get_value("text_to_speech_type") == 1:
			request_tts.cancel_request()
			audio_stream_player_tts.stop()
		content_queue.clear()
	content_queue.push_back(content)
	if content_queue.size() == 1:
		next_content()

func next_content() -> void:
	if content_queue.is_empty():
		return
	var content:String = content_queue.front()
	if Setting.get_value("text_to_speech"):
		if Setting.get_value("text_to_speech_type") == 0:
			if Setting.get_value("voice"):
				DisplayServer.tts_speak(content, Setting.get_value("voice"), Setting.get_value("text_to_speech_volume"), Setting.get_value("text_to_speech_pitch") / 100.0, Setting.get_value("text_to_speech_speed") / 100.0, 0)
		elif Setting.get_value("text_to_speech_type") == 1:
			if Setting.get_value("voice"):
				tts_request(content)
		else:
			DisplayServer.clipboard_set(content)
			content_queue.pop_front()
	print(content)

func tts_request(content:String) -> void:
	# 说到底谁设计的API，query_string_from_dict本应该是静态函数的但结果不是
	Network.post_request("/tts", {
			"voice": Setting.get_value("voice"),
			"speed": int(round(Setting.get_value("text_to_speech_speed") / 200.0 * (450 - 80) + 80)),
			"pitch": int(round(Setting.get_value("text_to_speech_pitch") / 200.0 * 99.0))
		},
		"text/plain",
		content.to_utf8_buffer(),
		tts_request_result
	)

func tts_utterance_end(_char_index:int, _utteracne_id:int) -> void:
	content_queue.pop_front()
	next_content()

func tts_request_result(_body:PackedByteArray) -> void:
	content_queue.pop_front()
	var audio_stream:AudioStreamMP3 = AudioStreamMP3.load_from_buffer(_body)
	if !audio_stream:
		return
	audio_stream_player_tts.stream = audio_stream
	audio_stream_player_tts.volume_linear = Setting.get_value("text_to_speech_volume") / 100.0
	audio_stream_player_tts.play()
	next_content()

func stop() -> void:
	DisplayServer.tts_stop()
