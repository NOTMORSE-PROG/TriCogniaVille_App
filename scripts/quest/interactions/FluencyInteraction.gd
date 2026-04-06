extends Control
## FluencyInteraction — Passage reading with auto-graded fluency assessment.
## Records audio while Android STT transcribes. FeedbackEngine.assess_fluency()
## scores completeness + accuracy. Audio uploaded to Cloudinary for teacher.
##
## States: IDLE → RECORDING → PROCESSING → RESULT

signal answer_submitted(correct: bool)
signal fluency_score_submitted(score: int)

# ── State ─────────────────────────────────────────────────────────────────────

enum State { IDLE, RECORDING, PROCESSING, RESULT }

const SPINNER_INTERVAL := 0.1
const MAX_LISTEN_SECONDS := 90.0

var _state: State = State.IDLE
var _sx: float = 1.0
var _sy: float = 1.0
var _question: Dictionary = {}
var _recognizer: SpeechRecognizer = null
var _current_result: Dictionary = {}

# UI nodes
var _record_btn: Button = null
var _stop_btn: Button = null
var _status_panel: PanelContainer = null
var _status_label: Label = null
var _result_panel: PanelContainer = null
var _score_bar: ProgressBar = null
var _score_label: Label = null
var _summary_label: Label = null
var _detail_label: Label = null
var _continue_btn: Button = null

# Spinner animation
var _spinner_chars: Array[String] = [
	"\u280b",
	"\u2819",
	"\u2839",
	"\u2838",
	"\u283c",
	"\u2834",
	"\u2826",
	"\u2827",
	"\u2807",
	"\u280f"
]
var _spinner_idx := 0
var _spinner_elapsed := 0.0

# ── Setup ─────────────────────────────────────────────────────────────────────


func setup(question: Dictionary, _show_hints: bool, sx: float = 1.0, sy: float = 1.0) -> void:
	_sx = sx
	_sy = sy
	_question = question
	_build_ui()


# ── UI Construction ───────────────────────────────────────────────────────────


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	_recognizer = SpeechRecognizer.new()
	_recognizer.MAX_LISTEN_SECONDS = MAX_LISTEN_SECONDS
	add_child(_recognizer)
	_recognizer.transcript_ready.connect(_on_transcript_ready)
	_recognizer.recognition_error.connect(_on_recognition_error)
	_recognizer.recognition_unavailable.connect(_on_recognition_unavailable)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", int(12 * _sy))
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Instruction label ──────────────────────────────────────────────────────
	var instruction: String = _question.get("instruction", "Read the full passage aloud clearly.")
	var inst_label := Label.new()
	inst_label.text = instruction
	inst_label.add_theme_font_size_override("font_size", int(17 * _sy))
	inst_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	inst_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inst_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(inst_label)

	# ── Passage card (scrollable) ──────────────────────────────────────────────
	var passage: String = _question.get("passage", "")
	if not passage.is_empty():
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(14))
		card.custom_minimum_size = Vector2(0, 140 * _sy)

		var scroll := ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_child(scroll)

		var passage_label := RichTextLabel.new()
		passage_label.text = passage
		passage_label.fit_content = true
		passage_label.bbcode_enabled = false
		passage_label.scroll_active = false
		passage_label.add_theme_font_size_override("normal_font_size", int(16 * _sy))
		passage_label.add_theme_color_override("default_color", StyleFactory.TEXT_PRIMARY)
		passage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		passage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scroll.add_child(passage_label)

		vbox.add_child(card)

	# ── Status panel ───────────────────────────────────────────────────────────
	_status_panel = PanelContainer.new()
	_status_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(12))
	_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_panel.custom_minimum_size = Vector2(0, 48 * _sy)

	_status_label = Label.new()
	_status_label.text = "Tap the button below when ready to read."
	_status_label.add_theme_font_size_override("font_size", int(14 * _sy))
	_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_panel.add_child(_status_label)
	vbox.add_child(_status_panel)

	# ── Controls ───────────────────────────────────────────────────────────────
	var controls_center := CenterContainer.new()
	vbox.add_child(controls_center)

	var controls_hbox := HBoxContainer.new()
	controls_hbox.add_theme_constant_override("separation", int(12 * _sx))
	controls_center.add_child(controls_hbox)

	_record_btn = Button.new()
	_record_btn.text = "Tap to Record"
	_record_btn.custom_minimum_size = Vector2(200 * _sx, 52 * _sy)
	_record_btn.add_theme_font_size_override("font_size", int(17 * _sy))
	_record_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_record_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	_record_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	_record_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	_record_btn.add_theme_stylebox_override("disabled", StyleFactory.make_disabled_button())
	_record_btn.pressed.connect(_on_record_pressed)
	controls_hbox.add_child(_record_btn)

	_stop_btn = Button.new()
	_stop_btn.text = "Stop"
	_stop_btn.visible = false
	_stop_btn.custom_minimum_size = Vector2(100 * _sx, 52 * _sy)
	_stop_btn.add_theme_font_size_override("font_size", int(17 * _sy))
	_stop_btn.add_theme_color_override("font_color", Color.WHITE)
	var stop_style := StyleFactory.make_primary_button_normal()
	stop_style.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	_stop_btn.add_theme_stylebox_override("normal", stop_style)
	_stop_btn.add_theme_stylebox_override("hover", stop_style)
	_stop_btn.add_theme_stylebox_override("pressed", stop_style)
	_stop_btn.pressed.connect(_on_stop_pressed)
	controls_hbox.add_child(_stop_btn)

	# ── Result panel (hidden until RESULT state) ───────────────────────────────
	_result_panel = PanelContainer.new()
	_result_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(14))
	_result_panel.visible = false

	var result_vbox := VBoxContainer.new()
	result_vbox.add_theme_constant_override("separation", int(8 * _sy))
	_result_panel.add_child(result_vbox)

	_score_bar = ProgressBar.new()
	_score_bar.min_value = 0
	_score_bar.max_value = 100
	_score_bar.value = 0
	_score_bar.custom_minimum_size = Vector2(0, 10 * _sy)
	_score_bar.add_theme_stylebox_override("background", StyleFactory.make_progress_bg())
	_score_bar.add_theme_stylebox_override("fill", StyleFactory.make_progress_fill())
	_score_bar.show_percentage = false
	result_vbox.add_child(_score_bar)

	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", int(22 * _sy))
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_score_label)

	_summary_label = Label.new()
	_summary_label.add_theme_font_size_override("font_size", int(16 * _sy))
	_summary_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_summary_label)

	_detail_label = Label.new()
	_detail_label.add_theme_font_size_override("font_size", int(14 * _sy))
	_detail_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_detail_label)

	vbox.add_child(_result_panel)

	# ── Continue button ────────────────────────────────────────────────────────
	var action_center := CenterContainer.new()
	action_center.visible = false
	vbox.add_child(action_center)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.custom_minimum_size = Vector2(160 * _sx, 48 * _sy)
	_continue_btn.add_theme_font_size_override("font_size", int(16 * _sy))
	_continue_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_continue_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	_continue_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	_continue_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	_continue_btn.pressed.connect(_on_continue_pressed)
	action_center.add_child(_continue_btn)
	_continue_btn.set_meta("action_center", action_center)

	# ── Decide initial state ───────────────────────────────────────────────────
	if _recognizer.is_available():
		_set_state(State.IDLE)
	else:
		# Fallback: auto-pass with default fluency score
		_auto_pass_fallback()


