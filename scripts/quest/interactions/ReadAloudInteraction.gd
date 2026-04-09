extends Control
## ReadAloudInteraction — Production read-aloud with Web Speech API assessment.
## States: IDLE → LISTENING → PROCESSING → RESULT (→ retry → IDLE)
## Fallback: UNAVAILABLE → TIMER_WAIT → COMPLETE  (desktop / unsupported browser)
##
## Preserves setup() signature and answer_submitted signal so QuestOverlay
## requires zero changes.

signal answer_submitted(correct: bool)

# ── State ─────────────────────────────────────────────────────────────────────

enum State { IDLE, LISTENING, PROCESSING, RESULT, UNAVAILABLE, TIMER_WAIT, COMPLETE }

const MAX_ATTEMPTS := 3
const SPINNER_INTERVAL := 0.1

var _state: State = State.IDLE
var _sx: float = 1.0
var _sy: float = 1.0
var _question: Dictionary = {}

# Speech components (created in _build_ui)
var _recognizer: SpeechRecognizer = null

# UI node references
var _record_btn: Button = null
var _stop_btn: Button = null
var _status_panel: PanelContainer = null
var _status_label: Label = null
var _result_panel: PanelContainer = null
var _score_bar: ProgressBar = null
var _score_label: Label = null
var _summary_label: Label = null
var _detail_label: Label = null
var _encourage_label: Label = null
var _flag_label: Label = null
var _try_again_btn: Button = null
var _continue_btn: Button = null
var _attempt_label: Label = null

# Fallback (timer) references

# Attempt tracking
var _attempt_number := 0
var _best_score := -1
var _best_result: Dictionary = {}

# Spinner animation
var _spinner_chars: Array[String] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
var _spinner_idx := 0
var _spinner_elapsed := 0.0

# Fallback timer

# Current assessment result (populated after processing)
var _current_result: Dictionary = {}

# ── Setup ─────────────────────────────────────────────────────────────────────


func setup(question: Dictionary, _show_hints: bool, sx: float = 1.0, sy: float = 1.0) -> void:
	_sx = sx
	_sy = sy
	_question = question
	_attempt_number = 0
	_best_score = -1
	_best_result = {}
	_build_ui()


