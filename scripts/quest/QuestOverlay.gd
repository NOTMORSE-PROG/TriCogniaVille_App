extends Control
## QuestOverlay — Full-screen quest UI overlay on the village map.
## Manages 3-stage flow: Tutorial → Practice → Mission → Results.
## Blocks all input below via MOUSE_FILTER_STOP.

var _sx: float = 1.0
var _sy: float = 1.0
var _transitioning: bool = false

# UI containers
var _bg: ColorRect
var _header_container: VBoxContainer
var _stage_dots: Array[Panel] = []
var _question_container: VBoxContainer
var _interaction_node: Control
var _bottom_bar: HBoxContainer
var _next_btn: Button
var _counter_label: Label
var _close_btn: Button
var _building_label: Label
var _topic_label: Label
var _stage_label: Label

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
	_building_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_building_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_building_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_container.add_child(_building_label)

	var sub_hbox := HBoxContainer.new()
	sub_hbox.add_theme_constant_override("separation", int(12 * _sx))
	sub_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_container.add_child(sub_hbox)

	_topic_label = Label.new()
	_topic_label.add_theme_font_size_override("font_size", int(18 * _sy))
	_topic_label.add_theme_color_override("font_color", StyleFactory.GOLD)
	_topic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_hbox.add_child(_topic_label)

	_stage_label = Label.new()
	_stage_label.add_theme_font_size_override("font_size", int(18 * _sy))
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
		dot.custom_minimum_size = Vector2(16 * _sx, 8 * _sy)
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
	_close_btn.custom_minimum_size = Vector2(44 * _sx, 44 * _sy)
	_close_btn.add_theme_font_size_override("font_size", int(16 * _sy))
	_close_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_close_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	_close_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	_close_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	_close_btn.pressed.connect(_on_close_pressed)
	header_hbox.add_child(_close_btn)

	# ── Content area ──
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	main_vbox.add_child(scroll)

	_question_container = VBoxContainer.new()
	_question_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_question_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_question_container)

	# ── Bottom bar ──
	_bottom_bar = HBoxContainer.new()
	_bottom_bar.add_theme_constant_override("separation", int(12 * _sx))
	_bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(_bottom_bar)

	_counter_label = Label.new()
	_counter_label.add_theme_font_size_override("font_size", int(14 * _sy))
	_counter_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_counter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_bar.add_child(_counter_label)

	_next_btn = Button.new()
	_next_btn.text = "Next"
	_next_btn.visible = false
	_next_btn.custom_minimum_size = Vector2(140 * _sx, 48 * _sy)
	_next_btn.add_theme_font_size_override("font_size", int(18 * _sy))
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
	_set_tracker_visible(false)
	visible = true
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_stage_changed(stage: String) -> void:
	_update_stage_dots(stage)
	match stage:
		"tutorial": _stage_label.text = "Tutorial"
		"practice": _stage_label.text = "Practice"
		"mission":  _stage_label.text = "Mission"
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

	var question: Dictionary = questions[idx]
	var stage := QuestManager.get_current_stage()
	var show_hints := (stage == "practice" or stage == "tutorial")

	# Update counter
	if stage == "mission":
		_counter_label.text = "Question %d of %d" % [idx + 1, questions.size()]
	else:
		_counter_label.text = "%s %d of %d" % [stage.capitalize(), idx + 1, questions.size()]

	# Clear old interaction
	_transitioning = true
	if is_instance_valid(_interaction_node):
		_interaction_node.queue_free()
		_interaction_node = null

	_next_btn.visible = false

	# Create new interaction based on type
	var qtype: String = question.get("type", "mcq")
	match qtype:
		"mcq":
			var mcq: Node = load("res://scripts/quest/interactions/MCQInteraction.gd").new()
			_question_container.add_child(mcq)
			mcq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mcq.size_flags_vertical = Control.SIZE_EXPAND_FILL
			mcq.setup(question, show_hints, _sx, _sy)
			mcq.answer_submitted.connect(_on_answer_submitted)
			_interaction_node = mcq
		"tap_target":
			var tap: Node = load("res://scripts/quest/interactions/TapTargetInteraction.gd").new()
			_question_container.add_child(tap)
			tap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tap.size_flags_vertical = Control.SIZE_EXPAND_FILL
			tap.setup(question, show_hints, _sx, _sy)
			tap.answer_submitted.connect(_on_answer_submitted)
			_interaction_node = tap
		"drag_drop":
			var dd: Node = load("res://scripts/quest/interactions/DragDropInteraction.gd").new()
			_question_container.add_child(dd)
			dd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dd.size_flags_vertical = Control.SIZE_EXPAND_FILL
			dd.setup(question, show_hints, _sx, _sy)
			dd.answer_submitted.connect(_on_answer_submitted)
			_interaction_node = dd
		"read_aloud":
			var ra: Node = load("res://scripts/quest/interactions/ReadAloudInteraction.gd").new()
			_question_container.add_child(ra)
			ra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ra.size_flags_vertical = Control.SIZE_EXPAND_FILL
			ra.setup(question, show_hints, _sx, _sy)
			ra.answer_submitted.connect(_on_answer_submitted)
			_interaction_node = ra

	if is_instance_valid(_interaction_node):
		UIAnimations.fade_in_up(self, _interaction_node)

	_transitioning = false