# ── State Machine ─────────────────────────────────────────────────────────────


func _set_state(new_state: State) -> void:
	_state = new_state
	_update_ui_for_state()


func _update_ui_for_state() -> void:
	_record_btn.visible = false
	_stop_btn.visible = false
	if is_instance_valid(_result_panel):
		_result_panel.visible = false
	if is_instance_valid(_continue_btn) and _continue_btn.has_meta("action_center"):
		(_continue_btn.get_meta("action_center") as Control).visible = false
	set_process(false)

	match _state:
		State.IDLE:
			_record_btn.visible = true
			_record_btn.disabled = false
			_status_label.text = "Tap the button when ready to read the passage."
			_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)

		State.RECORDING:
			_stop_btn.visible = true
			_status_label.text = "Listening... read the passage aloud now!"
			_status_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
			set_process(true)

		State.PROCESSING:
			_status_label.text = "Analyzing your reading..."
			_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
			set_process(true)

		State.RESULT:
			_result_panel.visible = true
			if is_instance_valid(_continue_btn) and _continue_btn.has_meta("action_center"):
				(_continue_btn.get_meta("action_center") as Control).visible = true
			_populate_result()


func _process(delta: float) -> void:
	match _state:
		State.RECORDING:
			var t := fmod(Time.get_ticks_msec() / 1000.0, 1.2)
			var alpha := 0.5 + 0.5 * sin(t * TAU / 1.2)
			if is_instance_valid(_status_panel):
				_status_panel.modulate.a = alpha

		State.PROCESSING:
			_spinner_elapsed += delta
			if _spinner_elapsed >= SPINNER_INTERVAL:
				_spinner_elapsed = 0.0
				_spinner_idx = (_spinner_idx + 1) % _spinner_chars.size()
				if is_instance_valid(_status_label):
					_status_label.text = _spinner_chars[_spinner_idx] + " Analyzing your reading..."


# ── Event Handlers ────────────────────────────────────────────────────────────


func _on_record_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	_set_state(State.RECORDING)
	_recognizer.start_recognition("en-US")


func _on_stop_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	_recognizer.stop_recognition()
	_set_state(State.PROCESSING)


