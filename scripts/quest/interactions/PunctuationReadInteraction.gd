class_name PunctuationReadInteraction
extends VBoxContainer
## PunctuationReadInteraction — Two-step linked interaction for Week 3 (Punctuation).
## Step 1: Student reads the sentence aloud (mic, speech recognition).
## Step 2: MCQ about the sentence's punctuation (fades in after read-aloud completes).
## The MCQ result is the graded answer emitted via answer_submitted.
##
## Preserves setup() / answer_submitted pattern for QuestOverlay dispatch.

signal answer_submitted(correct: bool)

# ── State ─────────────────────────────────────────────────────────────────────

enum Step { READ_ALOUD, MCQ }

const SPINNER_INTERVAL := 0.1

var _step: Step = Step.READ_ALOUD
var _sx: float = 1.0
var _sy: float = 1.0
var _question: Dictionary = {}
var _show_hints: bool = false
var _read_done: bool = false

# Speech
var _recognizer: SpeechRecognizer = null

# ── Read-Aloud UI nodes ───────────────────────────────────────────────────────
var _sentence_label: RichTextLabel = null
var _read_instruction: Label = null
var _mic_status_panel: PanelContainer = null
var _mic_status_label: Label = null
var _mic_btn: Button = null
var _mic_stop_btn: Button = null
var _read_feedback_label: Label = null

# ── MCQ UI nodes ──────────────────────────────────────────────────────────────
var _mcq_panel: PanelContainer = null
var _mcq_question_label: Label = null
var _mcq_hint_label: Label = null
var _mcq_options_vbox: VBoxContainer = null
var _mcq_feedback_panel: PanelContainer = null
var _mcq_feedback_icon: Label = null
var _mcq_feedback_label: Label = null
var _mcq_continue_btn: Button = null

# Spinner animation
var _spinner_chars: Array[String] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
var _spinner_idx := 0
var _spinner_elapsed := 0.0
var _is_processing := false


# ── Setup ─────────────────────────────────────────────────────────────────────


func setup(question: Dictionary, show_hints: bool, sx: float = 1.0, sy: float = 1.0) -> void:
	_sx = sx
	_sy = sy
	_question = question
	_show_hints = show_hints
	_build_ui()


# ── UI Construction ───────────────────────────────────────────────────────────