# ── UI Construction ───────────────────────────────────────────────────────────


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	# Set up speech recognizer
	_recognizer = SpeechRecognizer.new()
	add_child(_recognizer)
	_recognizer.transcript_ready.connect(_on_transcript_ready)
	_recognizer.recognition_error.connect(_on_recognition_error)
	_recognizer.recognition_unavailable.connect(_on_recognition_unavailable)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", int(14 * _sy))
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Instruction label ──────────────────────────────────────────────────────
	var instruction: String = _question.get("instruction", "Read this aloud clearly.")
	var inst_label := Label.new()
	inst_label.text = instruction
	inst_label.add_theme_font_size_override("font_size", int(34 * _sy))
	inst_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	inst_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inst_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(inst_label)

	# ── Content card ───────────────────────────────────────────────────────────
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(16))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var word: String = _question.get("word", "")
	var passage: String = _question.get("passage", "")

	if not word.is_empty():
		var word_label := Label.new()
		word_label.text = word
		word_label.add_theme_font_size_override("font_size", int(64 * _sy))
		word_label.add_theme_color_override("font_color", StyleFactory.GOLD)
		word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(word_label)
	elif not passage.is_empty():
		var passage_label := RichTextLabel.new()
		passage_label.text = passage
		passage_label.fit_content = true
		passage_label.bbcode_enabled = false
		passage_label.scroll_active = false
		passage_label.add_theme_font_size_override("normal_font_size", int(32 * _sy))
		passage_label.add_theme_color_override("default_color", StyleFactory.TEXT_PRIMARY)
		passage_label.custom_minimum_size = Vector2(0, 120 * _sy)
		passage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(passage_label)

	vbox.add_child(card)

	# ── Attempt counter ────────────────────────────────────────────────────────
	_attempt_label = Label.new()
	_attempt_label.add_theme_font_size_override("font_size", int(20 * _sy))
	_attempt_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_attempt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attempt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attempt_label.visible = false
	vbox.add_child(_attempt_label)

	# ── Status panel (mic indicator / spinner) ─────────────────────────────────
	_status_panel = PanelContainer.new()
	_status_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(12))
	_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_panel.custom_minimum_size = Vector2(0, 84 * _sy)

	_status_label = Label.new()
	_status_label.text = "Tap the microphone when ready to read."
	_status_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_panel.add_child(_status_label)
	vbox.add_child(_status_panel)

	# ── Recording controls row ─────────────────────────────────────────────────
	var controls_center := CenterContainer.new()
	vbox.add_child(controls_center)

	var controls_hbox := HBoxContainer.new()
	controls_hbox.add_theme_constant_override("separation", int(12 * _sx))
	controls_center.add_child(controls_hbox)

	_record_btn = Button.new()
	_record_btn.text = "Tap to Speak"
	_record_btn.custom_minimum_size = Vector2(280 * _sx, 100 * _sy)
	_record_btn.add_theme_font_size_override("font_size", int(28 * _sy))
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
	_stop_btn.custom_minimum_size = Vector2(160 * _sx, 100 * _sy)
	_stop_btn.add_theme_font_size_override("font_size", int(28 * _sy))
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

	# Score bar
	_score_bar = ProgressBar.new()
	_score_bar.min_value = 0
	_score_bar.max_value = 100
	_score_bar.value = 0
	_score_bar.custom_minimum_size = Vector2(0, 16 * _sy)
	_score_bar.add_theme_stylebox_override("background", StyleFactory.make_progress_bg())
	_score_bar.add_theme_stylebox_override("fill", StyleFactory.make_progress_fill())
	_score_bar.show_percentage = false
	result_vbox.add_child(_score_bar)

	# Score label
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", int(34 * _sy))
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_score_label)

	# Summary feedback
	_summary_label = Label.new()
	_summary_label.add_theme_font_size_override("font_size", int(24 * _sy))
	_summary_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_summary_label)

	# Detailed feedback (error guidance)
	_detail_label = Label.new()
	_detail_label.add_theme_font_size_override("font_size", int(22 * _sy))
	_detail_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_detail_label)

	# Encouragement
	_encourage_label = Label.new()
	_encourage_label.add_theme_font_size_override("font_size", int(22 * _sy))
	_encourage_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
	_encourage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_encourage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_encourage_label)

	# Teacher flag notice
	_flag_label = Label.new()
	_flag_label.text = "This reading has been saved for your teacher to review."
	_flag_label.add_theme_font_size_override("font_size", int(20 * _sy))
	_flag_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	_flag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flag_label.visible = false
	result_vbox.add_child(_flag_label)

	vbox.add_child(_result_panel)

	# ── Action buttons row (shown after RESULT) ────────────────────────────────
	var action_center := CenterContainer.new()
	action_center.visible = false
	vbox.add_child(action_center)

	var action_hbox := HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", int(12 * _sx))
	action_center.add_child(action_hbox)

	_try_again_btn = Button.new()
	_try_again_btn.text = "Try Again"
	_try_again_btn.custom_minimum_size = Vector2(200 * _sx, 76 * _sy)
	_try_again_btn.add_theme_font_size_override("font_size", int(26 * _sy))
	_try_again_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_try_again_btn.add_theme_stylebox_override("normal", StyleFactory.make_glass_card(10))
	_try_again_btn.add_theme_stylebox_override("hover", StyleFactory.make_glass_card(10))
	_try_again_btn.add_theme_stylebox_override("pressed", StyleFactory.make_glass_card(10))
	_try_again_btn.pressed.connect(_on_try_again_pressed)
	action_hbox.add_child(_try_again_btn)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.custom_minimum_size = Vector2(240 * _sx, 76 * _sy)
	_continue_btn.add_theme_font_size_override("font_size", int(26 * _sy))
	_continue_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_continue_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	_continue_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	_continue_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	_continue_btn.pressed.connect(_on_continue_pressed)
	action_hbox.add_child(_continue_btn)

	# Store reference to action_center so we can show/hide it
	_continue_btn.set_meta("action_center", action_center)

	# ── Decide initial state ───────────────────────────────────────────────────
	if QuestManager.AUTO_PASS_MIC_QUESTS:
		_set_state(State.UNAVAILABLE)
	elif _recognizer.is_available():
		_set_state(State.IDLE)
	else:
		_set_state(State.IDLE)
		_record_btn.disabled = true
		_status_label.text = "Speech recording requires an Android device."
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))


