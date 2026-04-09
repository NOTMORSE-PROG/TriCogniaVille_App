extends Control
## ReadAloudInteraction — Production read-aloud with backend Whisper assessment.
## States: IDLE → LISTENING → PROCESSING → RESULT (→ retry → IDLE)
##
## Preserves setup() signature and answer_submitted signal so QuestOverlay
## requires zero changes.

signal answer_submitted(correct: bool)

# ── State ─────────────────────────────────────────────────────────────────────

enum State { IDLE, LISTENING, PROCESSING, RESULT }

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
var _controls_center: CenterContainer = null
var _result_panel: PanelContainer = null
var _score_bar: ProgressBar = null
var _score_label: Label = null
var _summary_label: Label = null
var _encourage_label: Label = null
var _playback_btn: Button = null
var _try_again_btn: Button = null
var _action_center: CenterContainer = null
var _attempt_label: Label = null

# Attempt tracking
var _attempt_number := 0
var _best_score := -1
var _best_result: Dictionary = {}

# Spinner animation
var _spinner_chars: Array[String] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
var _spinner_idx := 0
var _spinner_elapsed := 0.0

# Audio + confidence for stats/playback
var _inst_label: Label = null
var _content_card: PanelContainer = null
var _audio_url: String = ""
var _current_confidence: float = 1.0
var _audio_player: AudioStreamPlayer = null

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
	_inst_label = Label.new()
	_inst_label.text = instruction
	_inst_label.add_theme_font_size_override("font_size", int(34 * _sy))
	_inst_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_inst_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inst_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_inst_label)

	# ── Content card ───────────────────────────────────────────────────────────
	_content_card = PanelContainer.new()
	_content_card.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(16))
	_content_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var word: String = _question.get("word", "")
	var passage: String = _question.get("passage", "")

	if not word.is_empty():
		var word_label := Label.new()
		word_label.text = word
		word_label.add_theme_font_size_override("font_size", int(64 * _sy))
		word_label.add_theme_color_override("font_color", StyleFactory.GOLD)
		word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_card.add_child(word_label)
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
		_content_card.add_child(passage_label)

	vbox.add_child(_content_card)

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
	_controls_center = controls_center
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
	result_vbox.add_theme_constant_override("separation", int(10 * _sy))
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

	# Score label (large, colour-coded)
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", int(48 * _sy))
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_score_label)

	# Summary (word count + plain-English verdict)
	_summary_label = Label.new()
	_summary_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_summary_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_summary_label)

	# Encouragement
	_encourage_label = Label.new()
	_encourage_label.add_theme_font_size_override("font_size", int(24 * _sy))
	_encourage_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
	_encourage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_encourage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_encourage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(_encourage_label)

	vbox.add_child(_result_panel)

	# ── Action buttons row (shown after RESULT) ────────────────────────────────
	_action_center = CenterContainer.new()
	_action_center.visible = false
	vbox.add_child(_action_center)

	_try_again_btn = Button.new()
	_try_again_btn.text = "Try Again"
	_try_again_btn.custom_minimum_size = Vector2(240 * _sx, 76 * _sy)
	_try_again_btn.add_theme_font_size_override("font_size", int(26 * _sy))
	_try_again_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_try_again_btn.add_theme_stylebox_override("normal", StyleFactory.make_glass_card(10))
	_try_again_btn.add_theme_stylebox_override("hover", StyleFactory.make_glass_card(10))
	_try_again_btn.add_theme_stylebox_override("pressed", StyleFactory.make_glass_card(10))
	_try_again_btn.pressed.connect(_on_try_again_pressed)
	_action_center.add_child(_try_again_btn)

	# ── Decide initial state ───────────────────────────────────────────────────
	if _recognizer.is_available():
		_set_state(State.IDLE)
		_recognizer.request_permission()
	else:
		_status_label.text = "Microphone not available. Continuing..."
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
		await get_tree().create_timer(3.0).timeout
		if not is_instance_valid(self):
			return
		answer_submitted.emit(true)


