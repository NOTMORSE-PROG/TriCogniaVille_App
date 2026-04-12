class_name PunctuationReadInteraction
extends VBoxContainer
## PunctuationReadInteraction — Two-step linked interaction for Week 3 (Punctuation).
##
## Phases (one thing visible at a time — no stacking):
##   READ    → sentence card + mic controls
##   RESULT  → score panel replaces everything (like school ReadAloudInteraction)
##   MCQ     → sentence card + question panel
##   DONE    → MCQ answered, feedback visible, answer_submitted emitted
##
## Score only if BOTH the read-aloud passes AND the MCQ answer is correct.

signal answer_submitted(correct: bool)

# ── Phase ─────────────────────────────────────────────────────────────────────

enum Phase { READ, RESULT, MCQ }

const SPINNER_INTERVAL := 0.1
const MAX_READ_ATTEMPTS := 3

var _phase: Phase = Phase.READ
var _sx: float = 1.0
var _sy: float = 1.0
var _question: Dictionary = {}
var _show_hints: bool = false
var _read_correct: bool = false
var _read_attempt: int = 0
var _is_processing := false

# Speech
var _recognizer: SpeechRecognizer = null

# ── READ phase nodes ───────────────────────────────────────────────────────────
var _sentence_card: PanelContainer = null   # shown in READ + MCQ phases
var _read_section: VBoxContainer = null     # everything below the sentence in READ phase
var _mic_status_label: Label = null
var _mic_btn: Button = null
var _mic_stop_btn: Button = null

# ── RESULT phase nodes ─────────────────────────────────────────────────────────
var _result_panel: PanelContainer = null
var _result_score_label: Label = null
var _result_summary_label: Label = null
var _result_try_again_center: CenterContainer = null

# ── MCQ phase nodes ────────────────────────────────────────────────────────────
var _mcq_panel: PanelContainer = null
var _mcq_question_label: Label = null
var _mcq_hint_label: Label = null
var _mcq_options_vbox: VBoxContainer = null
var _mcq_feedback_panel: PanelContainer = null
var _mcq_feedback_icon: Label = null
var _mcq_feedback_label: Label = null

# Spinner
var _spinner_chars: Array[String] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
var _spinner_idx := 0
var _spinner_elapsed := 0.0


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

	# ══ Sentence card (READ + MCQ phases) ═════════════════════════════════════
	_sentence_card = PanelContainer.new()
	_sentence_card.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(16))
	_sentence_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sentence_card)

	var sentence_label := RichTextLabel.new()
	var sentence_text: String = _question.get("sentence", "")
	sentence_label.text = sentence_text
	sentence_label.fit_content = true
	sentence_label.bbcode_enabled = false
	sentence_label.scroll_active = false
	var s_len := sentence_text.length()
	var s_font: int
	if s_len > 350:
		s_font = 16
	elif s_len > 200:
		s_font = 20
	elif s_len > 100:
		s_font = 26
	else:
		s_font = 36
	sentence_label.add_theme_font_size_override("normal_font_size", int(s_font * _sy))
	sentence_label.add_theme_color_override("default_color", StyleFactory.GOLD)
	sentence_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sentence_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sentence_card.add_child(sentence_label)

	# ══ READ section (shown only in READ phase) ════════════════════════════════
	_read_section = VBoxContainer.new()
	_read_section.add_theme_constant_override("separation", int(12 * _sy))
	_read_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_read_section)

	var read_instruction := Label.new()
	read_instruction.text = _question.get("instruction", "Read this sentence aloud.")
	var ri_text: String = _question.get("instruction", "Read this sentence aloud.")
	var ri_font: int = (30 if ri_text.length() > 150 else (38 if ri_text.length() > 80 else 46))
	read_instruction.add_theme_font_size_override("font_size", int(ri_font * _sy))
	read_instruction.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	read_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	read_instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	read_instruction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_read_section.add_child(read_instruction)

	var mic_status_panel := PanelContainer.new()
	mic_status_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(12))
	mic_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mic_status_panel.custom_minimum_size = Vector2(0, int(80 * _sy))
	_read_section.add_child(mic_status_panel)

	_mic_status_label = Label.new()
	_mic_status_label.text = "Tap the microphone to read aloud."
	_mic_status_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_mic_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_mic_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mic_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mic_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mic_status_panel.add_child(_mic_status_label)

	var mic_center := CenterContainer.new()
	_read_section.add_child(mic_center)

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

	# ══ RESULT section (shown only in RESULT phase) ════════════════════════════
	_result_panel = PanelContainer.new()
	_result_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(14))
	_result_panel.visible = false
	_result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_result_panel)

	var result_vbox := VBoxContainer.new()
	result_vbox.add_theme_constant_override("separation", int(8 * _sy))
	_result_panel.add_child(result_vbox)

	_result_score_label = Label.new()
	_result_score_label.add_theme_font_size_override("font_size", int(52 * _sy))
	_result_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_result_score_label)

	_result_summary_label = Label.new()
	_result_summary_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_result_summary_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_result_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_result_summary_label)

	_result_try_again_center = CenterContainer.new()
	_result_try_again_center.visible = false
	add_child(_result_try_again_center)

	var try_again_btn := Button.new()
	try_again_btn.text = "Try Again"
	try_again_btn.custom_minimum_size = Vector2(int(240 * _sx), int(84 * _sy))
	try_again_btn.add_theme_font_size_override("font_size", int(28 * _sy))
	try_again_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	try_again_btn.add_theme_stylebox_override("normal", StyleFactory.make_glass_card(10))
	try_again_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	try_again_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	try_again_btn.pressed.connect(_on_try_again_pressed)
	_result_try_again_center.add_child(try_again_btn)

	# ══ MCQ section (shown only in MCQ phase) ═════════════════════════════════
	_mcq_panel = PanelContainer.new()
	_mcq_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(14))
	_mcq_panel.visible = false
	add_child(_mcq_panel)

	var mcq_vbox := VBoxContainer.new()
	mcq_vbox.add_theme_constant_override("separation", int(10 * _sy))
	_mcq_panel.add_child(mcq_vbox)

	_mcq_question_label = Label.new()
	_mcq_question_label.text = _question.get("question", "")
	_mcq_question_label.add_theme_font_size_override("font_size", int(36 * _sy))
	_mcq_question_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_mcq_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mcq_question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mcq_question_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mcq_vbox.add_child(_mcq_question_label)

	_mcq_hint_label = Label.new()
	_mcq_hint_label.text = _question.get("hint", "")
	_mcq_hint_label.add_theme_font_size_override("font_size", int(24 * _sy))
	_mcq_hint_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	_mcq_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mcq_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mcq_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mcq_hint_label.visible = _show_hints and not _question.get("hint", "").is_empty()
	mcq_vbox.add_child(_mcq_hint_label)

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

	# Feedback (hidden until answered)
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


