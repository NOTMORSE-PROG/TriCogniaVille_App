extends Control
## MCQInteraction — Multiple-choice question interaction component.
## Displays passage (optional) + question + options with feedback.
## Pattern follows OnboardingScreen MCQ implementation.

signal answer_submitted(correct: bool)

var _sx: float = 1.0
var _sy: float = 1.0
var _answered: bool = false
var _show_hints: bool = false
var _question: Dictionary = {}

var _shuffled_correct_index: int = -1

var _passage_label: RichTextLabel
var _question_label: Label
var _hint_label: Label
var _options_container: VBoxContainer
var _feedback_panel: PanelContainer
var _feedback_icon: Label
var _feedback_text: Label


func setup(question: Dictionary, show_hints: bool, sx: float = 1.0, sy: float = 1.0) -> void:
	_sx = sx
	_sy = sy
	_question = question
	_show_hints = show_hints
	_answered = false
	_build_ui()


func _build_ui() -> void:
	# Clear existing children
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", int(12 * _sy))
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Passage (optional)
	var passage: String = _question.get("passage", "")
	if not passage.is_empty():
		var passage_card := PanelContainer.new()
		passage_card.add_theme_stylebox_override(
			"panel", StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 12, 1)
		)
		passage_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_passage_label = RichTextLabel.new()
		_passage_label.text = passage
		_passage_label.fit_content = true
		_passage_label.bbcode_enabled = false
		_passage_label.scroll_active = false
		_passage_label.add_theme_font_size_override("normal_font_size", int(34 * _sy))
		_passage_label.add_theme_color_override("default_color", StyleFactory.TEXT_SECONDARY)
		_passage_label.custom_minimum_size = Vector2(0, 130 * _sy)
		_passage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		passage_card.add_child(_passage_label)
		vbox.add_child(passage_card)

	# Instruction
	var instruction: String = _question.get("instruction", "")
	if not instruction.is_empty():
		var inst_label := Label.new()
		inst_label.text = instruction
		inst_label.add_theme_font_size_override("font_size", int(48 * _sy))
		inst_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
		inst_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inst_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(inst_label)

	# Question
	_question_label = Label.new()
	_question_label.text = _question.get("question", "")
	_question_label.add_theme_font_size_override("font_size", int(40 * _sy))
	_question_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_question_label)

	# Hint (practice mode only)
	if _show_hints:
		var hint: String = _question.get("hint", "")
		if not hint.is_empty():
			_hint_label = Label.new()
			_hint_label.text = hint
			_hint_label.add_theme_font_size_override("font_size", int(21 * _sy))
			_hint_label.add_theme_color_override("font_color", StyleFactory.SKY_BLUE)
			_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(_hint_label)

	# Options
	_options_container = VBoxContainer.new()
	_options_container.add_theme_constant_override("separation", int(8 * _sy))
	vbox.add_child(_options_container)

	var options: Array = _question.get("options", [])
	if options.is_empty():
		push_error("[MCQInteraction] Question has no options: %s" % _question.get("question", "?"))
		answer_submitted.emit(false)
		return

	# Shuffle options at render time so the correct answer isn't always first
	var stored_correct: int = _question.get("correct_index", -1)
	var idx_list := range(options.size())
	idx_list.shuffle()
	var shuffled: Array = []
	_shuffled_correct_index = -1
	for new_pos in idx_list.size():
		shuffled.append(options[idx_list[new_pos]])
		if idx_list[new_pos] == stored_correct:
			_shuffled_correct_index = new_pos
	options = shuffled

	for i in options.size():
		var btn := Button.new()
		btn.text = options[i]
		btn.custom_minimum_size = Vector2(0, 88 * _sy)
		btn.add_theme_font_size_override("font_size", int(30 * _sy))
		btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		btn.add_theme_stylebox_override("normal", StyleFactory.make_student_card_normal())
		btn.add_theme_stylebox_override("hover", StyleFactory.make_student_card_hover())
		btn.add_theme_stylebox_override("pressed", StyleFactory.make_student_card_pressed())
		btn.add_theme_stylebox_override("disabled", StyleFactory.make_disabled_button())
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_options_container.add_child(btn)

		var captured_idx := i
		btn.pressed.connect(func() -> void: _on_option_pressed(captured_idx))

		# Defer make_interactive so size is calculated
		btn.ready.connect(func() -> void: UIAnimations.make_interactive(btn))

	# Feedback panel (hidden initially)
	_feedback_panel = PanelContainer.new()
	_feedback_panel.visible = false
	_feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fb_vbox := VBoxContainer.new()
	fb_vbox.add_theme_constant_override("separation", int(4 * _sy))
	fb_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_feedback_icon = Label.new()
	_feedback_icon.add_theme_font_size_override("font_size", int(27 * _sy))
	_feedback_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fb_vbox.add_child(_feedback_icon)

	_feedback_text = Label.new()
	_feedback_text.add_theme_font_size_override("font_size", int(21 * _sy))
	_feedback_text.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	_feedback_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fb_vbox.add_child(_feedback_text)

	_feedback_panel.add_child(fb_vbox)
	vbox.add_child(_feedback_panel)

	# Stagger modulate-only entrance (no position.y — VBoxContainer manages layout)
	var stagger_idx := 0
	for child in _options_container.get_children():
		if child is Control:
			child.modulate.a = 0.0
			var tw := create_tween()
			(
				tw
				. tween_property(child, "modulate:a", 1.0, 0.3)
				. set_trans(Tween.TRANS_QUAD)
				. set_ease(Tween.EASE_OUT)
				. set_delay(stagger_idx * 0.07)
			)
			stagger_idx += 1


