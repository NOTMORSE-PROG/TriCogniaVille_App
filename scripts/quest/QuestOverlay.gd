extends Control
## QuestOverlay — Full-screen quest UI overlay on the village map.
## Manages 3-stage flow: Tutorial → Practice → Mission → Results.
## Blocks all input below via MOUSE_FILTER_STOP.

var _tutorial_demo_shown: bool = false
var _sx: float = 1.0
var _sy: float = 1.0
var _transitioning: bool = false

# UI containers
var _bg: ColorRect
var _header_container: VBoxContainer
var _stage_dots: Array[Panel] = []
var _question_container: VBoxContainer
var _question_scroll: ScrollContainer
var _interaction_node: Control
var _bottom_bar: HBoxContainer
var _next_btn: Button
var _counter_label: Label
var _close_btn: Button
var _building_label: Label
var _topic_label: Label
var _stage_label: Label

# Stage banner
var _stage_banner: PanelContainer
var _stage_banner_label: Label
var _stage_banner_desc: Label
var _stage_banner_icon: Label

# Mission progress
var _progress_container: HBoxContainer
var _mission_progress_bar: ProgressBar
var _running_score_label: Label

# Hint system
var _hint_manager: HintManager
var _hint_nudge_label: Label

# Result UI
var _result_container: VBoxContainer


func setup(sx: float, sy: float) -> void:
	_sx = sx
	_sy = sy
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_layout()
	_connect_quest_signals()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(false)


func _process(delta: float) -> void:
	if _hint_manager != null:
		_hint_manager.update(delta)


func _connect_quest_signals() -> void:
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_stage_changed.connect(_on_stage_changed)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_abandoned.connect(_on_quest_abandoned)


# ═════════════════════════════════════════════════════════════════════════════
# LAYOUT
# ═════════════════════════════════════════════════════════════════════════════


