extends Control
## DragDropInteraction — Tap OR drag-and-drop interaction.
## Supports syllable splitting and event sequence ordering.
## Chips support both tap-to-place AND Godot 4 drag-and-drop.

signal answer_submitted(correct: bool)

var _sx: float = 1.0
var _sy: float = 1.0
var _answered: bool = false
var _show_hints: bool = false
var _question: Dictionary = {}

var _placed_order: Array[String] = []
var _word_bank: HBoxContainer
var _drop_zone_container: PanelContainer  # wraps _drop_zone for drop handling
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
	# Do NOT set SIZE_EXPAND_FILL vertically — let content grow naturally so the
	# parent QuestOverlay ScrollContainer can scroll to show the buttons.
	vbox.add_theme_constant_override("separation", int(14 * _sy))
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Instruction
	var instruction: String = _question.get("instruction", "")
	if not instruction.is_empty():
		var inst_label := Label.new()
		inst_label.text = instruction
		inst_label.add_theme_font_size_override("font_size", int(30 * _sy))
		inst_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		inst_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inst_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(inst_label)

	# Word display (syllable mode)
	var mode: String = _question.get("mode", "syllable")
	var word: String = _question.get("word", "")
	if mode == "syllable" and not word.is_empty():
		var word_label := Label.new()
		word_label.text = word
		word_label.add_theme_font_size_override("font_size", int(46 * _sy))
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
			hint_label.add_theme_font_size_override("font_size", int(30 * _sy))
			hint_label.add_theme_color_override("font_color", StyleFactory.SKY_BLUE)
			hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(hint_label)

	# Helper label
	var helper := Label.new()
	helper.text = "Tap a piece to place it, or drag it to the answer box"
	helper.add_theme_font_size_override("font_size", int(22 * _sy))
	helper.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	helper.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	helper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(helper)

	# Drop zone label
	var drop_label := Label.new()
	drop_label.text = "Your answer:"
	drop_label.add_theme_font_size_override("font_size", int(24 * _sy))
	drop_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	drop_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(drop_label)

	# Drop zone card — full-width, taller, with internal padding
	_drop_zone_container = _make_drop_zone_panel()
	_drop_zone_container.custom_minimum_size = Vector2(0, int(110 * _sy))
	_drop_zone_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drop_zone_container.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(_drop_zone_container)

	var drop_margin := MarginContainer.new()
	drop_margin.add_theme_constant_override("margin_left", int(14 * _sx))
	drop_margin.add_theme_constant_override("margin_right", int(14 * _sx))
	drop_margin.add_theme_constant_override("margin_top", int(12 * _sy))
	drop_margin.add_theme_constant_override("margin_bottom", int(12 * _sy))
	drop_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drop_zone_container.add_child(drop_margin)

	if mode == "syllable":
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", int(6 * _sx))
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drop_zone = hbox
	else:
		var vbox_drop := VBoxContainer.new()
		vbox_drop.add_theme_constant_override("separation", int(6 * _sy))
		vbox_drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drop_zone = vbox_drop

	drop_margin.add_child(_drop_zone)

	# Word bank label
	var bank_label := Label.new()
	bank_label.text = "Tap to place:"
	bank_label.add_theme_font_size_override("font_size", int(24 * _sy))
	bank_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	bank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bank_label)

	# Word bank wrapped in a droppable panel so zone chips can be dragged back
	var word_bank_panel := _WordBankPanel.new()
	word_bank_panel._interaction = self
	word_bank_panel.custom_minimum_size = Vector2(0, int(100 * _sy))
	word_bank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	word_bank_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	word_bank_panel.add_theme_stylebox_override(
		"panel", StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 8, 0)
	)
	vbox.add_child(word_bank_panel)

	var bank_margin := MarginContainer.new()
	bank_margin.add_theme_constant_override("margin_left", int(14 * _sx))
	bank_margin.add_theme_constant_override("margin_right", int(14 * _sx))
	bank_margin.add_theme_constant_override("margin_top", int(12 * _sy))
	bank_margin.add_theme_constant_override("margin_bottom", int(12 * _sy))
	bank_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_bank_panel.add_child(bank_margin)

	_word_bank = HBoxContainer.new()
	_word_bank.add_theme_constant_override("separation", int(8 * _sx))
	_word_bank.alignment = BoxContainer.ALIGNMENT_CENTER
	_word_bank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bank_margin.add_child(_word_bank)

	# Populate bank
	var pieces: Array = _question.get("pieces", []).duplicate()
	if pieces.is_empty():
		push_error(
			"[DragDropInteraction] Question has no pieces: %s" % _question.get("instruction", "?")
		)
		answer_submitted.emit(false)
		return
	for piece_text: String in pieces:
		_add_chip_to_bank(piece_text)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", int(12 * _sx))
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	_reset_btn = Button.new()
	_reset_btn.text = "Reset"
	_reset_btn.custom_minimum_size = Vector2(180 * _sx, 72 * _sy)
	_reset_btn.add_theme_font_size_override("font_size", int(28 * _sy))
	_reset_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_reset_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	_reset_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	_reset_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	_reset_btn.pressed.connect(_on_reset_pressed)
	btn_row.add_child(_reset_btn)

	_check_btn = Button.new()
	_check_btn.text = "Check"
	_check_btn.disabled = true
	_check_btn.custom_minimum_size = Vector2(180 * _sx, 72 * _sy)
	_check_btn.add_theme_font_size_override("font_size", int(28 * _sy))
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

	UIAnimations.stagger_children(self, _word_bank)