# ── State Machine ─────────────────────────────────────────────────────────────


func _set_state(new_state: State) -> void:
	_state = new_state
	_update_ui_for_state()


func _update_ui_for_state() -> void:
	# Defaults — hide everything, show per-state below
	_record_btn.visible = false
	_stop_btn.visible = false
	if is_instance_valid(_result_panel):
		_result_panel.visible = false
	if is_instance_valid(_status_panel):
		_status_panel.visible = false
	if is_instance_valid(_controls_center):
		_controls_center.visible = false
	if is_instance_valid(_action_center):
		_action_center.visible = false
	if is_instance_valid(_inst_label):
		_inst_label.visible = true
	if is_instance_valid(_content_card):
		_content_card.visible = true
	if is_instance_valid(_attempt_label):
		_attempt_label.visible = false
	set_process(false)

	match _state:
		State.IDLE:
			_status_panel.visible = true
			_controls_center.visible = true
			_record_btn.visible = true
			_record_btn.disabled = false
			_status_panel.modulate.a = 1.0
			_status_label.text = "Tap the microphone when ready to read."
			_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
			if _attempt_number > 0:
				_attempt_label.visible = true
				_attempt_label.text = "Attempt %d of %d" % [_attempt_number, MAX_ATTEMPTS]

		State.LISTENING:
			_status_panel.visible = true
			_controls_center.visible = true
			_stop_btn.visible = true
			_status_label.text = "Listening... read aloud now!"
			_status_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
			set_process(true)  # for pulse animation

		State.PROCESSING:
			_status_panel.visible = true
			_status_label.text = "Checking your reading..."
			_status_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
			set_process(true)  # for spinner animation

		State.RESULT:
			if is_instance_valid(_inst_label):
				_inst_label.visible = false
			if is_instance_valid(_content_card):
				_content_card.visible = false
			_result_panel.visible = true
			_populate_result_panel(_current_result)
			if _attempt_number < MAX_ATTEMPTS:
				# Still has tries left — show Try Again
				if is_instance_valid(_action_center):
					_action_center.visible = true
			else:
				# Max attempts reached — auto-submit best result, QuestOverlay shows Next
				var correct: bool = _best_result.get("correct", _current_result.get("correct", false))
				answer_submitted.emit(correct)


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
	_audio_url = _recognizer.get_audio_url()
	_current_confidence = confidence
	# Register URL so QuestManager can clean it up if the quest is abandoned
	QuestManager.register_audio_url(_audio_url)
	_submit_assessment(_current_result, text, confidence, _audio_url)

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
	_status_label.text = "Microphone not available. Continuing..."
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	answer_submitted.emit(true)


func _on_try_again_pressed() -> void:
	AudioManager.play_sfx("button_tap")
	if is_instance_valid(_status_panel):
		_status_panel.modulate.a = 1.0
	_set_state(State.IDLE)


# ── Result Panel Population ───────────────────────────────────────────────────