func _build_layout() -> void:
	# Dark overlay background
	_bg = ColorRect.new()
	_bg.color = Color(StyleFactory.BG_DEEP.r, StyleFactory.BG_DEEP.g, StyleFactory.BG_DEEP.b, 0.88)
	_bg.anchor_right = 1.0
	_bg.anchor_bottom = 1.0
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	# Main VBox filling the screen with margins
	# Centered card: 80% of screen width, fills screen height with padding
	var margin := MarginContainer.new()
	margin.anchor_left = 0.1
	margin.anchor_right = 0.9
	margin.anchor_top = 0.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 0.0
	margin.offset_right = 0.0
	margin.offset_top = 24 * _sy
	margin.offset_bottom = -24 * _sy
	margin.add_theme_constant_override("margin_left", int(24 * _sx))
	margin.add_theme_constant_override("margin_right", int(24 * _sx))
	margin.add_theme_constant_override("margin_top", int(20 * _sy))
	margin.add_theme_constant_override("margin_bottom", int(20 * _sy))
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", int(12 * _sy))
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(main_vbox)

	# ── Header ──
	var header_hbox := HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(header_hbox)

	_header_container = VBoxContainer.new()
	_header_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_container.add_theme_constant_override("separation", int(2 * _sy))
	_header_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_child(_header_container)

	_building_label = Label.new()
	_building_label.add_theme_font_size_override("font_size", int(44 * _sy))
	_building_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_building_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_container.add_child(_building_label)

	var sub_hbox := HBoxContainer.new()
	sub_hbox.add_theme_constant_override("separation", int(12 * _sx))
	sub_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_container.add_child(sub_hbox)

	_topic_label = Label.new()
	_topic_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_topic_label.add_theme_color_override("font_color", StyleFactory.GOLD)
	_topic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_hbox.add_child(_topic_label)

	_stage_label = Label.new()
	_stage_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_stage_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_stage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_hbox.add_child(_stage_label)

	# Stage dots
	var dots_container := HBoxContainer.new()
	dots_container.add_theme_constant_override("separation", int(6 * _sx))
	dots_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_hbox.add_child(dots_container)

	_stage_dots = []
	for i in 3:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(26 * _sx, 14 * _sy)
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = StyleFactory.PIN_EMPTY
		dot_style.corner_radius_top_left = 4
		dot_style.corner_radius_top_right = 4
		dot_style.corner_radius_bottom_left = 4
		dot_style.corner_radius_bottom_right = 4
		dot_style.anti_aliasing = true
		dot.add_theme_stylebox_override("panel", dot_style)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots_container.add_child(dot)
		_stage_dots.append(dot)

	# Close button
	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(68 * _sx, 68 * _sy)
	_close_btn.add_theme_font_size_override("font_size", int(28 * _sy))
	_close_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_close_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	_close_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	_close_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	_close_btn.pressed.connect(_on_close_pressed)
	header_hbox.add_child(_close_btn)

	# ── Stage Banner ──
	_stage_banner = PanelContainer.new()
	_stage_banner.custom_minimum_size = Vector2(0, 74 * _sy)
	_stage_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = StyleFactory.STAGE_TUTORIAL_BG
	banner_style.corner_radius_top_left = int(10 * _sx)
	banner_style.corner_radius_top_right = int(10 * _sx)
	banner_style.corner_radius_bottom_left = int(10 * _sx)
	banner_style.corner_radius_bottom_right = int(10 * _sx)
	banner_style.border_width_top = 2
	banner_style.border_width_bottom = 2
	banner_style.border_color = StyleFactory.STAGE_TUTORIAL_ACCENT
	banner_style.content_margin_left = int(16 * _sx)
	banner_style.content_margin_right = int(16 * _sx)
	banner_style.content_margin_top = int(6 * _sy)
	banner_style.content_margin_bottom = int(6 * _sy)
	_stage_banner.add_theme_stylebox_override("panel", banner_style)
	main_vbox.add_child(_stage_banner)

	var banner_hbox := HBoxContainer.new()
	banner_hbox.add_theme_constant_override("separation", int(12 * _sx))
	banner_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_banner.add_child(banner_hbox)

	_stage_banner_icon = Label.new()
	_stage_banner_icon.text = "LEARN"
	_stage_banner_icon.add_theme_font_size_override("font_size", int(22 * _sy))
	_stage_banner_icon.add_theme_color_override("font_color", StyleFactory.STAGE_TUTORIAL_ACCENT)
	_stage_banner_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_hbox.add_child(_stage_banner_icon)

	_stage_banner_label = Label.new()
	_stage_banner_label.text = "TUTORIAL MODE"
	_stage_banner_label.add_theme_font_size_override("font_size", int(32 * _sy))
	_stage_banner_label.add_theme_color_override("font_color", Color.WHITE)
	_stage_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_hbox.add_child(_stage_banner_label)

	_stage_banner_desc = Label.new()
	_stage_banner_desc.text = "Guided learning — no score"
	_stage_banner_desc.add_theme_font_size_override("font_size", int(22 * _sy))
	_stage_banner_desc.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_stage_banner_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_hbox.add_child(_stage_banner_desc)

	# ── Mission Progress Bar ──
	_progress_container = HBoxContainer.new()
	_progress_container.add_theme_constant_override("separation", int(12 * _sx))
	_progress_container.visible = false
	_progress_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(_progress_container)

	_mission_progress_bar = ProgressBar.new()
	_mission_progress_bar.min_value = 0.0
	_mission_progress_bar.max_value = 10.0
	_mission_progress_bar.value = 0.0
	_mission_progress_bar.custom_minimum_size = Vector2(0, 16 * _sy)
	_mission_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_progress_bar.add_theme_stylebox_override("background", StyleFactory.make_progress_bg())
	var progress_fill := StyleFactory.make_progress_fill()
	progress_fill.bg_color = StyleFactory.SUCCESS_GREEN
	_mission_progress_bar.add_theme_stylebox_override("fill", progress_fill)
	_mission_progress_bar.show_percentage = false
	_progress_container.add_child(_mission_progress_bar)

	_running_score_label = Label.new()
	_running_score_label.text = "Score: 0 / 0"
	_running_score_label.add_theme_font_size_override("font_size", int(20 * _sy))
	_running_score_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
	_running_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_container.add_child(_running_score_label)

	# ── Content area ──
	_question_scroll = ScrollContainer.new()
	var scroll := _question_scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	main_vbox.add_child(scroll)

	_question_container = VBoxContainer.new()
	_question_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_question_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_question_container)

	# ── Hint nudge label ──
	_hint_nudge_label = Label.new()
	_hint_nudge_label.text = ""
	_hint_nudge_label.visible = false
	_hint_nudge_label.add_theme_font_size_override("font_size", int(22 * _sy))
	_hint_nudge_label.add_theme_color_override("font_color", StyleFactory.SKY_BLUE)
	_hint_nudge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_nudge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_nudge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(_hint_nudge_label)

	# ── Bottom bar ──
	_bottom_bar = HBoxContainer.new()
	_bottom_bar.add_theme_constant_override("separation", int(12 * _sx))
	_bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(_bottom_bar)

	_counter_label = Label.new()
	_counter_label.add_theme_font_size_override("font_size", int(22 * _sy))
	_counter_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_counter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_bar.add_child(_counter_label)

	_next_btn = Button.new()
	_next_btn.text = "Next"
	_next_btn.visible = false
	_next_btn.custom_minimum_size = Vector2(220 * _sx, 76 * _sy)
	_next_btn.add_theme_font_size_override("font_size", int(28 * _sy))
	_next_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_next_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	_next_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	_next_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	_next_btn.pressed.connect(_on_next_pressed)
	_bottom_bar.add_child(_next_btn)

	_next_btn.ready.connect(func() -> void: UIAnimations.make_interactive(_next_btn))

	# Result container (hidden)
	_result_container = VBoxContainer.new()
	_result_container.visible = false
	_result_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_result_container)