# ── Phase transitions ─────────────────────────────────────────────────────────


func _set_phase(p: Phase) -> void:
	_phase = p
	# Hide everything, then show only what this phase needs
	_sentence_card.visible = false
	_read_section.visible = false
	_result_panel.visible = false
	_result_try_again_center.visible = false
	_mcq_panel.visible = false

	match p:
		Phase.READ:
			_sentence_card.visible = true
			_read_section.visible = true

		Phase.RESULT:
			# Sentence hidden — full attention on score, same as school
			_result_panel.visible = true

		Phase.MCQ:
			# Sentence back as reference for answering the question
			_sentence_card.visible = true
			_mcq_panel.visible = true


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


# ── READ phase handlers ───────────────────────────────────────────────────────


func _on_mic_pressed() -> void:
	if _phase != Phase.READ:
		return
	_read_attempt += 1
	AudioManager.play_sfx("button_tap")
	_mic_btn.disabled = true
	_mic_btn.visible = false
	_mic_stop_btn.visible = true
	_mic_status_label.text = "Listening... read the sentence aloud!"
	_mic_status_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
	_recognizer.start_recognition("en-US")

	# Safety timeout
	await get_tree().create_timer(40.0).timeout
	if not is_instance_valid(self) or _phase != Phase.READ:
		return
	_go_to_mcq(false)


func _on_stop_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	_recognizer.stop_recognition()
	_mic_stop_btn.visible = false
	_is_processing = true
	set_process(true)
	_mic_status_label.text = "Checking your reading..."
	_mic_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)


func _on_transcript_ready(text: String, confidence: float) -> void:
	_is_processing = false
	set_process(false)

	var expected: String = _question.get("word", _question.get("sentence", ""))
	var cfg: Dictionary = QuestManager.get_assessment_config()
	var result: Dictionary

	if expected.is_empty():
		result = {"score": 100, "correct": true, "feedback_summary": "Great reading!"}
	else:
		var alternatives := _recognizer.get_alternatives()
		if alternatives.size() > 1:
			result = FeedbackEngine.best_match(expected, alternatives, confidence, cfg)
		else:
			result = FeedbackEngine.assess(expected, text, confidence, cfg)

	var is_correct: bool = result.get("correct", false)
	if is_correct:
		_read_correct = true

	_show_result(result)

	if is_correct or _read_attempt >= MAX_READ_ATTEMPTS:
		AudioManager.play_sfx("correct" if is_correct else "wrong")
		if is_correct:
			UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.08))
		await get_tree().create_timer(1.5).timeout
		if not is_instance_valid(self):
			return
		_go_to_mcq(is_correct)
	else:
		AudioManager.play_sfx("wrong")
		_result_try_again_center.visible = true