func _build_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", int(14 * _sy))

	# ── Speech recognizer ──────────────────────────────────────────────────────
	_recognizer = SpeechRecognizer.new()
	add_child(_recognizer)
	_recognizer.transcript_ready.connect(_on_transcript_ready)
	_recognizer.recognition_error.connect(_on_recognition_error)
	_recognizer.recognition_unavailable.connect(_on_recognition_unavailable)

	# ── Sentence display card ──────────────────────────────────────────────────
	var sentence_card := PanelContainer.new()
	sentence_card.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(16))
	sentence_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sentence_card)

	_sentence_label = RichTextLabel.new()
	_sentence_label.text = _question.get("sentence", "")
	_sentence_label.fit_content = true
	_sentence_label.bbcode_enabled = false
	_sentence_label.scroll_active = false
	_sentence_label.add_theme_font_size_override("normal_font_size", int(42 * _sy))
	_sentence_label.add_theme_color_override("default_color", StyleFactory.GOLD)
	_sentence_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sentence_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sentence_card.add_child(_sentence_label)

	# ── Read-aloud instruction ─────────────────────────────────────────────────
	_read_instruction = Label.new()
	_read_instruction.text = _question.get("instruction", "Read this sentence aloud. Then answer the question.")
	_read_instruction.add_theme_font_size_override("font_size", int(34 * _sy))
	_read_instruction.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_read_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_read_instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_read_instruction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_read_instruction)

	# ── Mic status panel ───────────────────────────────────────────────────────
	_mic_status_panel = PanelContainer.new()
	_mic_status_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(12))
	_mic_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mic_status_panel.custom_minimum_size = Vector2(0, int(80 * _sy))

	_mic_status_label = Label.new()
	_mic_status_label.text = "Tap the microphone to read aloud."
	_mic_status_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_mic_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_mic_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mic_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mic_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mic_status_panel.add_child(_mic_status_label)
	add_child(_mic_status_panel)

	# ── Mic button row ─────────────────────────────────────────────────────────
	var mic_center := CenterContainer.new()
	add_child(mic_center)

	var mic_hbox := HBoxContainer.new()
	mic_hbox.add_theme_constant_override("separation", int(12 * _sx))
	mic_center.add_child(mic_hbox)

	_mic_btn = Button.new()
	_mic_btn.text = "Tap to Speak"
	_mic_btn.custom_minimum_size = Vector2(int(280 * _sx), int(100 * _sy))
	_mic_btn.add_theme_font_size_override("font_size", int(28 * _sy))
	_mic_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_mic_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	_mic_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	_mic_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	_mic_btn.add_theme_stylebox_override("disabled", StyleFactory.make_disabled_button())
	_mic_btn.pressed.connect(_on_mic_pressed)
	mic_hbox.add_child(_mic_btn)

	_mic_stop_btn = Button.new()
	_mic_stop_btn.text = "Stop"
	_mic_stop_btn.visible = false
	_mic_stop_btn.custom_minimum_size = Vector2(int(160 * _sx), int(100 * _sy))
	_mic_stop_btn.add_theme_font_size_override("font_size", int(28 * _sy))
	_mic_stop_btn.add_theme_color_override("font_color", Color.WHITE)
	var stop_style := StyleFactory.make_primary_button_normal()
	stop_style.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	_mic_stop_btn.add_theme_stylebox_override("normal", stop_style)
	_mic_stop_btn.add_theme_stylebox_override("hover", stop_style)
	_mic_stop_btn.add_theme_stylebox_override("pressed", stop_style)
	_mic_stop_btn.pressed.connect(_on_stop_pressed)
	mic_hbox.add_child(_mic_stop_btn)

	# ── Read feedback label ────────────────────────────────────────────────────
	_read_feedback_label = Label.new()
	_read_feedback_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_read_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_read_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_read_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_read_feedback_label.visible = false
	add_child(_read_feedback_label)

	# ── MCQ panel (hidden until read step complete) ────────────────────────────
	_mcq_panel = PanelContainer.new()
	_mcq_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(14))
	_mcq_panel.visible = false
	add_child(_mcq_panel)

	var mcq_vbox := VBoxContainer.new()
	mcq_vbox.add_theme_constant_override("separation", int(10 * _sy))
	_mcq_panel.add_child(mcq_vbox)

	# Divider label
	var divider := Label.new()
	divider.text = "Now answer the question:"
	divider.add_theme_font_size_override("font_size", int(28 * _sy))
	divider.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	divider.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mcq_vbox.add_child(divider)

	# Question label
	_mcq_question_label = Label.new()
	_mcq_question_label.text = _question.get("question", "")
	_mcq_question_label.add_theme_font_size_override("font_size", int(36 * _sy))
	_mcq_question_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_mcq_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mcq_question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mcq_question_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mcq_vbox.add_child(_mcq_question_label)

	# Hint label
	_mcq_hint_label = Label.new()
	_mcq_hint_label.text = _question.get("hint", "")
	_mcq_hint_label.add_theme_font_size_override("font_size", int(24 * _sy))
	_mcq_hint_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	_mcq_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mcq_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mcq_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mcq_hint_label.visible = _show_hints and not _question.get("hint", "").is_empty()
	mcq_vbox.add_child(_mcq_hint_label)

	# Options
	_mcq_options_vbox = VBoxContainer.new()
	_mcq_options_vbox.add_theme_constant_override("separation", int(8 * _sy))
	mcq_vbox.add_child(_mcq_options_vbox)

	var options: Array = _question.get("options", [])
	for i in options.size():
		var btn := Button.new()
		btn.text = options[i]
		btn.custom_minimum_size = Vector2(0, int(108 * _sy))
		btn.add_theme_font_size_override("font_size", int(34 * _sy))
		btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		btn.add_theme_stylebox_override("normal", StyleFactory.make_glass_card(10))
		btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
		btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
		btn.add_theme_stylebox_override("disabled", StyleFactory.make_disabled_button())
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_option_pressed.bind(i))
		_mcq_options_vbox.add_child(btn)

	# Feedback panel
	_mcq_feedback_panel = PanelContainer.new()
	_mcq_feedback_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(10))
	_mcq_feedback_panel.visible = false
	mcq_vbox.add_child(_mcq_feedback_panel)

	var fb_hbox := HBoxContainer.new()
	fb_hbox.add_theme_constant_override("separation", int(8 * _sx))
	_mcq_feedback_panel.add_child(fb_hbox)

	_mcq_feedback_icon = Label.new()
	_mcq_feedback_icon.add_theme_font_size_override("font_size", int(34 * _sy))
	_mcq_feedback_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mcq_feedback_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fb_hbox.add_child(_mcq_feedback_icon)

	_mcq_feedback_label = Label.new()
	_mcq_feedback_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_mcq_feedback_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_mcq_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mcq_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mcq_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fb_hbox.add_child(_mcq_feedback_label)

	# Continue button
	var continue_center := CenterContainer.new()
	continue_center.visible = false
	mcq_vbox.add_child(continue_center)

	_mcq_continue_btn = Button.new()
	_mcq_continue_btn.text = "Continue"
	_mcq_continue_btn.custom_minimum_size = Vector2(int(240 * _sx), int(84 * _sy))
	_mcq_continue_btn.add_theme_font_size_override("font_size", int(28 * _sy))
	_mcq_continue_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_mcq_continue_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	_mcq_continue_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	_mcq_continue_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	_mcq_continue_btn.set_meta("continue_center", continue_center)
	_mcq_continue_btn.pressed.connect(_on_mcq_continue_pressed)
	continue_center.add_child(_mcq_continue_btn)