# ═════════════════════════════════════════════════════════════════════════════
# QUEST SIGNAL HANDLERS
# ═════════════════════════════════════════════════════════════════════════════


func _on_quest_started(building_id: String) -> void:
	var quest := QuestManager.get_current_quest_data()
	_building_label.text = QuestData.get_building_label(building_id)
	_topic_label.text = quest.get("topic", "")
	# Defensive resets — state may be dirty from a previously abandoned quest
	_transitioning = false
	_clear_question_container()
	if is_instance_valid(_question_scroll):
		_question_scroll.visible = true
	if is_instance_valid(_bottom_bar):
		_bottom_bar.visible = true
	_set_tracker_visible(false)
	visible = true
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)


func _on_stage_changed(stage: String) -> void:
	_tutorial_demo_shown = false
	_update_stage_dots(stage)
	_update_stage_banner(stage)
	match stage:
		"tutorial":
			_stage_label.text = "Tutorial"
		"practice":
			_stage_label.text = "Practice"
		"mission":
			_stage_label.text = "Mission"

	# Show progress bar only during mission
	_progress_container.visible = (stage == "mission")
	if stage == "mission":
		var questions := QuestManager.get_current_questions()
		_mission_progress_bar.max_value = float(questions.size())
		_mission_progress_bar.value = 0.0
		_running_score_label.text = "Score: 0 / %d" % questions.size()

	_load_current_question()


func _on_quest_completed(building_id: String, passed: bool, score: int) -> void:
	_show_result(building_id, passed, score)


func _on_quest_abandoned(_building_id: String) -> void:
	_hide_overlay()


# ═════════════════════════════════════════════════════════════════════════════
# QUESTION LOADING
# ═════════════════════════════════════════════════════════════════════════════


func _load_current_question() -> void:
	if _transitioning:
		return

	var questions := QuestManager.get_current_questions()
	var idx := QuestManager.get_current_question_index()

	if idx >= questions.size():
		# No more questions in this stage
		if QuestManager.get_current_stage() == "mission":
			QuestManager.advance_stage()  # triggers finish
		else:
			QuestManager.advance_stage()
		return

	var question: Dictionary = _personalize_quest_data(questions[idx])
	var stage := QuestManager.get_current_stage()
	var show_hints := stage == "practice" or stage == "tutorial"

	# For tutorial stage, show guided demo first (only once per question)
	if stage == "tutorial" and not _tutorial_demo_shown:
		_show_tutorial_demo(question)
		return

	# Update counter
	if stage == "mission":
		_counter_label.text = "Question %d of %d" % [idx + 1, questions.size()]
	else:
		_counter_label.text = "%s %d of %d" % [stage.capitalize(), idx + 1, questions.size()]

	# Clear old interaction — remove all children immediately to prevent stacking
	_transitioning = true
	_clear_question_container()

	_next_btn.visible = false

	# Create new interaction based on type
	var qtype: String = question.get("type", "mcq")
	match qtype:
		"mcq":
			var mcq_script := load("res://scripts/quest/interactions/MCQInteraction.gd")
			if mcq_script == null:
				push_error("[QuestOverlay] Failed to load MCQInteraction script")
				_transitioning = false
				return
			var mcq: Node = mcq_script.new()
			_question_container.add_child(mcq)
			mcq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mcq.size_flags_vertical = Control.SIZE_EXPAND_FILL
			mcq.setup(question, show_hints, _sx, _sy)
			mcq.answer_submitted.connect(_on_answer_submitted)
			_interaction_node = mcq
		"tap_target":
			var tap_script := load("res://scripts/quest/interactions/TapTargetInteraction.gd")
			if tap_script == null:
				push_error("[QuestOverlay] Failed to load TapTargetInteraction script")
				_transitioning = false
				return
			var tap: Node = tap_script.new()
			_question_container.add_child(tap)
			tap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tap.size_flags_vertical = Control.SIZE_EXPAND_FILL
			tap.setup(question, show_hints, _sx, _sy)
			tap.answer_submitted.connect(_on_answer_submitted)
			_interaction_node = tap
		"drag_drop":
			var dd_script := load("res://scripts/quest/interactions/DragDropInteraction.gd")
			if dd_script == null:
				push_error("[QuestOverlay] Failed to load DragDropInteraction script")
				_transitioning = false
				return
			var dd: Node = dd_script.new()
			_question_container.add_child(dd)
			dd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dd.size_flags_vertical = Control.SIZE_EXPAND_FILL
			dd.setup(question, show_hints, _sx, _sy)
			dd.answer_submitted.connect(_on_answer_submitted)
			_interaction_node = dd
		"read_aloud":
			var ra_script := load("res://scripts/quest/interactions/ReadAloudInteraction.gd")
			if ra_script == null:
				push_error("[QuestOverlay] Failed to load ReadAloudInteraction script")
				_transitioning = false
				return
			var ra: Node = ra_script.new()
			_question_container.add_child(ra)
			ra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ra.size_flags_vertical = Control.SIZE_EXPAND_FILL
			ra.setup(question, show_hints, _sx, _sy)
			ra.answer_submitted.connect(_on_answer_submitted)
			_interaction_node = ra
		"fluency_check":
			var fl_script := load("res://scripts/quest/interactions/FluencyInteraction.gd")
			if fl_script == null:
				push_error("[QuestOverlay] Failed to load FluencyInteraction script")
				_transitioning = false
				return
			var fl: Node = fl_script.new()
			_question_container.add_child(fl)
			fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fl.size_flags_vertical = Control.SIZE_EXPAND_FILL
			fl.setup(question, show_hints, _sx, _sy)
			fl.answer_submitted.connect(_on_answer_submitted)
			fl.fluency_score_submitted.connect(
				func(score: int) -> void: QuestManager.submit_fluency_score(score)
			)
			_interaction_node = fl
		"punctuation_read":
			var pr_script := load(
				"res://scripts/quest/interactions/PunctuationReadInteraction.gd"
			)
			if pr_script == null:
				push_error("[QuestOverlay] Failed to load PunctuationReadInteraction script")
				_transitioning = false
				return
			var pr: Node = pr_script.new()
			_question_container.add_child(pr)
			pr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pr.size_flags_vertical = Control.SIZE_EXPAND_FILL
			pr.setup(question, show_hints, _sx, _sy)
			pr.answer_submitted.connect(_on_answer_submitted)
			_interaction_node = pr

	if is_instance_valid(_interaction_node):
		UIAnimations.fade_in_up(self, _interaction_node)

	# Start hint tracking for mission mode
	_hint_nudge_label.visible = false
	_hint_nudge_label.text = ""
	if stage == "mission":
		_hint_manager = HintManager.new()
		_hint_manager.hint_triggered.connect(_on_hint_triggered)
		_hint_manager.start_tracking()
		set_process(true)
	else:
		_hint_manager = null
		set_process(false)

	_transitioning = false