# ── State Machine ─────────────────────────────────────────────────────────────


func _set_state(new_state: State) -> void:
	_state = new_state
	_update_ui_for_state()


func _update_ui_for_state() -> void:
	# Defaults
	_record_btn.visible = false
	_stop_btn.visible = false
	if is_instance_valid(_result_panel):
		_result_panel.visible = false
	_get_action_center().visible = false
	if is_instance_valid(_attempt_label):
		_attempt_label.visible = false
	set_process(false)

	match _state:
		State.IDLE:
			_record_btn.visible = true
			_record_btn.disabled = false
			_status_label.text = "Tap the microphone when ready to read."
			_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
			if _attempt_number > 0:
				_attempt_label.visible = true
				_attempt_label.text = "Attempt %d of %d" % [_attempt_number, MAX_ATTEMPTS]

		State.LISTENING:
			_stop_btn.visible = true
			_status_label.text = "Listening... read aloud now!"
			_status_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
			set_process(true)  # for pulse animation

		State.PROCESSING:
			_status_label.text = "Checking your reading..."
			_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
			set_process(true)  # for spinner animation

		State.RESULT:
			_record_btn.visible = false
			_result_panel.visible = true
			_populate_result_panel(_current_result)
			_get_action_center().visible = true
			# Hide "Try Again" if max attempts reached
			_try_again_btn.visible = (_attempt_number < MAX_ATTEMPTS)

		State.UNAVAILABLE:
			_status_label.text = "Speech recording is not available on this device."
			_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))


func _get_action_center() -> Control:
	if is_instance_valid(_continue_btn):
		return _continue_btn.get_meta("action_center") as Control
	return Control.new()


# ── Process (animations) ──────────────────────────────────────────────────────


func _process(delta: float) -> void:
	match _state:
		State.LISTENING:
			# Pulse status panel modulate
			var t := fmod(Time.get_ticks_msec() / 1000.0, 1.2)
			var alpha := 0.5 + 0.5 * sin(t * TAU / 1.2)
			if is_instance_valid(_status_panel):
				_status_panel.modulate.a = alpha

		State.PROCESSING:
			# Spinner character cycle
			_spinner_elapsed += delta
			if _spinner_elapsed >= SPINNER_INTERVAL:
				_spinner_elapsed = 0.0
				_spinner_idx = (_spinner_idx + 1) % _spinner_chars.size()
				if is_instance_valid(_status_label):
					_status_label.text = _spinner_chars[_spinner_idx] + " Checking your reading..."



# ── Event Handlers ────────────────────────────────────────────────────────────


func _on_record_pressed() -> void:
	_attempt_number += 1
	_update_attempt_label()
	AudioManager.play_sfx("button_tap")
	_set_state(State.LISTENING)
	_recognizer.start_recognition("en-US")
	# Safety net: if recognition never completes within 40s, reset gracefully
	await get_tree().create_timer(40.0).timeout
	if not is_instance_valid(self):
		return
	if _state == State.LISTENING or _state == State.PROCESSING:
		_set_state(State.IDLE)
		if is_instance_valid(_status_label):
			_status_label.text = "Speech recognition timed out. Please try again."
			_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))


func _on_stop_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	_recognizer.stop_recognition()
	_set_state(State.PROCESSING)