func _populate_result_panel(result: Dictionary) -> void:
	var score: int = result.get("score", 0)
	var correct_count: int = result.get("correct_count", 0)
	var total_expected: int = result.get("total_expected", 0)
	var error_types: Array = result.get("error_types", [])

	# Score bar
	_score_bar.value = score

	# Score label — large, colour-coded
	_score_label.text = "%d%%" % score
	var score_color: Color
	if score >= 75:
		score_color = StyleFactory.SUCCESS_GREEN
	elif score >= 50:
		score_color = Color(1.0, 0.8, 0.2, 1.0)
	else:
		score_color = Color(0.9, 0.3, 0.3, 1.0)
	_score_label.add_theme_color_override("font_color", score_color)

	# Summary — explicit word count
	if total_expected > 0:
		_summary_label.text = "You read %d out of %d words correctly." % [correct_count, total_expected]
	else:
		_summary_label.text = result.get("feedback_summary", "")

	# Encouragement
	_encourage_label.text = result.get("feedback_encouragement", "")

	# Get the result panel VBox to append dynamic content
	var result_vbox: VBoxContainer = _result_panel.get_child(0) as VBoxContainer

	# Remove any previously added dynamic children (everything after _encourage_label index)
	var encourage_idx: int = _encourage_label.get_index()
	var children_to_remove: Array[Node] = []
	for i in range(encourage_idx + 1, result_vbox.get_child_count()):
		children_to_remove.append(result_vbox.get_child(i))
	for child in children_to_remove:
		child.queue_free()

	# ── Stat cards row ──────────────────────────────────────────────────────────
	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", int(8 * _sx))
	stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_vbox.add_child(stat_row)

	var stat_defs := [
		{"label": "Accuracy", "value": "%d%%" % score, "color": score_color},
		{
			"label": "Words",
			"value": "%d/%d" % [correct_count, total_expected] if total_expected > 0 else "—",
			"color": StyleFactory.TEXT_PRIMARY
		},
		{
			"label": "Clarity",
			"value": "High" if _current_confidence >= 0.8 else ("Good" if _current_confidence >= 0.5 else "Low"),
			"color": StyleFactory.SUCCESS_GREEN if _current_confidence >= 0.8 else (Color(1.0, 0.8, 0.2, 1.0) if _current_confidence >= 0.5 else Color(0.9, 0.3, 0.3, 1.0))
		},
	]
	for sd in stat_defs:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 8, 1))
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", int(2 * _sy))
		card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(card_vbox)
		var val_lbl := Label.new()
		val_lbl.text = sd["value"]
		val_lbl.add_theme_font_size_override("font_size", int(26 * _sy))
		val_lbl.add_theme_color_override("font_color", sd["color"])
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(val_lbl)
		var key_lbl := Label.new()
		key_lbl.text = sd["label"]
		key_lbl.add_theme_font_size_override("font_size", int(18 * _sy))
		key_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(key_lbl)
		stat_row.add_child(card)

	# ── Voice playback button ───────────────────────────────────────────────────
	if not _audio_url.is_empty():
		var pb_center := CenterContainer.new()
		pb_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_vbox.add_child(pb_center)
		_playback_btn = Button.new()
		_playback_btn.text = "▶  Play My Recording"
		_playback_btn.custom_minimum_size = Vector2(300 * _sx, 64 * _sy)
		_playback_btn.add_theme_font_size_override("font_size", int(24 * _sy))
		_playback_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		_playback_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
		_playback_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
		_playback_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
		_playback_btn.pressed.connect(_on_play_recording_pressed)
		pb_center.add_child(_playback_btn)

	# ── Dynamic error detail ────────────────────────────────────────────────────
	if not error_types.is_empty():
		var first_error: String = error_types[0]
		match first_error:
			"omission":
				var missed: Array = result.get("missed_words", [])
				if missed.size() > 0:
					var missed_lbl := Label.new()
					missed_lbl.text = "Words you missed:"
					missed_lbl.add_theme_font_size_override("font_size", int(22 * _sy))
					missed_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
					missed_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					missed_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
					result_vbox.add_child(missed_lbl)
					var chip_row := HBoxContainer.new()
					chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
					chip_row.add_theme_constant_override("separation", int(6 * _sx))
					chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
					result_vbox.add_child(chip_row)
					for w in missed.slice(0, mini(4, missed.size())):
						var chip := PanelContainer.new()
						var chip_style := StyleBoxFlat.new()
						chip_style.bg_color = Color(0.9, 0.3, 0.3, 0.25)
						chip_style.corner_radius_top_left = 6
						chip_style.corner_radius_top_right = 6
						chip_style.corner_radius_bottom_left = 6
						chip_style.corner_radius_bottom_right = 6
						chip_style.border_width_top = 1
						chip_style.border_width_bottom = 1
						chip_style.border_width_left = 1
						chip_style.border_width_right = 1
						chip_style.border_color = Color(0.9, 0.3, 0.3, 0.7)
						chip_style.content_margin_left = int(10 * _sx)
						chip_style.content_margin_right = int(10 * _sx)
						chip_style.content_margin_top = int(4 * _sy)
						chip_style.content_margin_bottom = int(4 * _sy)
						chip.add_theme_stylebox_override("panel", chip_style)
						chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
						var wl := Label.new()
						wl.text = str(w)
						wl.add_theme_font_size_override("font_size", int(22 * _sy))
						wl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
						wl.mouse_filter = Control.MOUSE_FILTER_IGNORE
						chip.add_child(wl)
						chip_row.add_child(chip)

			"substitution":
				var subs: Array = result.get("substitutions", [])
				if subs.size() > 0:
					var sub_lbl := Label.new()
					sub_lbl.text = "Word corrections:"
					sub_lbl.add_theme_font_size_override("font_size", int(22 * _sy))
					sub_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
					sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
					result_vbox.add_child(sub_lbl)
					for i in range(mini(3, subs.size())):
						var sub: Dictionary = subs[i]
						var row_lbl := Label.new()
						row_lbl.text = 'You said "%s"  →  correct: "%s"' % [sub.get("said", ""), sub.get("correct", "")]
						row_lbl.add_theme_font_size_override("font_size", int(22 * _sy))
						row_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
						row_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
						row_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
						row_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
						result_vbox.add_child(row_lbl)

			"phonetic":
				var phonetic_words: Array = result.get("phonetic_words", [])
				var ph_lbl := Label.new()
				ph_lbl.text = (
					"Almost there! Practise: " + ", ".join(phonetic_words.slice(0, mini(3, phonetic_words.size())))
					if phonetic_words.size() > 0
					else "Almost! Try pronouncing each word a little more clearly."
				)
				ph_lbl.add_theme_font_size_override("font_size", int(22 * _sy))
				ph_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
				ph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				ph_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				ph_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				result_vbox.add_child(ph_lbl)

			"addition":
				var add_lbl := Label.new()
				add_lbl.text = "Read only the words shown — don't add extra words."
				add_lbl.add_theme_font_size_override("font_size", int(22 * _sy))
				add_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
				add_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				add_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				add_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				result_vbox.add_child(add_lbl)
	elif score < 90:
		var tip_lbl := Label.new()
		tip_lbl.text = "Almost perfect! Speak each word a little more clearly."
		tip_lbl.add_theme_font_size_override("font_size", int(22 * _sy))
		tip_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
		tip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tip_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_vbox.add_child(tip_lbl)

	UIAnimations.fade_in_up(self, _result_panel)

	# Scroll to show the result panel
	await get_tree().process_frame
	var n: Node = self
	while n:
		if n is ScrollContainer:
			(n as ScrollContainer).ensure_control_visible(_result_panel)
			break
		n = n.get_parent()