func _on_hint_triggered(level: int) -> void:
	match level:
		0:
			# Gentle nudge
			_hint_nudge_label.text = "Take your time! Read the question carefully."
			_hint_nudge_label.visible = true
			_hint_nudge_label.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(_hint_nudge_label, "modulate:a", 1.0, 0.3)
		1:
			# Eliminate one wrong answer — delegate to interaction
			_hint_nudge_label.text = "Here's a hint to help you..."
			if is_instance_valid(_interaction_node) and _interaction_node.has_method("apply_hint"):
				_interaction_node.apply_hint(1)
		2:
			# Stronger hint — delegate to interaction
			_hint_nudge_label.text = "One more hint — look closely!"
			if is_instance_valid(_interaction_node) and _interaction_node.has_method("apply_hint"):
				_interaction_node.apply_hint(2)


func _on_answer_submitted(correct: bool) -> void:
	# Stop hint tracking (hints are shown automatically on inactivity, not counted)
	if _hint_manager != null:
		_hint_manager.stop_tracking()
		set_process(false)
	_hint_nudge_label.visible = false

	QuestManager.submit_answer(correct)

	# Update mission progress bar
	if correct and QuestManager.get_current_stage() == "mission":
		var total := QuestManager.get_mission_total()
		var score := QuestManager.get_mission_score()
		_mission_progress_bar.value = float(total)
		var total_q: int = QuestManager.get_current_questions().size()
		_running_score_label.text = "Score: %d / %d" % [score, total_q]
		if score > 0:
			_running_score_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
		# Tween the progress bar
		var tw := create_tween()
		(
			tw
			. tween_property(_mission_progress_bar, "value", float(total), 0.3)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
		)

	_next_btn.visible = false

	if correct:
		# Show Next button after a short delay
		var timer := get_tree().create_timer(1.2)
		timer.timeout.connect(
			func() -> void:
				if not is_instance_valid(_next_btn):
					return
				var questions := QuestManager.get_current_questions()
				var idx := QuestManager.get_current_question_index()
				var stage := QuestManager.get_current_stage()

				if idx + 1 >= questions.size():
					if stage == "mission":
						_next_btn.text = "See Results"
					else:
						_next_btn.text = "Next Stage"
				else:
					_next_btn.text = "Next"
				_next_btn.visible = true
				UIAnimations.fade_in_up(self, _next_btn)
		)
	else:
		# Wrong answer — still allow player to proceed after feedback delay
		var timer := get_tree().create_timer(1.5)
		timer.timeout.connect(
			func() -> void:
				if not is_instance_valid(_next_btn):
					return
				var questions := QuestManager.get_current_questions()
				var idx := QuestManager.get_current_question_index()
				var stage := QuestManager.get_current_stage()

				if idx + 1 >= questions.size():
					if stage == "mission":
						_next_btn.text = "See Results"
					else:
						_next_btn.text = "Next Stage"
				else:
					_next_btn.text = "Next"
				_next_btn.visible = true
				UIAnimations.fade_in_up(self, _next_btn)
		)