# ── Process (spinner) ─────────────────────────────────────────────────────────


func _process(delta: float) -> void:
	if not _is_processing:
		return
	_spinner_elapsed += delta
	if _spinner_elapsed >= SPINNER_INTERVAL:
		_spinner_elapsed = 0.0
		_spinner_idx = (_spinner_idx + 1) % _spinner_chars.size()
		if is_instance_valid(_mic_status_label):
			_mic_status_label.text = _spinner_chars[_spinner_idx] + " Checking your reading..."


# ── Mic Step Event Handlers ───────────────────────────────────────────────────


func _on_mic_pressed() -> void:
	if _read_done:
		return
	AudioManager.play_sfx("button_tap")
	_mic_btn.disabled = true
	_mic_btn.visible = false
	_mic_stop_btn.visible = true
	_mic_status_label.text = "Listening... read the sentence aloud!"
	_mic_status_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
	_recognizer.start_recognition("en-US")

	# Safety timeout: if nothing fires within 40s, advance to MCQ gracefully
	await get_tree().create_timer(40.0).timeout
	if not is_instance_valid(self):
		return
	if not _read_done:
		_finish_read_step(false, "Timed out — let's try the question.")


func _on_stop_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	_recognizer.stop_recognition()
	_mic_stop_btn.visible = false
	_is_processing = true
	set_process(true)


func _on_transcript_ready(_text: String, _confidence: float) -> void:
	_is_processing = false
	set_process(false)
	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self):
		return
	_finish_read_step(true, "Great reading! Now answer the question below.")


func _on_recognition_error(reason: String) -> void:
	_is_processing = false
	set_process(false)
	if _read_done:
		return
	# Show error but still advance — don't block the student
	var msg: String
	if "unavailable" in reason.to_lower() or "service" in reason.to_lower():
		msg = "Voice check unavailable — let's try the question."
	else:
		msg = reason + " — Tap to try again, or skip to the question."
	_mic_status_label.text = msg
	_mic_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	_mic_btn.visible = true
	_mic_btn.disabled = false
	_mic_stop_btn.visible = false
	# Show a "skip to question" button
	_show_skip_button()


func _on_recognition_unavailable() -> void:
	_is_processing = false
	set_process(false)
	if _read_done:
		return
	_finish_read_step(false, "Voice check not available — answering the question now.")


