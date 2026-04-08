extends Control
## QuestTutorialGuide — Animated demo overlay for tutorial stage.
## Shows a guided walkthrough before the student tries the question.
## Player presses "Next" to advance each step, or "Skip Demo" to go straight to trying.

signal demo_complete

var _sx: float = 1.0
var _sy: float = 1.0
var _question: Dictionary = {}
var _step: int = 0
var _steps: Array[Dictionary] = []

var _overlay: ColorRect
var _card: PanelContainer
var _title_label: Label
var _desc_label: Label
var _step_counter: Label
var _next_btn: Button
var _skip_btn: Button


func setup(question: Dictionary, sx: float, sy: float) -> void:
	_sx = sx
	_sy = sy
	_question = question
	_build_steps()
	_build_ui()
	_show_step(0)


func _build_steps() -> void:
	var qtype: String = _question.get("type", "mcq")
	var instruction: String = _question.get("instruction", "")

	_steps = []

	# Step 0: How this works
	(
		_steps
		. append(
			{
				"title": "How this works",
				"desc": _get_how_it_works(qtype),
				"accent": StyleFactory.STAGE_TUTORIAL_ACCENT,
			}
		)
	)

	# Step 1: The instruction (if any)
	if not instruction.is_empty():
		(
			_steps
			. append(
				{
					"title": "Read the instruction",
					"desc": instruction,
					"accent": StyleFactory.GOLD,
				}
			)
		)

	# Step 2: The correct answer / what to look for
	(
		_steps
		. append(
			{
				"title": _get_answer_title(qtype),
				"desc": _get_answer_desc(qtype),
				"accent": StyleFactory.SUCCESS_GREEN,
			}
		)
	)

	# Final step: Try it yourself
	(
		_steps
		. append(
			{
				"title": "Your turn!",
				"desc":
				"Now try answering the question yourself. The question will load after you tap Next.",
				"accent": StyleFactory.ACCENT_CORAL,
			}
		)
	)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Semi-transparent overlay
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.55)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# CenterContainer reliably centers the card without spacer tricks
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_card = PanelContainer.new()
	var style := StyleFactory.make_glass_card(14)
	style.bg_color = Color(0.05, 0.08, 0.16, 0.95)
	_card.add_theme_stylebox_override("panel", style)
	_card.custom_minimum_size = Vector2(640 * _sx, 0)
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_card)

	# Card content with internal padding
	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", int(36 * _sx))
	card_margin.add_theme_constant_override("margin_right", int(36 * _sx))
	card_margin.add_theme_constant_override("margin_top", int(28 * _sy))
	card_margin.add_theme_constant_override("margin_bottom", int(28 * _sy))
	_card.add_child(card_margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", int(20 * _sy))
	card_margin.add_child(content)

	# Top row: step counter + skip button
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(top_row)

	_step_counter = Label.new()
	_step_counter.add_theme_font_size_override("font_size", int(28 * _sy))
	_step_counter.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_step_counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_step_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(_step_counter)

	_skip_btn = Button.new()
	_skip_btn.text = "Skip Demo"
	_skip_btn.custom_minimum_size = Vector2(200 * _sx, 64 * _sy)
	_skip_btn.add_theme_font_size_override("font_size", int(26 * _sy))
	_skip_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_skip_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	_skip_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	_skip_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	_skip_btn.pressed.connect(_finish_demo)
	top_row.add_child(_skip_btn)

	# Title
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", int(46 * _sy))
	_title_label.add_theme_color_override("font_color", StyleFactory.STAGE_TUTORIAL_ACCENT)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.custom_minimum_size = Vector2(1, 0)
	_title_label.size_flags_horizontal = Control.SIZE_FILL
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_title_label)

	# Description — custom_minimum_size.x = 1 prevents autowrap from inflating card width
	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", int(34 * _sy))
	_desc_label.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(1, 0)
	_desc_label.size_flags_horizontal = Control.SIZE_FILL
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_desc_label)

	# Next button
	var btn_center := CenterContainer.new()
	content.add_child(btn_center)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(340 * _sx, 100 * _sy)
	_next_btn.add_theme_font_size_override("font_size", int(38 * _sy))
	_next_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_next_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	_next_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	_next_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	_next_btn.pressed.connect(_on_next_pressed)
	btn_center.add_child(_next_btn)

	_next_btn.ready.connect(func() -> void: UIAnimations.make_interactive(_next_btn))


func _show_step(idx: int) -> void:
	if idx >= _steps.size():
		_finish_demo()
		return

	var step: Dictionary = _steps[idx]
	var is_last := idx == _steps.size() - 1

	_step_counter.text = "Step %d of %d" % [idx + 1, _steps.size()]
	_next_btn.text = "Try It Now!" if is_last else "Next →"

	# Update border accent color
	var style := StyleFactory.make_glass_card(14)
	style.bg_color = Color(0.05, 0.08, 0.16, 0.95)
	style.border_width_top = 3
	style.border_color = step["accent"]
	_card.add_theme_stylebox_override("panel", style)

	# Animate text swap
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	tw.tween_callback(
		func() -> void:
			_title_label.text = step["title"]
			_title_label.add_theme_color_override("font_color", step["accent"])
			_desc_label.text = step["desc"]
	)
	tw.tween_property(_card, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)


func _on_next_pressed() -> void:
	_step += 1
	if _step >= _steps.size():
		_finish_demo()
	else:
		_show_step(_step)


func _finish_demo() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	tw.tween_callback(
		func() -> void:
			demo_complete.emit()
			queue_free()
	)


func _get_how_it_works(qtype: String) -> String:
	match qtype:
		"mcq":
			return "You'll see a question with multiple choices. Read carefully, then tap the answer you think is correct."
		"tap_target":
			return "You'll see a word split into parts. Tap the correct segment that matches what the question asks."
		"drag_drop":
			return "You'll see scrambled pieces. Tap them in the right order, then press Check."
		"read_aloud":
			return "You'll see a word or passage. Read it aloud clearly, then press the button when you're done."
	return "Follow the instructions to answer each question."


func _get_answer_title(qtype: String) -> String:
	match qtype:
		"mcq":
			return "Watch: the correct answer"
		"tap_target":
			return "Watch: the target to tap"
		"drag_drop":
			return "Watch: the correct order"
		"read_aloud":
			return "Read it clearly"
	return "The answer"


func _get_answer_desc(qtype: String) -> String:
	match qtype:
		"mcq":
			var options: Array = _question.get("options", [])
			var ci: int = _question.get("correct_index", 0)
			if ci >= 0 and ci < options.size():
				return (
					'The correct answer is: "%s"\n\n%s'
					% [options[ci], _question.get("feedback_correct", "")]
				)
		"tap_target":
			var segments: Array = _question.get("segments", [])
			var targets: Array = _question.get("target_indices", [])
			var target_texts: PackedStringArray = []
			for idx: int in targets:
				if idx >= 0 and idx < segments.size():
					target_texts.append(segments[idx])
			return (
				'Tap: "%s"\n\n%s'
				% [" + ".join(target_texts), _question.get("feedback_correct", "")]
			)
		"drag_drop":
			var order: Array = _question.get("correct_order", [])
			return (
				"Correct order: %s\n\n%s"
				% [" → ".join(order), _question.get("feedback_correct", "")]
			)
		"read_aloud":
			return (
				"Take your time reading. There's no wrong answer here — just read clearly!\n\n%s"
				% _question.get("feedback_correct", "")
			)
	return _question.get("feedback_correct", "")
