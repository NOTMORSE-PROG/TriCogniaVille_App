extends Control
## DragDropInteraction — Tap-to-select drag & drop interaction.
## Supports syllable splitting and event sequence ordering.
## Uses tap-to-place pattern (proven reliable on mobile).

signal answer_submitted(correct: bool)

var _sx: float = 1.0
var _sy: float = 1.0
var _answered: bool = false
var _show_hints: bool = false
var _question: Dictionary = {}

var _placed_order: Array[String] = []
var _word_bank: HBoxContainer
var _drop_zone: BoxContainer
var _check_btn: Button
var _reset_btn: Button
var _feedback_panel: PanelContainer
var _feedback_icon: Label
var _feedback_text: Label


func setup(question: Dictionary, show_hints: bool, sx: float = 1.0, sy: float = 1.0) -> void:
	_sx = sx
	_sy = sy
	_question = question
	_show_hints = show_hints
	_answered = false
	_placed_order = []
	_build_ui()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", int(12 * _sy))
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Instruction
	var instruction: String = _question.get("instruction", "")
	if not instruction.is_empty():
		var inst_label := Label.new()
		inst_label.text = instruction
		inst_label.add_theme_font_size_override("font_size", int(18 * _sy))
		inst_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		inst_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inst_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(inst_label)

	# Word display (for syllable mode)
	var mode: String = _question.get("mode", "syllable")
	var word: String = _question.get("word", "")
	if mode == "syllable" and not word.is_empty():
		var word_label := Label.new()
		word_label.text = word
		word_label.add_theme_font_size_override("font_size", int(28 * _sy))
		word_label.add_theme_color_override("font_color", StyleFactory.GOLD)
		word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(word_label)

	# Hint (practice mode)
	if _show_hints:
		var hint: String = _question.get("hint", "")
		if not hint.is_empty():
			var hint_label := Label.new()
			hint_label.text = hint
			hint_label.add_theme_font_size_override("font_size", int(14 * _sy))
			hint_label.add_theme_color_override("font_color", StyleFactory.SKY_BLUE)
			hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(hint_label)

	# Drop zone (where chips go)
	var drop_label := Label.new()
	drop_label.text = "Your answer:"
	drop_label.add_theme_font_size_override("font_size", int(14 * _sy))
	drop_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	drop_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(drop_label)

	var drop_card := PanelContainer.new()
	drop_card.add_theme_stylebox_override("panel", StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 12, 1))
	drop_card.custom_minimum_size = Vector2(0, 56 * _sy)
	drop_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if mode == "syllable":
		# Use HBox for syllables (horizontal layout)
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", int(6 * _sx))
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		_drop_zone = hbox
	else:
		# Use VBox for sequence events (vertical layout)
		var vbox_drop := VBoxContainer.new()
		vbox_drop.add_theme_constant_override("separation", int(6 * _sy))
		_drop_zone = vbox_drop
	drop_card.add_child(_drop_zone)
	vbox.add_child(drop_card)

	# Word bank (scrambled pieces)
	var bank_label := Label.new()
	bank_label.text = "Tap to place:"
	bank_label.add_theme_font_size_override("font_size", int(14 * _sy))
	bank_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	bank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bank_label)

	_word_bank = HBoxContainer.new()
	_word_bank.add_theme_constant_override("separation", int(8 * _sx))
	_word_bank.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_word_bank)

	# Populate word bank with scrambled pieces
	var pieces: Array = _question.get("pieces", []).duplicate()
	for piece_text in pieces:
		_add_chip_to_bank(piece_text)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", int(12 * _sx))
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	_reset_btn = Button.new()
	_reset_btn.text = "Reset"
	_reset_btn.custom_minimum_size = Vector2(100 * _sx, 44 * _sy)
	_reset_btn.add_theme_font_size_override("font_size", int(16 * _sy))
	_reset_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_reset_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	_reset_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	_reset_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	_reset_btn.pressed.connect(_on_reset_pressed)
	btn_row.add_child(_reset_btn)

	_check_btn = Button.new()
	_check_btn.text = "Check"
	_check_btn.disabled = true
	_check_btn.custom_minimum_size = Vector2(100 * _sx, 44 * _sy)
	_check_btn.add_theme_font_size_override("font_size", int(16 * _sy))
	_check_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_check_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	_check_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	_check_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	_check_btn.add_theme_stylebox_override("disabled", StyleFactory.make_disabled_button())
	_check_btn.pressed.connect(_on_check_pressed)
	btn_row.add_child(_check_btn)

	_check_btn.ready.connect(func() -> void: UIAnimations.make_interactive(_check_btn))
	_reset_btn.ready.connect(func() -> void: UIAnimations.make_interactive(_reset_btn))

	# Feedback panel
	_feedback_panel = PanelContainer.new()
	_feedback_panel.visible = false
	_feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fb_vbox := VBoxContainer.new()
	fb_vbox.add_theme_constant_override("separation", int(4 * _sy))
	fb_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_feedback_icon = Label.new()
	_feedback_icon.add_theme_font_size_override("font_size", int(18 * _sy))
	_feedback_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fb_vbox.add_child(_feedback_icon)

	_feedback_text = Label.new()
	_feedback_text.add_theme_font_size_override("font_size", int(14 * _sy))
	_feedback_text.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	_feedback_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fb_vbox.add_child(_feedback_text)

	_feedback_panel.add_child(fb_vbox)
	vbox.add_child(_feedback_panel)

	UIAnimations.stagger_children(self, _word_bank)