func _show_result(result: Dictionary) -> void:
	var score: int = result.get("score", 0)
	var score_color: Color
	if score >= 75:
		score_color = StyleFactory.SUCCESS_GREEN
	elif score >= 50:
		score_color = Color(1.0, 0.8, 0.2, 1.0)
	else:
		score_color = Color(0.9, 0.3, 0.3, 1.0)
	_result_score_label.text = "%d%%" % score
	_result_score_label.add_theme_color_override("font_color", score_color)
	_result_summary_label.text = result.get("feedback_summary", "")
	# Switch to RESULT phase — sentence + mic disappear, score takes their place
	_set_phase(Phase.RESULT)


func _on_try_again_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	_result_try_again_center.visible = false
	_set_phase(Phase.READ)
	_mic_btn.visible = true
	_mic_btn.disabled = false
	_mic_stop_btn.visible = false
	_mic_status_label.text = "Tap the microphone to read aloud."
	_mic_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)


func _go_to_mcq(_read_passed: bool) -> void:
	_set_phase(Phase.MCQ)


func _on_recognition_error(reason: String) -> void:
	_is_processing = false
	set_process(false)
	if _phase != Phase.READ:
		return
	var msg: String
	if "unavailable" in reason.to_lower() or "service" in reason.to_lower():
		msg = "Voice check unavailable."
	else:
		msg = reason + " — try again or skip."
	_mic_status_label.text = msg
	_mic_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	_mic_btn.visible = true
	_mic_btn.disabled = false
	_mic_stop_btn.visible = false
	_show_skip_button()


func _on_recognition_unavailable() -> void:
	_is_processing = false
	set_process(false)
	if _phase != Phase.READ:
		return
	_read_correct = true  # benefit of the doubt — no hardware to assess
	_go_to_mcq(true)


func _show_skip_button() -> void:
	for child in get_children():
		if child.get_meta("is_skip_center", false):
			return
	var skip_center := CenterContainer.new()
	skip_center.set_meta("is_skip_center", true)
	add_child(skip_center)
	var skip_btn := Button.new()
	skip_btn.text = "Skip to Question"
	skip_btn.custom_minimum_size = Vector2(int(300 * _sx), int(80 * _sy))
	skip_btn.add_theme_font_size_override("font_size", int(24 * _sy))
	skip_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	skip_btn.add_theme_stylebox_override("normal", StyleFactory.make_glass_card(10))
	skip_btn.add_theme_stylebox_override("hover", StyleFactory.make_glass_card(10))
	skip_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_tap")
		skip_center.queue_free()
		_go_to_mcq(false)
	)
	skip_center.add_child(skip_btn)


# ── MCQ phase handlers ────────────────────────────────────────────────────────


func _on_option_pressed(index: int) -> void:
	var correct_index: int = _question.get("correct_index", -1)
	var is_correct := index == correct_index

	# Question text no longer needed — collapse it
	_mcq_question_label.visible = false
	_mcq_hint_label.visible = false

	# Disable all options
	for btn in _mcq_options_vbox.get_children():
		(btn as Button).disabled = true

	# Colour-code selection
	for i in _mcq_options_vbox.get_child_count():
		var btn := _mcq_options_vbox.get_child(i) as Button
		if i == correct_index:
			var s := StyleFactory.make_primary_button_normal()
			s.bg_color = StyleFactory.SUCCESS_GREEN.darkened(0.3)
			btn.add_theme_stylebox_override("disabled", s)
		elif i == index and not is_correct:
			var s := StyleFactory.make_primary_button_normal()
			s.bg_color = Color(0.75, 0.2, 0.2, 1.0)
			btn.add_theme_stylebox_override("disabled", s)

	# Show feedback
	_mcq_feedback_icon.text = "✓" if is_correct else "✗"
	_mcq_feedback_icon.add_theme_color_override(
		"font_color", StyleFactory.SUCCESS_GREEN if is_correct else Color(0.9, 0.3, 0.3, 1.0)
	)
	_mcq_feedback_label.text = _question.get("feedback_correct" if is_correct else "feedback_wrong", "")
	_mcq_feedback_panel.visible = true

	AudioManager.play_sfx("correct" if is_correct else "wrong")
	if is_correct:
		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.08))

	# Score only if BOTH read passed AND MCQ correct
	answer_submitted.emit(_read_correct and is_correct)