func _on_answer_submitted(correct: bool) -> void:
	QuestManager.submit_answer(correct)
	# Show Next button after a short delay
	_next_btn.visible = false
	var timer := get_tree().create_timer(1.2)
	timer.timeout.connect(func() -> void:
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
		if QuestManager.get_current_stage() == "mission":
			QuestManager.advance_stage()  # triggers finish
		else:
			QuestManager.advance_stage()


func _on_close_pressed() -> void:
	QuestManager.abandon_quest()


# ═════════════════════════════════════════════════════════════════════════════
# RESULTS
# ═════════════════════════════════════════════════════════════════════════════

func _show_result(_building_id: String, passed: bool, score: int) -> void:
	# Clear question area
	if is_instance_valid(_interaction_node):
		_interaction_node.queue_free()
		_interaction_node = null

	_next_btn.visible = false
	_counter_label.text = ""

	# Build result UI in question container
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", int(16 * _sy))
	_question_container.add_child(vbox)
	_interaction_node = vbox  # for cleanup

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(center)

	var result_card := VBoxContainer.new()
	result_card.add_theme_constant_override("separation", int(16 * _sy))
	result_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(result_card)

	# Result icon/title
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(28 * _sy))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_card.add_child(title)

	var score_label := Label.new()
	score_label.text = "Score: %d / %d" % [score, QuestManager.get_mission_total()]
	score_label.add_theme_font_size_override("font_size", int(20 * _sy))
	score_label.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_card.add_child(score_label)

	if passed:
		title.text = "Quest Complete!"
		title.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)

		var xp_label := Label.new()
		var xp: int = QuestManager.get_current_quest_data().get("xp", 0)
		xp_label.text = "+%d XP" % xp
		xp_label.add_theme_font_size_override("font_size", int(24 * _sy))
		xp_label.add_theme_color_override("font_color", StyleFactory.GOLD)
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_card.add_child(xp_label)

		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.12))
		UIAnimations.elastic_reveal(self, result_card)

		# Close button after delay
		var close_timer := get_tree().create_timer(2.0)
		close_timer.timeout.connect(func() -> void:
			var done_btn := Button.new()
			done_btn.text = "Continue"
			done_btn.custom_minimum_size = Vector2(180 * _sx, 50 * _sy)
			done_btn.add_theme_font_size_override("font_size", int(18 * _sy))
			done_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
			done_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
			done_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
			done_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
			done_btn.pressed.connect(func() -> void:
				QuestManager._reset_state()
				_hide_overlay()
			)
			var btn_center := CenterContainer.new()
			btn_center.add_child(done_btn)
			result_card.add_child(btn_center)
			UIAnimations.fade_in_up(self, done_btn)
			UIAnimations.make_interactive(done_btn)
		)
	else:
		title.text = "Keep trying!"
		title.add_theme_color_override("font_color", StyleFactory.TEXT_ERROR)

		var encourage := Label.new()
		encourage.text = "You need 7 correct answers to unlock this building."
		encourage.add_theme_font_size_override("font_size", int(15 * _sy))
		encourage.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
		encourage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		encourage.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		encourage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result_card.add_child(encourage)

		UIAnimations.fade_in_up(self, result_card)

		# Retry + Close buttons
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", int(12 * _sx))
		btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
		result_card.add_child(btn_row)

		var retry_btn := Button.new()
		retry_btn.text = "Try Again"
		retry_btn.custom_minimum_size = Vector2(140 * _sx, 48 * _sy)
		retry_btn.add_theme_font_size_override("font_size", int(18 * _sy))
		retry_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		retry_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
		retry_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
		retry_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
		retry_btn.pressed.connect(func() -> void:
			if is_instance_valid(_interaction_node):
				_interaction_node.queue_free()
				_interaction_node = null
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
		quit_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
		quit_btn.pressed.connect(func() -> void:
			QuestManager._reset_state()
			_hide_overlay()
		)
		btn_row.add_child(quit_btn)

		retry_btn.ready.connect(func() -> void: UIAnimations.make_interactive(retry_btn))
		quit_btn.ready.connect(func() -> void: UIAnimations.make_interactive(quit_btn))


# ═════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════════════════════════

func _update_stage_dots(stage: String) -> void:
	var active_idx := 0
	match stage:
		"tutorial": active_idx = 0
		"practice": active_idx = 1
		"mission":  active_idx = 2
	UIAnimations.update_page_dots(self, _stage_dots, active_idx)


func _hide_overlay() -> void:
	if is_instance_valid(_interaction_node):
		_interaction_node.queue_free()
		_interaction_node = null
	_set_tracker_visible(true)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		visible = false
		modulate.a = 1.0
	)


func _set_tracker_visible(show: bool) -> void:
	var tracker := get_parent().get_node_or_null("QuestTracker")
	if is_instance_valid(tracker):
		tracker.visible = show