func _on_transcript_ready(text: String, confidence: float) -> void:
	_set_state(State.PROCESSING)
	var expected: String = _question.get("passage", "")
	var cfg: Dictionary = QuestManager.get_assessment_config()

	# Run assess_fluency() on each alternative and keep the best fluency_score.
	# best_match() calls assess() which never returns fluency_score, so we
	# must use assess_fluency() directly for the fluency interaction.
	var alternatives := _recognizer.get_alternatives()
	if alternatives.size() > 1:
		var best_fluency := -1
		for alt in alternatives:
			var alt_text: String = str(alt)
			if alt_text.strip_edges().is_empty():
				continue
			var r := FeedbackEngine.assess_fluency(expected, alt_text, confidence, cfg)
			if r.get("fluency_score", 0) > best_fluency:
				best_fluency = r.get("fluency_score", 0)
				_current_result = r
		if _current_result.is_empty():
			_current_result = FeedbackEngine.assess_fluency(expected, text, confidence, cfg)
	else:
		_current_result = FeedbackEngine.assess_fluency(expected, text, confidence, cfg)

	var fluency: int = _current_result.get("fluency_score", 0)

	# Upload audio
	var audio_b64 := _recognizer.get_audio_base64()
	if not audio_b64.is_empty():
		ApiClient.upload_audio(
			audio_b64,
			func(success: bool, data: Dictionary) -> void:
				var audio_url: String = data.get("audioUrl", "") if success else ""
				_submit_assessment(_current_result, text, confidence, audio_url)
		)
	else:
		_submit_assessment(_current_result, text, confidence, "")

	fluency_score_submitted.emit(fluency)

	await get_tree().create_timer(0.5).timeout
	_set_state(State.RESULT)

	var cfg_pass: int = cfg.get("fluency_pass", 60)
	if fluency >= cfg_pass:
		AudioManager.play_sfx("correct")
		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.08))
	else:
		AudioManager.play_sfx("wrong")


func _on_recognition_error(reason: String) -> void:
	_set_state(State.IDLE)
	_status_label.text = reason
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))


func _on_recognition_unavailable() -> void:
	_auto_pass_fallback()


func _on_continue_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	var fluency: int = _current_result.get("fluency_score", 0)
	var cfg: Dictionary = QuestManager.get_assessment_config()
	var cfg_pass: int = cfg.get("fluency_pass", 60)
	answer_submitted.emit(fluency >= cfg_pass)


# ── Result Display ────────────────────────────────────────────────────────────


func _populate_result() -> void:
	var fluency: int = _current_result.get("fluency_score", 0)
	_score_bar.value = fluency

	_score_label.text = "Fluency: %d%%" % fluency
	if fluency >= 80:
		_score_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
		_summary_label.text = "Excellent fluency! You read smoothly and clearly."
	elif fluency >= 60:
		_score_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
		_summary_label.text = "Good reading! Keep practicing your smoothness."
	else:
		_score_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
		_summary_label.text = "Let's practice reading more smoothly. Try again!"

	_detail_label.text = _current_result.get("feedback_detail", "")

	UIAnimations.fade_in_up(self, _result_panel)


# ── Fallback ──────────────────────────────────────────────────────────────────


func _auto_pass_fallback() -> void:
	_status_label.text = "Voice check not available. Passage auto-accepted."
	_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_current_result = {"fluency_score": 75, "correct": true}
	fluency_score_submitted.emit(75)
	answer_submitted.emit(true)


# ── Assessment Submission ─────────────────────────────────────────────────────


func _submit_assessment(
	result: Dictionary, transcript: String, confidence: float, audio_url: String = ""
) -> void:
	if not ApiClient.is_authenticated:
		return

	var quest_data := QuestManager.get_current_quest_data()
	var building_id: String = QuestManager.get_current_building_id()
	var stage: String = QuestManager.get_current_stage()
	var quest_id: String = quest_data.get("quest_id", "unknown")
	var expected: String = _question.get("passage", "")

	var payload := {
		"questId": quest_id,
		"buildingId": building_id,
		"stage": stage,
		"expectedText": expected,
		"transcript": transcript,
		"confidence": confidence,
		"score": result.get("fluency_score", 0),
		"feedback": result.get("feedback_summary", "") + " " + result.get("feedback_detail", ""),
		"errorTypes": result.get("error_types", []),
		"flagReview": result.get("flag_review", false),
		"attemptNumber": 1,
		"audioUrl": audio_url,
	}

	ApiClient.submit_speech_assessment(
		payload,
		func(success: bool, data: Dictionary) -> void:
			if not success:
				push_error(
					"[FluencyInteraction] Speech assessment submission failed: %s" % str(data)
				)
				# Surface a small on-screen indicator so the student/teacher knows the
				# reading wasn't saved to the review queue. (Durable local-queue retry
				# is tracked for Pass 4.)
				if is_instance_valid(_status_label):
					_status_label.text = "(couldn't save reading)"
					_status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3, 1.0))
	)