func _on_next_pressed() -> void:
	if _transitioning:
		return
	var has_more := QuestManager.advance_question()
	if has_more:
		_load_current_question()
	else:
		# End of stage
		var stage := QuestManager.get_current_stage()
		if stage == "mission":
			QuestManager.advance_stage()  # triggers finish
		elif stage == "practice":
			# End of guided portion — ask the player before entering the graded mission
			_show_post_tutorial_modal()
		else:
			QuestManager.advance_stage()


func _show_post_tutorial_modal() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var card := PanelContainer.new()
	var card_style := StyleFactory.make_glass_card(16)
	card_style.border_width_top = 4
	card_style.border_color = StyleFactory.SUCCESS_GREEN
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(640 * _sx, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", int(40 * _sx))
	card_margin.add_theme_constant_override("margin_right", int(40 * _sx))
	card_margin.add_theme_constant_override("margin_top", int(36 * _sy))
	card_margin.add_theme_constant_override("margin_bottom", int(36 * _sy))
	card.add_child(card_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(20 * _sy))
	card_margin.add_child(vbox)

	var title := Label.new()
	title.text = "Tutorial Complete!"
	title.add_theme_font_size_override("font_size", int(48 * _sy))
	title.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "Ready to take on the main challenge?"
	desc.add_theme_font_size_override("font_size", int(32 * _sy))
	desc.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var btn_row := VBoxContainer.new()
	btn_row.add_theme_constant_override("separation", int(14 * _sy))
	vbox.add_child(btn_row)

	var continue_btn := Button.new()
	continue_btn.text = "Start the Challenge"
	continue_btn.custom_minimum_size = Vector2(520 * _sx, 96 * _sy)
	continue_btn.add_theme_font_size_override("font_size", int(36 * _sy))
	continue_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	continue_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	continue_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	continue_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	btn_row.add_child(continue_btn)

	var back_btn := Button.new()
	back_btn.text = "Go Back"
	back_btn.custom_minimum_size = Vector2(520 * _sx, 84 * _sy)
	back_btn.add_theme_font_size_override("font_size", int(30 * _sy))
	back_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	back_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	back_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	back_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	btn_row.add_child(back_btn)

	UIAnimations.panel_in(self, card)

	continue_btn.pressed.connect(
		func() -> void:
			AudioManager.play_sfx("button_tap")
			dim.queue_free()
			center.queue_free()
			# Advance through any empty intermediate stages until we reach mission
			QuestManager.advance_stage()
			while (
				QuestManager.get_current_stage() != "mission"
				and QuestManager.get_current_stage() != ""
				and QuestManager.get_current_questions().is_empty()
			):
				QuestManager.advance_stage()
	)

	back_btn.pressed.connect(
		func() -> void:
			AudioManager.play_sfx("button_tap")
			dim.queue_free()
			center.queue_free()
			QuestManager.abandon_quest()
	)


func _reload_current_question() -> void:
	# Reset hint manager for the retry attempt
	if _hint_manager != null:
		_hint_manager.reset()
	_hint_nudge_label.visible = false
	# Reload the same question (no advance_question call)
	_load_current_question()


func _on_close_pressed() -> void:
	QuestManager.abandon_quest()


# ═════════════════════════════════════════════════════════════════════════════
# RESULTS
# ═════════════════════════════════════════════════════════════════════════════


func _show_result(_building_id: String, passed: bool, score: int) -> void:
	if passed:
		AudioManager.play_sfx("quest_pass")
	else:
		AudioManager.play_sfx("quest_fail")

	# Hide progress bar and hints
	_progress_container.visible = false
	_hint_nudge_label.visible = false
	set_process(false)

	# Clear question area
	_clear_question_container()

	_next_btn.visible = false
	_counter_label.text = ""

	var total := QuestManager.get_mission_total()
	var question_results := QuestManager.get_question_results()

	# Build result UI in question container
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", int(12 * _sy))
	_question_container.add_child(vbox)
	_interaction_node = vbox  # for cleanup

	# ── Score Header ──
	var header_card := PanelContainer.new()
	header_card.add_theme_stylebox_override(
		"panel", StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 16, 2)
	)
	header_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header_card)

	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", int(8 * _sy))
	header_card.add_child(header_vbox)

	# Title
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(26 * _sy))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_vbox.add_child(title)

	# Score display
	var score_label := Label.new()
	score_label.text = "%d / %d" % [score, total]
	score_label.add_theme_font_size_override("font_size", int(36 * _sy))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_vbox.add_child(score_label)

	# Personalized message
	var message := Label.new()
	message.add_theme_font_size_override("font_size", int(15 * _sy))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_vbox.add_child(message)

	if passed:
		title.text = "Quest Complete!"
		title.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
		score_label.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)

		if score >= total:
			message.text = "Perfect score! You're a reading champion!"
		elif score >= total - 1:
			message.text = "Excellent work! Almost perfect!"
		else:
			message.text = "You passed! Well done!"
		message.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)

		var xp: int = QuestManager.get_last_xp_reward()
		var xp_label := Label.new()
		xp_label.text = "+%d XP" % xp
		xp_label.add_theme_font_size_override("font_size", int(22 * _sy))
		xp_label.add_theme_color_override("font_color", StyleFactory.GOLD)
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_vbox.add_child(xp_label)

		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.12))
		UIAnimations.elastic_reveal(self, header_card)
	else:
		title.text = "Keep Trying!"
		title.add_theme_color_override("font_color", StyleFactory.TEXT_ERROR)
		score_label.add_theme_color_override("font_color", StyleFactory.TEXT_ERROR)

		if score >= total - 3:
			message.text = "Almost there! You need 7 correct to pass."
		elif score >= int(total / 2.0):
			message.text = "Good effort! Review the questions and try again."
		else:
			message.text = "Keep practicing — you'll get it!"
		message.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)

		UIAnimations.fade_in_up(self, header_card)

	# ── Story: Lumi encouragement on fail ──
	if not passed:
		var fail_outro := StoryManager.get_outro(_building_id, false)
		if fail_outro.size() > 0:
			var lumi_card := PanelContainer.new()
			var lumi_style := StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 12, 1)
			lumi_style.border_width_left = 3
			lumi_style.border_color = StyleFactory.SUCCESS_GREEN
			lumi_card.add_theme_stylebox_override("panel", lumi_style)
			lumi_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(lumi_card)

			var lumi_hbox := HBoxContainer.new()
			lumi_hbox.add_theme_constant_override("separation", int(10 * _sx))
			lumi_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lumi_card.add_child(lumi_hbox)

			var lumi_icon := Label.new()
			lumi_icon.text = "\u2726"
			lumi_icon.add_theme_font_size_override("font_size", int(16 * _sy))
			lumi_icon.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
			lumi_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lumi_hbox.add_child(lumi_icon)

			var lumi_text := Label.new()
			lumi_text.text = fail_outro[0].get("text", "")
			lumi_text.add_theme_font_size_override("font_size", int(14 * _sy))
			lumi_text.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
			lumi_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lumi_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lumi_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lumi_hbox.add_child(lumi_text)

			UIAnimations.fade_in_up(self, lumi_card, 0.3)

	# ── Question Breakdown ──
	if question_results.size() > 0:
		var breakdown_label := Label.new()
		breakdown_label.text = "Question Breakdown"
		breakdown_label.add_theme_font_size_override("font_size", int(16 * _sy))
		breakdown_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
		breakdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(breakdown_label)

		for i in question_results.size():
			var result: Dictionary = question_results[i]
			var correct: bool = result.get("correct", false)
			var q: Dictionary = result.get("question", {})

			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", int(8 * _sx))
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(row)

			# Status icon
			var icon := Label.new()
			icon.text = "+" if correct else "x"
			icon.add_theme_font_size_override("font_size", int(16 * _sy))
			icon.add_theme_color_override(
				"font_color", StyleFactory.SUCCESS_GREEN if correct else StyleFactory.TEXT_ERROR
			)
			icon.custom_minimum_size = Vector2(24 * _sx, 0)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)

			# Question number
			var num := Label.new()
			num.text = "Q%d" % (i + 1)
			num.add_theme_font_size_override("font_size", int(13 * _sy))
			num.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
			num.custom_minimum_size = Vector2(32 * _sx, 0)
			num.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(num)

			# Question preview
			var preview := Label.new()
			var q_text: String = q.get("question", q.get("instruction", q.get("word", "")))
			if q_text.length() > 50:
				q_text = q_text.substr(0, 47) + "..."
			preview.text = q_text
			preview.add_theme_font_size_override("font_size", int(13 * _sy))
			preview.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
			preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			preview.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(preview)

	# ── Reflection Panel (dynamic strength/growth — inn + chapel only) ──
	var quest_data := QuestManager.get_current_quest_data()
	var quest_id: String = quest_data.get("quest_id", "")
	if quest_id in ["week3_punctuation", "week4_fluency"] and question_results.size() > 0:
		var reflection := ReflectionEngine.generate_reflection(quest_id, question_results)
		var strength: String = reflection.get("strength", "")
		var growth: String = reflection.get("growth", "")

		if not strength.is_empty() or not growth.is_empty():
			var ref_card := PanelContainer.new()
			var ref_style := StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 14, 1)
			ref_style.border_width_left = 3
			ref_style.border_color = StyleFactory.GOLD
			ref_card.add_theme_stylebox_override("panel", ref_style)
			ref_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(ref_card)

			var ref_vbox := VBoxContainer.new()
			ref_vbox.add_theme_constant_override("separation", int(6 * _sy))
			ref_card.add_child(ref_vbox)

			var ref_title := Label.new()
			ref_title.text = "\u2728 Your Reflection"
			ref_title.add_theme_font_size_override("font_size", int(16 * _sy))
			ref_title.add_theme_color_override("font_color", StyleFactory.GOLD)
			ref_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ref_vbox.add_child(ref_title)

			if not strength.is_empty():
				var s_row := HBoxContainer.new()
				s_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
				ref_vbox.add_child(s_row)
				var s_icon := Label.new()
				s_icon.text = "\u2b50"
				s_icon.add_theme_font_size_override("font_size", int(16 * _sy))
				s_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				s_row.add_child(s_icon)
				var s_lbl := Label.new()
				s_lbl.text = strength
				s_lbl.add_theme_font_size_override("font_size", int(15 * _sy))
				s_lbl.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
				s_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				s_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				s_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				s_row.add_child(s_lbl)

			if not growth.is_empty():
				var g_row := HBoxContainer.new()
				g_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
				ref_vbox.add_child(g_row)
				var g_icon := Label.new()
				g_icon.text = "\U0001f331"
				g_icon.add_theme_font_size_override("font_size", int(16 * _sy))
				g_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				g_row.add_child(g_icon)
				var g_lbl := Label.new()
				g_lbl.text = growth
				g_lbl.add_theme_font_size_override("font_size", int(15 * _sy))
				g_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
				g_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				g_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				g_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				g_row.add_child(g_lbl)

			UIAnimations.fade_in_up(self, ref_card, 0.5)

	# ── Action Buttons ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", int(12 * _sx))
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	if passed:
		var done_btn := Button.new()
		done_btn.text = "Continue"
		done_btn.custom_minimum_size = Vector2(180 * _sx, 50 * _sy)
		done_btn.add_theme_font_size_override("font_size", int(18 * _sy))
		done_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		done_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
		done_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
		done_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
		done_btn.pressed.connect(
			func() -> void:
				# ── Story: outro dialogue after quest pass ──
				var bid := _building_label.text.to_lower().replace(" ", "_")
				# Get building_id from QuestManager (more reliable)
				var quest_bid := QuestManager.get_last_completed_building_id()
				if not quest_bid.is_empty():
					bid = quest_bid
				if StoryManager.should_show_outro(bid):
					var outro := StoryManager.get_outro(bid, true)
					if outro.size() > 0:
						var dp := get_node_or_null("/root/Main/UI/DialoguePanel")
						if dp and dp.has_method("show_sequence"):
							QuestManager._reset_state()
							_hide_overlay()
							dp.show_sequence(outro)
							await dp.dialogue_sequence_finished
							StoryManager.mark_outro_seen(bid)
							return
				QuestManager._reset_state()
				_hide_overlay()
		)
		btn_row.add_child(done_btn)
		done_btn.ready.connect(func() -> void: UIAnimations.make_interactive(done_btn))
	else:
		var retry_btn := Button.new()
		retry_btn.text = "Try Again"
		retry_btn.custom_minimum_size = Vector2(140 * _sx, 48 * _sy)
		retry_btn.add_theme_font_size_override("font_size", int(18 * _sy))
		retry_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		retry_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
		retry_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
		retry_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
		retry_btn.pressed.connect(
			func() -> void:
				_clear_question_container()
				QuestManager.retry_mission()
		)
		btn_row.add_child(retry_btn)

		var quit_btn := Button.new()
		quit_btn.text = "Quit"
		quit_btn.custom_minimum_size = Vector2(100 * _sx, 48 * _sy)
		quit_btn.add_theme_font_size_override("font_size", int(16 * _sy))
		quit_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
		quit_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
		quit_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
		quit_btn.add_theme_stylebox_override(
			"pressed", StyleFactory.make_secondary_button_pressed()
		)
		quit_btn.pressed.connect(
			func() -> void:
				QuestManager.abandon_quest()
				_hide_overlay()
		)
		btn_row.add_child(quit_btn)

		retry_btn.ready.connect(func() -> void: UIAnimations.make_interactive(retry_btn))
		quit_btn.ready.connect(func() -> void: UIAnimations.make_interactive(quit_btn))