func _on_option_pressed(index: int) -> void:
	if _answered:
		return
	_answered = true

	var correct := index == _shuffled_correct_index

	# Disable all options
	for child in _options_container.get_children():
		if child is Button:
			child.disabled = true

	# Highlight selected option
	var selected_btn: Button = _options_container.get_child(index) as Button
	if is_instance_valid(selected_btn):
		var style := StyleFactory.make_student_card_normal()
		if correct:
			style.bg_color = StyleFactory.SUCCESS_GREEN.darkened(0.6)
			style.border_width_left = 4
			style.border_color = StyleFactory.SUCCESS_GREEN
		else:
			style.bg_color = StyleFactory.TEXT_ERROR.darkened(0.7)
			style.border_width_left = 4
			style.border_color = StyleFactory.TEXT_ERROR
		selected_btn.add_theme_stylebox_override("disabled", style)

	# Highlight correct answer if wrong
	if not correct and _shuffled_correct_index >= 0 and _shuffled_correct_index < _options_container.get_child_count():
		var correct_btn: Button = _options_container.get_child(_shuffled_correct_index) as Button
		if is_instance_valid(correct_btn):
			var cs := StyleFactory.make_student_card_normal()
			cs.bg_color = StyleFactory.SUCCESS_GREEN.darkened(0.6)
			cs.border_width_left = 4
			cs.border_color = StyleFactory.SUCCESS_GREEN
			correct_btn.add_theme_stylebox_override("disabled", cs)

	# Show feedback
	_show_feedback(correct)

	# Effects + SFX
	if correct:
		AudioManager.play_sfx("correct")
		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.08))
	else:
		AudioManager.play_sfx("wrong")
		if is_instance_valid(selected_btn):
			UIAnimations.shake_error(self, selected_btn)

	answer_submitted.emit(correct)


func apply_hint(level: int) -> void:
	if _answered:
		return
	match level:
		1:
			# Eliminate one wrong option (grey it out)
			for child in _options_container.get_children():
				if child is Button and not child.disabled:
					var idx := child.get_index()
					if idx != _shuffled_correct_index:
						child.disabled = true
						child.modulate.a = 0.4
						break  # Only eliminate one
		2:
			# Highlight a keyword in the question text
			if is_instance_valid(_question_label):
				var tw := create_tween().set_loops(3)
				tw.tween_property(_question_label, "modulate:a", 0.5, 0.3)
				tw.tween_property(_question_label, "modulate:a", 1.0, 0.3)


func _show_feedback(correct: bool) -> void:
	_feedback_panel.add_theme_stylebox_override("panel", StyleFactory.make_feedback_panel(correct))
	_feedback_panel.visible = true
	_feedback_panel.modulate.a = 0.0

	if correct:
		_feedback_icon.text = "Correct!"
		_feedback_icon.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
		_feedback_text.text = _question.get("feedback_correct", "")
	else:
		_feedback_icon.text = "Not Quite"
		_feedback_icon.add_theme_color_override("font_color", StyleFactory.TEXT_ERROR)
		_feedback_text.text = _question.get("feedback_wrong", "")

	var tw := create_tween()
	tw.tween_property(_feedback_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)

	# Hide the choices after a brief moment so the feedback takes their place
	await get_tree().create_timer(0.9).timeout
	if is_instance_valid(_options_container):
		var fade := create_tween()
		fade.tween_property(_options_container, "modulate:a", 0.0, 0.25)
		await fade.finished
		if is_instance_valid(_options_container):
			_options_container.visible = false
