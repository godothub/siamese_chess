extends Control

@onready var tts_input:TextEdit = $margin_container/v_box_container/margin_container_tts/h_box_container/text_edit
@onready var tts_submit:Button = $margin_container/v_box_container/margin_container_tts/h_box_container/button
@onready var tts_request:HTTPRequest = $margin_container/v_box_container/margin_container_tts/h_box_container/http_request
@onready var tts_result:AudioStreamPlayer = $margin_container/v_box_container/margin_container_tts/h_box_container/audio_stream_player
@onready var asr_input:AudioStreamPlayer = $margin_container/v_box_container/margin_container_asr/h_box_container/audio_stream_player
@onready var asr_submit:Button = $margin_container/v_box_container/margin_container_asr/h_box_container/button
@onready var asr_request:HTTPRequest = $margin_container/v_box_container/margin_container_asr/h_box_container/http_request
@onready var asr_result:Label = $margin_container/v_box_container/margin_container_asr/h_box_container/label
var asr_record_effect:AudioEffectRecord = null

func _ready() -> void:
	tts_submit.connect("pressed", send_tts)
	tts_request.set_tls_options(TLSOptions.client())
	tts_request.connect("request_completed", receive_tts)
	asr_submit.connect("pressed", record_asr)
	asr_request.connect("request_completed", receive_asr)
	var record_idx = AudioServer.get_bus_index("Record")
	asr_record_effect = AudioServer.get_bus_effect(record_idx, 0)

func send_tts() -> void:
	tts_request.request("https://api.famulan.uk:5000/tts?voice=default", ["Content-Type: text/plain"], HTTPClient.METHOD_POST, tts_input.text)

func receive_tts(_result:int, _response_code:int, _headers:PackedStringArray, body:PackedByteArray) -> void:
	var audio_stream:AudioStreamMP3 = AudioStreamMP3.load_from_buffer(body)
	if !audio_stream:
		printerr("invalid response")
	tts_result.stream = audio_stream
	tts_result.play()

func record_asr() -> void:
	if !asr_record_effect.is_recording_active():
		asr_record_effect.set_recording_active(true)
		asr_submit.text = "speaking"
	else:
		asr_submit.text = "speak"
		var recording:PackedByteArray = asr_record_effect.get_recording().data
		asr_record_effect.set_recording_active(false)
		asr_request.request_raw("https://api.famulan.uk:5000/asr", ["Content-Type: audio/wav"], HTTPClient.METHOD_POST, recording)

func receive_asr(_result:int, _response_code:int, _headers:PackedStringArray, body:PackedByteArray) -> void:
	asr_result.text = body.get_string_from_utf8()