# ═════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════════════════════════


## Immediately remove and queue-free all children of _question_container.
## Uses remove_child() for instant visual removal (prevents stale nodes from
## stacking when a new interaction is loaded on the same frame), then
## queue_free() for safe deferred memory cleanup.
func _clear_question_container() -> void:
	for child in _question_container.get_children():
		_question_container.remove_child(child)
		child.queue_free()
	_interaction_node = null


func _show_tutorial_demo(question: Dictionary) -> void:
	_tutorial_demo_shown = true
	_transitioning = true

	# Clear old interaction
	_clear_question_container()
	_next_btn.visible = false

	# Hide the empty content area so there's no big blank box while guide is shown
	if is_instance_valid(_question_scroll):
		_question_scroll.visible = false
	_hint_nudge_label.visible = false
	_bottom_bar.visible = false

	# Add guide directly to self (not _question_container) so PRESET_FULL_RECT works
	var guide: Control = load("res://scripts/quest/QuestTutorialGuide.gd").new()
	add_child(guide)
	guide.setup(question, _sx, _sy)

	guide.demo_complete.connect(
		func() -> void:
			# Restore content area then load the real interaction
			if is_instance_valid(_question_scroll):
				_question_scroll.visible = true
			_bottom_bar.visible = true
			_transitioning = false
			_load_current_question(),
		CONNECT_ONE_SHOT
	)