func _add_chip_to_bank(text: String) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(maxf(56 * _sx, text.length() * 14 * _sx), 48 * _sy)
	btn.add_theme_font_size_override("font_size", int(18 * _sy))
	btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	btn.add_theme_stylebox_override("normal", StyleFactory.make_elevated_card(StyleFactory.BG_SURFACE, 10, 1))
	btn.add_theme_stylebox_override("hover", StyleFactory.make_elevated_card(Color(0.14, 0.21, 0.36), 10, 2))
	btn.add_theme_stylebox_override("pressed", StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 10, 1))

	var captured := text
	btn.pressed.connect(func() -> void: _on_bank_chip_pressed(captured, btn))
	_word_bank.add_child(btn)

	btn.ready.connect(func() -> void: UIAnimations.make_interactive(btn))


func _add_chip_to_zone(text: String) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(maxf(56 * _sx, text.length() * 14 * _sx), 44 * _sy)
	btn.add_theme_font_size_override("font_size", int(18 * _sy))
	btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)

	var style := StyleFactory.make_elevated_card(StyleFactory.BG_SURFACE, 10, 1)
	style.border_width_left = 3
	style.border_color = StyleFactory.SKY_BLUE
	btn.add_theme_stylebox_override("normal", style)

	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = Color(0.14, 0.21, 0.36)
	btn.add_theme_stylebox_override("hover", hover_style)

	var captured := text
	btn.pressed.connect(func() -> void: _on_zone_chip_pressed(captured, btn))
	_drop_zone.add_child(btn)

	# Animate chip appearing
	btn.modulate.a = 0.0
	btn.ready.connect(func() -> void:
		UIAnimations.fade_in_up(self, btn)
	)


func _on_bank_chip_pressed(text: String, btn: Button) -> void:
	if _answered:
		return
	if not is_instance_valid(btn) or btn.get_parent() != _word_bank:
		return

	_word_bank.remove_child(btn)
	btn.queue_free()

	_placed_order.append(text)
	_add_chip_to_zone(text)
	_update_check_button()


func _on_zone_chip_pressed(text: String, btn: Button) -> void:
	if _answered:
		return
	if not is_instance_valid(btn) or btn.get_parent() != _drop_zone:
		return

	_drop_zone.remove_child(btn)
	btn.queue_free()

	_placed_order.erase(text)
	_add_chip_to_bank(text)
	_update_check_button()


func _update_check_button() -> void:
	var correct_order: Array = _question.get("correct_order", [])
	_check_btn.disabled = _placed_order.size() != correct_order.size()


func _on_reset_pressed() -> void:
	if _answered:
		return
	# Move all chips back to bank
	var pieces: Array = _question.get("pieces", []).duplicate()
	_placed_order = []
	for child in _drop_zone.get_children():
		child.queue_free()
	for child in _word_bank.get_children():
		child.queue_free()
	for piece_text in pieces:
		_add_chip_to_bank(piece_text)
	_update_check_button()


func _on_check_pressed() -> void:
	if _answered:
		return
	_answered = true

	var correct_order: Array = _question.get("correct_order", [])
	if _placed_order.size() != correct_order.size():
		return

	var correct := true
	for i in _placed_order.size():
		if _placed_order[i] != correct_order[i]:
			correct = false
			break

	# Disable buttons
	_check_btn.disabled = true
	_reset_btn.disabled = true
	for child in _word_bank.get_children():
		if child is Button:
			child.disabled = true
	for child in _drop_zone.get_children():
		if child is Button:
			child.disabled = true

	# Highlight chips
	var idx := 0
	for child in _drop_zone.get_children():
		if child is Button:
			var is_right: bool = idx < correct_order.size() and _placed_order[idx] == correct_order[idx]
			var style := StyleFactory.make_elevated_card(
				StyleFactory.SUCCESS_GREEN.darkened(0.5) if is_right else StyleFactory.TEXT_ERROR.darkened(0.6),
				10, 1
			)
			style.border_width_left = 3
			style.border_color = StyleFactory.SUCCESS_GREEN if is_right else StyleFactory.TEXT_ERROR
			child.add_theme_stylebox_override("normal", style)
			child.add_theme_stylebox_override("disabled", style)

			if not is_right:
				UIAnimations.shake_error(self, child)
			idx += 1

	_show_feedback_result(correct)

	if correct:
		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.08))

	answer_submitted.emit(correct)


func _show_feedback_result(correct: bool) -> void:
	_feedback_panel.add_theme_stylebox_override("panel",
		StyleFactory.make_feedback_panel(correct))
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
	tw.tween_property(_feedback_panel, "modulate:a", 1.0, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