func _on_transcript_ready(text: String, confidence: float) -> void:
	_set_state(State.PROCESSING)
	var expected: String = _question.get("word", _question.get("passage", ""))
	var cfg: Dictionary = QuestManager.get_assessment_config()

	if expected.is_empty():
		_current_result = {
			"score": 100,
			"correct": true,
			"flag_review": false,
			"feedback_summary": "Great reading!",
			"feedback_detail": "",
			"feedback_encouragement": "Keep it up!",
		}
	else:
		# Use multi-alternative matching for best accuracy
		var alternatives := _recognizer.get_alternatives()
		if alternatives.size() > 1:
			_current_result = FeedbackEngine.best_match(expected, alternatives, confidence, cfg)
		else:
			_current_result = FeedbackEngine.assess(expected, text, confidence, cfg)

	# Track best score across attempts
	var this_score: int = _current_result.get("score", 0)
	if this_score > _best_score:
		_best_score = this_score
		_best_result = _current_result.duplicate()

	# Audio was already uploaded by /speech/transcribe — use cached URL
	var audio_url := _recognizer.get_audio_url()
	_submit_assessment(_current_result, text, confidence, audio_url)

	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(self):
		return
	_set_state(State.RESULT)

	if _current_result.get("correct", false):
		AudioManager.play_sfx("correct")
		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.08))
	else:
		AudioManager.play_sfx("wrong")


func _on_recognition_error(reason: String) -> void:
	_set_state(State.IDLE)
	_status_label.text = reason
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))


func _on_recognition_unavailable() -> void:
	_set_state(State.IDLE)
	_record_btn.disabled = true
	_status_label.text = "Speech recording is not available on this device."
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))


func _on_try_again_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	if is_instance_valid(_status_panel):
		_status_panel.modulate.a = 1.0
	_set_state(State.IDLE)


func _on_continue_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	# Use best score across all attempts for the final answer
	var correct: bool = _best_result.get("correct", _current_result.get("correct", false))
	answer_submitted.emit(correct)


# ── Result Panel Population ───────────────────────────────────────────────────


func _populate_result_panel(result: Dictionary) -> void:
	var score: int = result.get("score", 0)

	_score_bar.value = score

	# Score label with colour
	_score_label.text = "%d%%" % score
	if score >= 75:
		_score_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
	elif score >= 50:
		_score_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	else:
		_score_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))

	_summary_label.text = result.get("feedback_summary", "")
	_detail_label.text = result.get("feedback_detail", "")
	_encourage_label.text = result.get("feedback_encouragement", "")

	var flag: bool = result.get("flag_review", false)
	_flag_label.visible = flag

	UIAnimations.fade_in_up(self, _result_panel)


# ── Helpers ───────────────────────────────────────────────────────────────────


func _update_attempt_label() -> void:
	if is_instance_valid(_attempt_label):
		_attempt_label.visible = true
		_attempt_label.text = "Attempt %d of %d" % [_attempt_number, MAX_ATTEMPTS]


func _submit_assessment(
	result: Dictionary, transcript: String, confidence: float, audio_url: String = ""
) -> void:
	if not ApiClient.is_authenticated:
		return

	var quest_data := QuestManager.get_current_quest_data()
	var building_id: String = QuestManager.get_current_building_id()
	var stage: String = QuestManager.get_current_stage()
	var quest_id: String = quest_data.get("quest_id", "unknown")
	var expected: String = _question.get("word", _question.get("passage", ""))

	var payload := {
		"questId": quest_id,
		"buildingId": building_id,
		"stage": stage,
		"expectedText": expected,
		"transcript": transcript,
		"confidence": confidence,
		"score": result.get("score", 0),
		"feedback": result.get("feedback_summary", "") + " " + result.get("feedback_detail", ""),
		"errorTypes": result.get("error_types", []),
		"flagReview": result.get("flag_review", false),
		"attemptNumber": _attempt_number,
		"audioUrl": audio_url,
	}

	ApiClient.submit_speech_assessment(
		payload, func(_success: bool, _data: Dictionary) -> void: pass
	)
