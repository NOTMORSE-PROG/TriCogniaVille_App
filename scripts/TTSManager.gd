extends Node
## TTSManager — AutoLoad singleton for Text-to-Speech.
## Wraps Godot 4's built-in DisplayServer TTS. Gracefully degrades on platforms
## where TTS is unavailable (e.g. some Android builds without a TTS engine).
##
## Primary use-cases:
##   • Auto-read instructions for Non-Reader students (reading_level == 1)
##   • "Hear it" pronunciation buttons on words/passages students must read aloud

var _voice_id: String = ""
var _available: bool = false


func _ready() -> void:
	if not DisplayServer.has_method("tts_get_voices"):
		push_warning("[TTSManager] DisplayServer TTS not supported on this platform.")
		return
	# tts_get_voices_for_language() returns PackedStringArray of voice ID strings.
	# tts_get_voices() returns Array[Dictionary] with "name" and "id" keys.
	# Prefer en-US; fall back to any English voice, then any available voice.
	# On Android, voice enumeration often returns empty even when TTS is functional
	# (the system selects a default voice when the voice ID is ""). We mark
	# _available = true whenever the TTS API exists and fall back to an empty
	# voice ID so Android's TTS engine picks its own default.
	var us_voices: PackedStringArray = DisplayServer.tts_get_voices_for_language("en-US")
	if not us_voices.is_empty():
		_voice_id = us_voices[0]
	else:
		var en_voices: PackedStringArray = DisplayServer.tts_get_voices_for_language("en")
		if not en_voices.is_empty():
			_voice_id = en_voices[0]
		else:
			var all_voices: Array = DisplayServer.tts_get_voices()
			if not all_voices.is_empty():
				_voice_id = all_voices[0].get("id", "")
			# If no voices are enumerated (common on Android), leave _voice_id empty.
			# tts_speak with an empty voice ID lets the platform choose its default.
	_available = true
	print("[TTSManager] Available: ", _available, " | Voice: '", _voice_id, "'")


## Returns true if TTS is supported and a voice was found.
func is_available() -> bool:
	return _available


## Speak text using the system TTS engine.
## interrupt=true (default) stops any current speech before starting.
func speak(text: String, interrupt: bool = true) -> void:
	if not _available or text.is_empty():
		return
	# volume 90/100, pitch 1.0, rate 0.85 (slightly slower — better for learners)
	DisplayServer.tts_speak(text, _voice_id, 90, 1.0, 0.85, 0, interrupt)


## Stop any ongoing TTS speech immediately.
func stop() -> void:
	if _available:
		DisplayServer.tts_stop()


## Factory: returns a pre-styled 🔊 button that speaks speak_text when pressed.
## Drop it anywhere in the UI — sized proportionally with sx/sy scale factors.
func make_speak_button(speak_text: String, sx: float, sy: float) -> Button:
	var btn := Button.new()
	btn.text = "🔊"
	btn.tooltip_text = "Hear it"
	btn.custom_minimum_size = Vector2(68 * sx, 68 * sy)
	btn.add_theme_font_size_override("font_size", int(30 * sy))
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	# Style: subtle ghost button — doesn't compete with the main interaction
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(1.0, 1.0, 1.0, 0.07)
	style_normal.corner_radius_top_left = int(10 * sx)
	style_normal.corner_radius_top_right = int(10 * sx)
	style_normal.corner_radius_bottom_left = int(10 * sx)
	style_normal.corner_radius_bottom_right = int(10 * sx)
	style_normal.border_width_top = 1
	style_normal.border_width_bottom = 1
	style_normal.border_width_left = 1
	style_normal.border_width_right = 1
	style_normal.border_color = Color(1.0, 1.0, 1.0, 0.18)
	btn.add_theme_stylebox_override("normal", style_normal)
	var style_hover := style_normal.duplicate()
	style_hover.bg_color = Color(1.0, 1.0, 1.0, 0.14)
	btn.add_theme_stylebox_override("hover", style_hover)
	var style_pressed := style_normal.duplicate()
	style_pressed.bg_color = Color(1.0, 1.0, 1.0, 0.22)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	var captured_text := speak_text
	btn.pressed.connect(func() -> void: speak(captured_text))
	return btn