# ── Chip Factories ────────────────────────────────────────────────────────────


func _make_chip_style(accent: Color = StyleFactory.BG_SURFACE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = accent
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_top = 0
	style.border_width_left = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	# Padding fits content — no forced width
	style.content_margin_left = int(16 * _sx)
	style.content_margin_right = int(16 * _sx)
	style.content_margin_top = int(10 * _sy)
	style.content_margin_bottom = int(10 * _sy)
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	style.anti_aliasing = true
	return style


func _add_chip_to_bank(text: String) -> void:
	var chip := DraggableChip.new()
	chip.chip_text = text
	chip.from_bank = true
	chip.text = text
	# Width fits content — only enforce minimum height
	chip.custom_minimum_size = Vector2(0, int(90 * _sy))
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.add_theme_font_size_override("font_size", int(34 * _sy))
	chip.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	chip.add_theme_stylebox_override("normal", _make_chip_style(StyleFactory.BG_SURFACE))
	var hover_s := _make_chip_style(Color(0.14, 0.21, 0.36))
	hover_s.border_width_top = 2
	hover_s.border_width_left = 2
	hover_s.border_width_right = 2
	hover_s.border_width_bottom = 2
	hover_s.border_color = StyleFactory.SKY_BLUE
	chip.add_theme_stylebox_override("hover", hover_s)
	chip.add_theme_stylebox_override("pressed", _make_chip_style(StyleFactory.BG_CARD))

	chip.pressed.connect(func() -> void: _on_bank_chip_pressed(text, chip))
	chip.drag_started.connect(func(_c: DraggableChip) -> void: pass)  # drag handled via _drop_data
	_word_bank.add_child(chip)

	chip.ready.connect(func() -> void: UIAnimations.make_interactive(chip))


func _add_chip_to_zone(text: String) -> void:
	var chip := DraggableChip.new()
	chip.chip_text = text
	chip.from_bank = false
	chip.text = text
	chip.custom_minimum_size = Vector2(0, int(70 * _sy))
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.add_theme_font_size_override("font_size", int(34 * _sy))
	chip.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)

	var placed_s := _make_chip_style(StyleFactory.BG_SURFACE)
	placed_s.border_width_left = 3
	placed_s.border_color = StyleFactory.SKY_BLUE
	chip.add_theme_stylebox_override("normal", placed_s)

	var hover_s := _make_chip_style(Color(0.14, 0.21, 0.36))
	hover_s.border_width_left = 3
	hover_s.border_color = StyleFactory.ACCENT_CORAL
	chip.add_theme_stylebox_override("hover", hover_s)
	chip.add_theme_stylebox_override("pressed", _make_chip_style(StyleFactory.BG_CARD))

	chip.pressed.connect(func() -> void: _on_zone_chip_pressed(text, chip))
	chip.modulate.a = 0.0
	_drop_zone.add_child(chip)
	UIAnimations.fade_in_up(self, chip)