func _show_skip_button() -> void:
	if not is_instance_valid(_read_feedback_label):
		return
	_read_feedback_label.text = "↓ Tap 'Skip to Question' if speech isn't working."
	_read_feedback_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_read_feedback_label.visible = true

	# Only add the skip button once
	for child in get_children():
		if child.get_meta("is_skip_btn", false):
			return

	var skip_center := CenterContainer.new()
	add_child(skip_center)

	var skip_btn := Button.new()
	skip_btn.set_meta("is_skip_btn", true)
	skip_btn.text = "Skip to Question"
	skip_btn.custom_minimum_size = Vector2(int(300 * _sx), int(80 * _sy))
	skip_btn.add_theme_font_size_override("font_size", int(24 * _sy))
	skip_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	skip_btn.add_theme_stylebox_override("normal", StyleFactory.make_glass_card(10))
	skip_btn.add_theme_stylebox_override("hover", StyleFactory.make_glass_card(10))
	skip_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		_finish_read_step(false, "")
	)
	skip_center.add_child(skip_btn)


# ── Transition to MCQ ─────────────────────────────────────────────────────────


func _finish_read_step(success: bool, message: String) -> void:
	if _read_done:
		return
	_read_done = true
	_step = Step.MCQ

	# Hide mic controls
	_mic_btn.visible = false
	_mic_stop_btn.visible = false

	if not message.is_empty():
		_read_feedback_label.text = message
		_read_feedback_label.add_theme_color_override(
			"font_color",
			StyleFactory.SUCCESS_GREEN if success else StyleFactory.TEXT_MUTED
		)
		_read_feedback_label.visible = true
		if success:
			AudioManager.play_sfx("correct")

	_mic_status_label.text = "Reading complete! ✓" if success else "Now answer the question."
	_mic_status_label.add_theme_color_override(
		"font_color",
		StyleFactory.SUCCESS_GREEN if success else StyleFactory.TEXT_MUTED
	)

	# Fade in MCQ panel
	_mcq_panel.modulate.a = 0.0
	_mcq_panel.visible = true
	UIAnimations.fade_in_up(self, _mcq_panel)


# ── MCQ Step Event Handlers ───────────────────────────────────────────────────


func _on_option_pressed(index: int) -> void:
	# Store selection result for continue button
	var correct_index: int = _question.get("correct_index", -1)
	var is_correct := index == correct_index
	_mcq_feedback_panel.set_meta("is_correct", is_correct)

	# Disable all options
	for btn in _mcq_options_vbox.get_children():
		(btn as Button).disabled = true

	# Highlight selected and correct options
	for i in _mcq_options_vbox.get_child_count():
		var btn := _mcq_options_vbox.get_child(i) as Button
		if i == correct_index:
			var correct_style := StyleFactory.make_primary_button_normal()
			correct_style.bg_color = StyleFactory.SUCCESS_GREEN.darkened(0.3)
			btn.add_theme_stylebox_override("disabled", correct_style)
		elif i == index and not is_correct:
			var wrong_style := StyleFactory.make_primary_button_normal()
			wrong_style.bg_color = Color(0.75, 0.2, 0.2, 1.0)
			btn.add_theme_stylebox_override("disabled", wrong_style)

	# Show feedback
	_mcq_feedback_icon.text = "✓" if is_correct else "✗"
	_mcq_feedback_icon.add_theme_color_override(
		"font_color", StyleFactory.SUCCESS_GREEN if is_correct else Color(0.9, 0.3, 0.3, 1.0)
	)
	var feedback_key := "feedback_correct" if is_correct else "feedback_wrong"
	_mcq_feedback_label.text = _question.get(feedback_key, "")
	_mcq_feedback_panel.visible = true
	UIAnimations.fade_in_up(self, _mcq_feedback_panel)

	# Play sound
	AudioManager.play_sfx("correct" if is_correct else "wrong")
	if is_correct:
		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.08))

	# Show continue button
	if is_instance_valid(_mcq_continue_btn) and _mcq_continue_btn.has_meta("continue_center"):
		(_mcq_continue_btn.get_meta("continue_center") as Control).visible = true


func _on_mcq_continue_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	var is_correct: bool = _mcq_feedback_panel.get_meta("is_correct", false)
	answer_submitted.emit(is_correct)