func _show_story_toast(text: String, stage: String) -> void:
	var stage_theme := StyleFactory.get_stage_theme(stage)
	var mood_color: Color = stage_theme.get("accent", StyleFactory.GOLD)

	# Build a small toast card
	var toast := PanelContainer.new()
	var toast_style := StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 12, 1)
	toast_style.border_width_left = 3
	toast_style.border_color = mood_color
	toast.add_theme_stylebox_override("panel", toast_style)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(10 * _sx))
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(hbox)

	# Lumi icon
	var icon := Label.new()
	icon.text = "\u2726"
	icon.add_theme_font_size_override("font_size", int(16 * _sy))
	icon.add_theme_color_override("font_color", mood_color)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon)

	# Text
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", int(14 * _sy))
	lbl.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lbl)

	# Position: centered, below stage banner
	toast.anchor_left = 0.15
	toast.anchor_right = 0.85
	toast.anchor_top = 0.18
	add_child(toast)

	# Animate in
	UIAnimations.fade_in_up(self, toast)

	# Auto-dismiss after delay
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(toast):
		await UIAnimations.panel_out(self, toast)
		if is_instance_valid(toast):
			toast.queue_free()


func _update_stage_banner(stage: String) -> void:
	var stage_theme := StyleFactory.get_stage_theme(stage)
	if stage_theme.get("label", "").is_empty():
		return

	# Animate banner transition
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_stage_banner, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(
		func() -> void:
			# Update banner style
			var banner_style := StyleBoxFlat.new()
			banner_style.bg_color = stage_theme["bg"]
			banner_style.corner_radius_top_left = int(10 * _sx)
			banner_style.corner_radius_top_right = int(10 * _sx)
			banner_style.corner_radius_bottom_left = int(10 * _sx)
			banner_style.corner_radius_bottom_right = int(10 * _sx)
			banner_style.border_width_top = 2
			banner_style.border_width_bottom = 2
			banner_style.border_color = stage_theme["accent"]
			banner_style.content_margin_left = int(16 * _sx)
			banner_style.content_margin_right = int(16 * _sx)
			banner_style.content_margin_top = int(6 * _sy)
			banner_style.content_margin_bottom = int(6 * _sy)
			_stage_banner.add_theme_stylebox_override("panel", banner_style)

			_stage_banner_icon.text = stage_theme["icon"]
			_stage_banner_icon.add_theme_color_override("font_color", stage_theme["accent"])
			_stage_banner_label.text = stage_theme["label"]
			_stage_banner_desc.text = stage_theme["desc"]

			# Tint the background overlay slightly
			var bg_tint := Color(stage_theme["bg"].r, stage_theme["bg"].g, stage_theme["bg"].b, 0.88)
			_bg.color = bg_tint
	)
	(
		tw
		. chain()
		. tween_property(_stage_banner, "modulate:a", 1.0, 0.2)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)