# ── Voice Playback ────────────────────────────────────────────────────────────


func _on_play_recording_pressed() -> void:
	if _audio_url.is_empty() or not is_instance_valid(_playback_btn):
		return
	_playback_btn.text = "Loading..."
	_playback_btn.disabled = true
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_audio_fetched.bind(http), CONNECT_ONE_SHOT)
	http.request(_audio_url)


func _on_audio_fetched(
	res: int, _code: int, _hdrs: PackedStringArray, body: PackedByteArray, http: HTTPRequest
) -> void:
	http.queue_free()
	if not is_instance_valid(_playback_btn):
		return
	if res != HTTPRequest.RESULT_SUCCESS or body.is_empty():
		_playback_btn.text = "▶  Play My Recording"
		_playback_btn.disabled = false
		return
	var mp3 := AudioStreamMP3.new()
	mp3.data = body
	if not is_instance_valid(_audio_player):
		_audio_player = AudioStreamPlayer.new()
		add_child(_audio_player)
	_audio_player.stream = mp3
	_audio_player.play()
	_playback_btn.text = "Playing..."
	_audio_player.finished.connect(
		func() -> void:
			if is_instance_valid(_playback_btn):
				_playback_btn.text = "▶  Play My Recording"
				_playback_btn.disabled = false,
		CONNECT_ONE_SHOT
	)


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
