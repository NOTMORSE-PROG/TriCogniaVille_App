class_name SpeechRecognizer
extends Node
## SpeechRecognizer — Records audio via native Android plugin, transcribes
## via backend Groq Whisper API.
##
## Public API is unchanged from the original on-device STT version so all
## interaction consumers (FluencyInteraction, ReadAloudInteraction,
## PunctuationReadInteraction) work without modification.
##
## On desktop/editor: all methods are safe no-ops; recognition_unavailable is emitted.

signal transcript_ready(text: String, confidence: float)
signal recognition_error(reason: String)
signal recognition_unavailable
signal listening_started
signal listening_ended

var max_listen_seconds: float = 30.0

var _plugin = null
var _alternatives: Array = []
var _audio_base64 := ""
var _audio_url := ""
var _language := "en-US"
var _timeout_timer: Timer = null
var _is_recording := false


func _ready() -> void:
	if Engine.has_singleton("SpeechPlugin"):
		_plugin = Engine.get_singleton("SpeechPlugin")
		_plugin.connect("recording_completed", _on_recording_completed)
		if _plugin.has_signal("recording_error"):
			_plugin.connect("recording_error", _on_recording_error)
		if _plugin.has_signal("listening_started"):
			_plugin.connect("listening_started", func() -> void: listening_started.emit())
		if _plugin.has_signal("listening_ended"):
			_plugin.connect("listening_ended", func() -> void: listening_ended.emit())
	else:
		push_warning("[SpeechRecognizer] SpeechPlugin singleton not found — speech unavailable.")


## Returns true if the native Android audio recording is available.
func is_available() -> bool:
	if _plugin == null:
		return false
	return _plugin.isAvailable()


## Ask the OS for RECORD_AUDIO permission without starting a recording.
## Safe to call multiple times — no-op if already granted or plugin unavailable.
func request_permission() -> void:
	if _plugin != null:
		_plugin.requestPermission()


## Start listening for speech.
## language: BCP-47 locale tag, e.g. "en-US"
func start_recognition(language: String = "en-US") -> void:
	if _plugin == null:
		recognition_unavailable.emit()
		return

	if not is_available():
		recognition_unavailable.emit()
		return

	_alternatives.clear()
	_audio_base64 = ""
	_audio_url = ""
	_language = language
	_is_recording = true
	_plugin.startRecording(language)
	TTSManager.stop()
	AudioManager.set_sfx_muted(true)

	# Safety: auto-stop after max_listen_seconds
	_cleanup_timer()
	_timeout_timer = Timer.new()
	add_child(_timeout_timer)
	_timeout_timer.wait_time = max_listen_seconds
	_timeout_timer.one_shot = true
	_timeout_timer.timeout.connect(_on_safety_timeout)
	_timeout_timer.start()

	listening_started.emit()


## Stop recognition early (e.g. user taps Stop button).
func stop_recognition() -> void:
	_cleanup_timer()
	_is_recording = false
	if _plugin != null:
		_plugin.stopRecording()  # plugin emits listening_ended via connected signal
	else:
		listening_ended.emit()  # desktop/editor fallback — no plugin to emit it


## Get the last recorded audio as base64 string (fallback).
func get_audio_base64() -> String:
	if _plugin != null and _audio_base64.is_empty():
		_audio_base64 = _plugin.getAudioBase64()
	return _audio_base64


## Get the Cloudinary URL of the uploaded audio (returned by /speech/transcribe).
func get_audio_url() -> String:
	return _audio_url


## Get all STT alternative transcriptions from the last recognition.
func get_alternatives() -> Array:
	return _alternatives


func _exit_tree() -> void:
	if _is_recording:
		AudioManager.set_sfx_muted(false)


## ── Private ────────────────────────────────────────────────────────────────


func _cleanup_timer() -> void:
	if is_instance_valid(_timeout_timer):
		_timeout_timer.stop()
		_timeout_timer.queue_free()
		_timeout_timer = null


## Called by plugin when audio recording is done — send to backend for transcription.
func _on_recording_completed(audio_b64: String) -> void:
	AudioManager.set_sfx_muted(false)
	_cleanup_timer()
	_is_recording = false
	_audio_base64 = audio_b64

	if audio_b64.is_empty():
		recognition_error.emit("No audio recorded. Please try again.")
		return

	# Send audio to backend for Whisper transcription
	ApiClient.transcribe_audio(audio_b64, _language, _on_transcribe_response)


func _on_recording_error(reason: String) -> void:
	AudioManager.set_sfx_muted(false)
	_cleanup_timer()
	_is_recording = false
	recognition_error.emit(reason)


func _on_transcribe_response(success: bool, data: Dictionary) -> void:
	if not success:
		recognition_error.emit("Could not transcribe. Check your connection and try again.")
		return

	var transcript: String = data.get("transcript", "")
	var confidence: float = data.get("confidence", 0.0)
	_audio_url = data.get("audioUrl", "")

	var alts = data.get("alternatives", [])
	if alts is Array:
		_alternatives = alts
	else:
		_alternatives = [transcript] if not transcript.is_empty() else []

	if transcript.strip_edges().is_empty():
		recognition_error.emit("No speech detected. Please speak clearly and try again.")
		return

	transcript_ready.emit(transcript, confidence)


func _on_safety_timeout() -> void:
	_cleanup_timer()
	if _is_recording:
		_is_recording = false
		if _plugin != null:
			_plugin.stopRecording()
		# stopRecording will trigger recording_completed which will call the backend.
		# But if for some reason it doesn't, emit an error after a brief delay.
		await get_tree().create_timer(2.0).timeout
		if _audio_url.is_empty() and _audio_base64.is_empty():
			# listening_ended already emitted by plugin signal above — only emit the error
			recognition_error.emit("No response from speech engine. Please try again.")
