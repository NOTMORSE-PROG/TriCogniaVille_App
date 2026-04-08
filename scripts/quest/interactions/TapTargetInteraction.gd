extends Control
## TapTargetInteraction — "Tap the correct part" interaction.
## Displays a word split into tappable segments. Student taps the target segment.
## Used for decoding (blends, vowels) and vocabulary (word spark).

signal answer_submitted(correct: bool)

var _sx: float = 1.0
var _sy: float = 1.0
var _answered: bool = false
var _show_hints: bool = false
var _question: Dictionary = {}

var _segments_container: HBoxContainer
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
	for child in get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", int(16 * _sy))
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Instruction
	var instruction: String = _question.get("instruction", "")
	if not instruction.is_empty():
		var inst_label := Label.new()
		inst_label.text = instruction
		inst_label.add_theme_font_size_override("font_size", int(40 * _sy))
		inst_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		inst_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inst_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(inst_label)

	# Word label
	var word: String = _question.get("word", "")
	if not word.is_empty():
		var word_label := Label.new()
		word_label.text = word
		word_label.add_theme_font_size_override("font_size", int(60 * _sy))
		word_label.add_theme_color_override("font_color", StyleFactory.GOLD)
		word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(word_label)

	# Segment buttons
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(center)

	_segments_container = HBoxContainer.new()
	_segments_container.add_theme_constant_override("separation", int(6 * _sx))
	center.add_child(_segments_container)

	var segments: Array = _question.get("segments", [])
	var target_indices: Array = _question.get("target_indices", [])

	for i in segments.size():
		var seg_text: String = segments[i]
		if seg_text.strip_edges().is_empty():
			# Spacer for visual separation
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(12 * _sx, 0)
			_segments_container.add_child(spacer)
			continue

		var btn := Button.new()
		btn.text = seg_text
		btn.custom_minimum_size = Vector2(maxf(110 * _sx, seg_text.length() * 42 * _sx), 130 * _sy)
		btn.add_theme_font_size_override("font_size", int(50 * _sy))
		btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		btn.add_theme_stylebox_override(
			"normal", StyleFactory.make_elevated_card(StyleFactory.BG_SURFACE, 10, 1)
		)
		btn.add_theme_stylebox_override(
			"hover", StyleFactory.make_elevated_card(Color(0.14, 0.21, 0.36), 10, 2)
		)
		btn.add_theme_stylebox_override(
			"pressed", StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 10, 1)
		)
		btn.add_theme_stylebox_override("disabled", StyleFactory.make_disabled_button())

		var captured_idx := i
		btn.pressed.connect(func() -> void: _on_segment_pressed(captured_idx))
		_segments_container.add_child(btn)

		btn.ready.connect(func() -> void: UIAnimations.make_interactive(btn))

		# Practice hint: pulse the target segments
		if _show_hints and i in target_indices:
			btn.ready.connect(func() -> void: _pulse_hint(btn))

	# Feedback panel
	_feedback_panel = PanelContainer.new()
	_feedback_panel.visible = false
	_feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fb_vbox := VBoxContainer.new()
	fb_vbox.add_theme_constant_override("separation", int(4 * _sy))
	fb_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_feedback_icon = Label.new()
	_feedback_icon.add_theme_font_size_override("font_size", int(40 * _sy))
	_feedback_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fb_vbox.add_child(_feedback_icon)

	_feedback_text = Label.new()
	_feedback_text.add_theme_font_size_override("font_size", int(30 * _sy))
	_feedback_text.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	_feedback_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fb_vbox.add_child(_feedback_text)

	_feedback_panel.add_child(fb_vbox)
	vbox.add_child(_feedback_panel)

	UIAnimations.stagger_children(self, _segments_container)


func _on_segment_pressed(index: int) -> void:
	if _answered:
		return
	_answered = true

	var target_indices: Array = _question.get("target_indices", [])
	var correct := index in target_indices

	# Disable all segment buttons
	for child in _segments_container.get_children():
		if child is Button:
			child.disabled = true

	# Highlight tapped segment
	var btn_idx := 0
	for child in _segments_container.get_children():
		if child is Button:
			if btn_idx == index:
				var style := StyleFactory.make_elevated_card(
					(
						StyleFactory.SUCCESS_GREEN.darkened(0.5)
						if correct
						else StyleFactory.TEXT_ERROR.darkened(0.6)
					),
					10,
					1
				)
				style.border_width_top = 3
				style.border_color = (
					StyleFactory.SUCCESS_GREEN if correct else StyleFactory.TEXT_ERROR
				)
				child.add_theme_stylebox_override("disabled", style)

				if correct:
					child.pivot_offset = child.size / 2.0
					var tw := create_tween()
					(
						tw
						. tween_property(child, "scale", Vector2(1.15, 1.15), 0.15)
						. set_trans(Tween.TRANS_BACK)
						. set_ease(Tween.EASE_OUT)
					)
					tw.tween_property(child, "scale", Vector2.ONE, 0.2)
				else:
					UIAnimations.shake_error(self, child)
			elif btn_idx in target_indices and not correct:
				# Show the correct one
				var cs := StyleFactory.make_elevated_card(
					StyleFactory.SUCCESS_GREEN.darkened(0.5), 10, 1
				)
				cs.border_width_top = 3
				cs.border_color = StyleFactory.SUCCESS_GREEN
				child.add_theme_stylebox_override("disabled", cs)
			btn_idx += 1

	_show_feedback_panel(correct)

	if correct:
		AudioManager.play_sfx("correct")
		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.08))
	else:
		AudioManager.play_sfx("wrong")

	answer_submitted.emit(correct)


func apply_hint(level: int) -> void:
	if _answered:
		return
	var target_indices: Array = _question.get("target_indices", [])
	match level:
		1:
			# Dim one wrong segment
			var btn_idx := 0
			for child in _segments_container.get_children():
				if child is Button and not child.disabled:
					if btn_idx not in target_indices:
						child.modulate.a = 0.3
						break
				if child is Button:
					btn_idx += 1
		2:
			# Brief pulse on correct segment
			var btn_idx := 0
			for child in _segments_container.get_children():
				if child is Button:
					if btn_idx in target_indices:
						var tw := create_tween().set_loops(2)
						tw.tween_property(child, "modulate:a", 0.4, 0.25)
						tw.tween_property(child, "modulate:a", 1.0, 0.25)
					btn_idx += 1


func _show_feedback_panel(correct: bool) -> void:
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

	call_deferred("_scroll_to_feedback")


func _scroll_to_feedback() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var node: Node = self
	while node:
		if node is ScrollContainer:
			var sc: ScrollContainer = node
			sc.ensure_control_visible(_feedback_panel)
			await get_tree().process_frame
			sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value)
			return
		node = node.get_parent()


func _pulse_hint(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	var tw := create_tween().set_loops()
	tw.tween_property(btn, "modulate:a", 0.6, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(btn, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