# Creates a drop-zone PanelContainer that accepts DraggableChip drag data
func _make_drop_zone_panel() -> PanelContainer:
	var panel := _DropZonePanel.new()
	panel._interaction = self
	panel.add_theme_stylebox_override(
		"panel", StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 12, 1)
	)
	return panel


# ── Tap-to-Place Handlers ─────────────────────────────────────────────────────


func _on_bank_chip_pressed(text: String, chip: DraggableChip) -> void:
	if _answered:
		return
	if not is_instance_valid(chip) or chip.get_parent() != _word_bank:
		return
	_word_bank.remove_child(chip)
	chip.queue_free()
	_placed_order.append(text)
	_add_chip_to_zone(text)
	_update_check_button()


func _on_zone_chip_pressed(text: String, chip: DraggableChip) -> void:
	if _answered:
		return
	if not is_instance_valid(chip) or chip.get_parent() != _drop_zone:
		return
	var idx := _placed_order.find(text)
	if idx == -1:
		return
	_placed_order.remove_at(idx)
	_rebuild_drop_zone()
	_add_chip_to_bank(text)
	_update_check_button()


# Returns the child index in _drop_zone that corresponds to a global x position.
func _get_drop_index(global_drop_x: float) -> int:
	var children := _drop_zone.get_children()
	for i in children.size():
		var child := children[i] as Control
		if child == null:
			continue
		if global_drop_x < child.global_position.x + child.size.x * 0.5:
			return i
	return children.size()


# Called when a bank chip is dragged into the drop zone.
func _on_chip_dropped(chip_data: Dictionary, global_drop_x: float = -1.0) -> void:
	if _answered:
		return
	var text: String = chip_data.get("chip_text", "")
	if text.is_empty():
		return
	# Remove from bank
	for child in _word_bank.get_children():
		if child is DraggableChip and child.chip_text == text:
			_word_bank.remove_child(child)
			child.queue_free()
			break
	# Insert at drop position instead of always appending
	var idx: int = _get_drop_index(global_drop_x) if global_drop_x >= 0.0 else _placed_order.size()
	_placed_order.insert(idx, text)
	_rebuild_drop_zone()
	_update_check_button()


# Called when a zone chip is dragged to a new position within the drop zone.
func _on_chip_reordered(chip_data: Dictionary, global_drop_x: float) -> void:
	if _answered:
		return
	var text: String = chip_data.get("chip_text", "")
	if text.is_empty():
		return
	var old_idx: int = _placed_order.find(text)
	if old_idx == -1:
		return
	# Determine insertion index before removing the item
	var new_idx: int = _get_drop_index(global_drop_x)
	_placed_order.remove_at(old_idx)
	if new_idx > old_idx:
		new_idx -= 1
	_placed_order.insert(new_idx, text)
	_rebuild_drop_zone()
	_update_check_button()


func _rebuild_drop_zone() -> void:
	for child in _drop_zone.get_children():
		child.queue_free()
	for piece in _placed_order:
		_add_chip_to_zone(piece)


