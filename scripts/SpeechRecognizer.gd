class_name SpeechRecognizer
extends Node
## SpeechRecognizer — Android native speech recognition via Kotlin plugin.
## Uses MediaRecorder (saves audio) + Android SpeechRecognizer (transcribes)
## running simultaneously on Android 10+ (shared mic).
##
## On desktop/editor: all methods are safe no-ops; recognition_unavailable is emitted.
## Fallback path in ReadAloudInteraction handles this gracefully.

signal transcript_ready(text: String, confidence: float)
signal recognition_error(reason: String)
signal recognition_unavailable
signal listening_started
signal listening_ended

const MAX_LISTEN_SECONDS := 30.0

var _plugin = null
var _alternatives: Array = []
var _audio_base64 := ""
var _timeout_timer: Timer = null


func _ready() -> void:
	if Engine.has_singleton("SpeechPlugin"):
		_plugin = Engine.get_singleton("SpeechPlugin")
		_plugin.connect("transcript_ready", _on_plugin_transcript)
		_plugin.connect("recognition_error", _on_plugin_error)
		_plugin.connect("recording_completed", _on_recording_completed)
		if _plugin.has_signal("recognition_unavailable"):
			_plugin.connect(
				"recognition_unavailable", func() -> void: recognition_unavailable.emit()
			)
		if _plugin.has_signal("listening_ended"):
			_plugin.connect("listening_ended", func() -> void: listening_ended.emit())
	else:
		push_warning("[SpeechRecognizer] SpeechPlugin singleton not found — speech unavailable.")


## Returns true if the native Android speech recognition is available.
func is_available() -> bool:
	if _plugin == null:
		return false
	return _plugin.isAvailable()


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
	_plugin.startRecording(language)

	# Safety: auto-stop after MAX_LISTEN_SECONDS
	_cleanup_timer()
	_timeout_timer = Timer.new()
	add_child(_timeout_timer)
	_timeout_timer.wait_time = MAX_LISTEN_SECONDS
	_timeout_timer.one_shot = true
	_timeout_timer.timeout.connect(stop_recognition)
	_timeout_timer.start()

	listening_started.emit()


## Stop recognition early (e.g. user taps Stop button).
func stop_recognition() -> void:
	_cleanup_timer()
	if _plugin != null:
		_plugin.stopRecording()
	listening_ended.emit()


## Get the last recorded audio as base64 string (for Cloudinary upload).
func get_audio_base64() -> String:
	if _plugin != null and _audio_base64.is_empty():
		_audio_base64 = _plugin.getAudioBase64()
	return _audio_base64


## Get all STT alternative transcriptions from the last recognition.
func get_alternatives() -> Array:
	return _alternatives


## ── Private ────────────────────────────────────────────────────────────────


func _cleanup_timer() -> void:
	if is_instance_valid(_timeout_timer):
		_timeout_timer.stop()
		_timeout_timer.queue_free()
		_timeout_timer = null


## Called by plugin when transcript is ready.
## text: best transcription, confidence: 0.0-1.0, alternatives_json: JSON array string
func _on_plugin_transcript(text: String, confidence: float, alternatives_json: String = "") -> void:
	_cleanup_timer()
	if not alternatives_json.is_empty():
		var parsed = JSON.parse_string(alternatives_json)
		if parsed is Array:
			_alternatives = parsed
		else:
			_alternatives = [text]
	else:
		_alternatives = [text]

	if text.strip_edges().is_empty():
		recognition_error.emit("No speech detected. Please speak clearly and try again.")
		return

	transcript_ready.emit(text, confidence)


func _on_plugin_error(reason: String) -> void:
	_cleanup_timer()
	recognition_error.emit(reason)


func _on_recording_completed(audio_b64: String) -> void:
	_audio_base64 = audio_b64