func _update_stage_dots(stage: String) -> void:
	var active_idx := 0
	match stage:
		"tutorial":
			active_idx = 0
		"practice":
			active_idx = 1
		"mission":
			active_idx = 2
	UIAnimations.update_page_dots(self, _stage_dots, active_idx)


func _hide_overlay() -> void:
	_clear_question_container()
	_set_tracker_visible(true)
	AudioManager.start_village_music()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	tw.tween_callback(
		func() -> void:
			visible = false
			modulate.a = 1.0
	)


func _set_tracker_visible(visible_state: bool) -> void:
	var tracker := get_parent().get_node_or_null("QuestTracker")
	if is_instance_valid(tracker):
		tracker.visible = visible_state


func _personalize_quest_data(data: Dictionary) -> Dictionary:
	var student_name: String = GameManager.current_student.get("name", "")
	if student_name.is_empty():
		return data
	var result := data.duplicate(true)
	_substitute_name_in_dict(result, student_name)
	return result


func _substitute_name_in_dict(d: Dictionary, student_name: String) -> void:
	for key in d.keys():
		var val = d[key]
		if val is String:
			d[key] = val.replace("{name}", student_name)
		elif val is Array:
			_substitute_name_in_array(val, student_name)
		elif val is Dictionary:
			_substitute_name_in_dict(val, student_name)


func _substitute_name_in_array(arr: Array, student_name: String) -> void:
	for i in arr.size():
		var val = arr[i]
		if val is String:
			arr[i] = val.replace("{name}", student_name)
		elif val is Array:
			_substitute_name_in_array(val, student_name)
		elif val is Dictionary:
			_substitute_name_in_dict(val, student_name)