# Called from _DropTarget when a chip is dragged OUT of the zone (back to bank)
func _on_chip_returned_to_bank(chip_data: Dictionary) -> void:
	if _answered:
		return
	var text: String = chip_data.get("chip_text", "")
	if text.is_empty():
		return
	var idx := _placed_order.find(text)
	if idx == -1:
		return
	_placed_order.remove_at(idx)
	_rebuild_drop_zone()
	_add_chip_to_bank(text)
	_update_check_button()


func _update_check_button() -> void:
	var correct_order: Array = _question.get("correct_order", [])
	_check_btn.disabled = _placed_order.size() != correct_order.size()


func _on_reset_pressed() -> void:
	if _answered:
		return
	var pieces: Array = _question.get("pieces", []).duplicate()
	_placed_order = []
	for child in _drop_zone.get_children():
		child.queue_free()
	for child in _word_bank.get_children():
		child.queue_free()
	for piece_text: String in pieces:
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

	_check_btn.disabled = true
	_reset_btn.disabled = true
	for child in _word_bank.get_children():
		if child is Button:
			child.disabled = true
	for child in _drop_zone.get_children():
		if child is Button:
			child.disabled = true

	var idx := 0
	for child in _drop_zone.get_children():
		if child is Button:
			var is_right: bool = (
				idx < correct_order.size() and _placed_order[idx] == correct_order[idx]
			)
			var style := _make_chip_style(
				(
					StyleFactory.SUCCESS_GREEN.darkened(0.5)
					if is_right
					else StyleFactory.TEXT_ERROR.darkened(0.6)
				)
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
		AudioManager.play_sfx("correct")
		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.08))
	else:
		AudioManager.play_sfx("wrong")

	answer_submitted.emit(correct)


func _show_feedback_result(correct: bool) -> void:
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


func apply_hint(level: int) -> void:
	if _answered:
		return
	var correct_order: Array = _question.get("correct_order", [])
	match level:
		1:
			if _placed_order.size() == 0 and correct_order.size() > 0:
				var first_piece: String = correct_order[0]
				for child in _word_bank.get_children():
					if child is DraggableChip and child.chip_text == first_piece:
						_word_bank.remove_child(child)
						child.queue_free()
						_placed_order.append(first_piece)
						_add_chip_to_zone(first_piece)
						_update_check_button()
						break
		2:
			if _placed_order.size() == 1 and correct_order.size() > 1:
				var second_piece: String = correct_order[1]
				for child in _word_bank.get_children():
					if child is DraggableChip and child.chip_text == second_piece:
						_word_bank.remove_child(child)
						child.queue_free()
						_placed_order.append(second_piece)
						_add_chip_to_zone(second_piece)
						_update_check_button()
						break


# ── Inner helper objects ──────────────────────────────────────────────────────


## PanelContainer subclass that implements Godot 4 drag-drop virtuals directly.
class _DropZonePanel:
	extends PanelContainer
	var _interaction: Control  # DragDropInteraction reference

	func _can_drop_data(_at_pos: Vector2, data: Variant) -> bool:
		if _interaction == null:
			return false
		if data is Dictionary and data.has("chip_text"):
			return not _interaction._answered
		return false

	func _drop_data(at_pos: Vector2, data: Variant) -> void:
		if _interaction == null:
			return
		var global_drop_x: float = global_position.x + at_pos.x
		if data.get("from_bank", true):
			_interaction._on_chip_dropped(data, global_drop_x)
		else:
			_interaction._on_chip_reordered(data, global_drop_x)


## PanelContainer that acts as a drop target for chips dragged OUT of the drop zone.
class _WordBankPanel:
	extends PanelContainer
	var _interaction: Control

	func _can_drop_data(_at_pos: Vector2, data: Variant) -> bool:
		if _interaction == null:
			return false
		# Only accept chips coming from the drop zone (from_bank == false)
		if data is Dictionary and data.has("chip_text") and not data.get("from_bank", true):
			return not _interaction._answered
		return false

	func _drop_data(_at_pos: Vector2, data: Variant) -> void:
		if _interaction != null:
			_interaction._on_chip_returned_to_bank(data)
