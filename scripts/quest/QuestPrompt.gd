extends Control
## QuestPrompt — Floating prompt panel shown when tapping a locked building.
## Shows building info + "Start Quest" button or "Complete X first!" message.

signal start_quest_pressed(building_id: String, skip_tutorial: bool)
signal dismissed

var _sx: float = 1.0
var _sy: float = 1.0
var _building_id: String = ""
var _transitioning: bool = false
var _player_ref: Node2D
var _building_pos: Vector2 = Vector2.ZERO

var _panel: PanelContainer
var _auto_dismiss_threshold: float = 250.0


func setup(sx: float, sy: float) -> void:
	_sx = sx
	_sy = sy
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)


func show_quest_prompt(
	building_id: String,
	building_label: String,
	topic: String,
	building_color: Color,
	building_pos: Vector2,
	player: Node2D
) -> void:
	if _transitioning:
		return
	_building_id = building_id
	_building_pos = building_pos
	_player_ref = player
	_build_prompt(building_label, topic, building_color, true)
	set_process(true)


func show_sequence_message(required_label: String, building_pos: Vector2, player: Node2D) -> void:
	if _transitioning:
		return
	_building_id = ""
	_building_pos = building_pos
	_player_ref = player
	_build_sequence_message(required_label)
	set_process(true)


func hide_prompt() -> void:
	if not visible or _transitioning:
		return
	_transitioning = true
	set_process(false)
	await UIAnimations.panel_out(self, _panel)
	visible = false
	_transitioning = false
	dismissed.emit()


func _process(_delta: float) -> void:
	# Auto-dismiss if player walks away
	if is_instance_valid(_player_ref):
		var dist := _player_ref.position.distance_to(_building_pos)
		if dist > _auto_dismiss_threshold * _sx:
			hide_prompt()


func _build_prompt(
	building_label: String, topic: String, building_color: Color, can_start: bool
) -> void:
	# Clear
	for child in get_children():
		child.queue_free()

	# Full-screen transparent click blocker
	var blocker := ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.4)
	blocker.anchor_right = 1.0
	blocker.anchor_bottom = 1.0
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	# Tap outside dismisses
	blocker.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				hide_prompt()
			elif event is InputEventScreenTouch and event.pressed:
				hide_prompt()
	)
	add_child(blocker)

	# Center container
	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# Panel
	_panel = PanelContainer.new()
	var style := StyleFactory.make_glass_card(16)
	style.border_width_top = 4
	style.border_color = building_color
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size = Vector2(560 * _sx, 0)
	center.add_child(_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", int(36 * _sx))
	panel_margin.add_theme_constant_override("margin_right", int(36 * _sx))
	panel_margin.add_theme_constant_override("margin_top", int(32 * _sy))
	panel_margin.add_theme_constant_override("margin_bottom", int(32 * _sy))
	_panel.add_child(panel_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(20 * _sy))
	panel_margin.add_child(vbox)

	# Building name + topic
	var title := Label.new()
	title.text = building_label
	title.add_theme_font_size_override("font_size", int(50 * _sy))
	title.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var topic_label := Label.new()
	topic_label.text = topic
	topic_label.add_theme_font_size_override("font_size", int(32 * _sy))
	topic_label.add_theme_color_override("font_color", StyleFactory.GOLD)
	topic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(topic_label)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", int(6 * _sy))
	sep.add_theme_stylebox_override("separator", StyleBoxFlat.new())
	vbox.add_child(sep)

	# Description
	var desc := Label.new()
	desc.text = "Complete this reading quest to unlock!"
	desc.add_theme_font_size_override("font_size", int(36 * _sy))
	desc.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc)

	if can_start:
		var tutorial_done: bool = GameManager.is_tutorial_done(_building_id)
		var challenge_done: bool = GameManager.is_unlocked(_building_id)

		# Two-option choice: Tutorial vs Challenge
		var choice_vbox := VBoxContainer.new()
		choice_vbox.add_theme_constant_override("separation", int(14 * _sy))
		vbox.add_child(choice_vbox)

		# Start with Tutorial button (blue accent)
		var tutorial_btn := Button.new()
		tutorial_btn.text = "✓  Tutorial Done" if tutorial_done else "Start with Tutorial"
		tutorial_btn.custom_minimum_size = Vector2(520 * _sx, 96 * _sy)
		tutorial_btn.add_theme_font_size_override("font_size", int(38 * _sy))
		tutorial_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		var tut_style := StyleFactory.make_secondary_button_normal()
		tut_style.border_color = StyleFactory.STAGE_TUTORIAL_ACCENT
		tut_style.border_width_top = 2
		tut_style.border_width_left = 2
		tut_style.border_width_right = 2
		tut_style.border_width_bottom = 2
		tutorial_btn.add_theme_stylebox_override("normal", tut_style)
		var tut_hover := StyleFactory.make_secondary_button_hover()
		tut_hover.border_color = StyleFactory.STAGE_TUTORIAL_ACCENT
		tut_hover.bg_color = Color(
			StyleFactory.STAGE_TUTORIAL_ACCENT.r,
			StyleFactory.STAGE_TUTORIAL_ACCENT.g,
			StyleFactory.STAGE_TUTORIAL_ACCENT.b,
			0.1
		)
		tutorial_btn.add_theme_stylebox_override("hover", tut_hover)
		tutorial_btn.add_theme_stylebox_override(
			"pressed", StyleFactory.make_secondary_button_pressed()
		)
		tutorial_btn.pressed.connect(
			func() -> void:
				set_process(false)
				visible = false
				start_quest_pressed.emit(_building_id, false)
		)
		var tut_center := CenterContainer.new()
		tut_center.add_child(tutorial_btn)
		choice_vbox.add_child(tut_center)

		var tut_desc := Label.new()
		tut_desc.text = "Learn step-by-step with guided examples"
		tut_desc.add_theme_font_size_override("font_size", int(26 * _sy))
		tut_desc.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
		tut_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tut_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		choice_vbox.add_child(tut_desc)

		# Skip to Challenge button — locked until tutorial is done
		var challenge_btn := Button.new()
		if challenge_done:
			challenge_btn.text = "✓  Challenge Done"
		elif tutorial_done:
			challenge_btn.text = "Start the Challenge"
		else:
			challenge_btn.text = "🔒  Complete Tutorial First"
		challenge_btn.disabled = not tutorial_done
		challenge_btn.custom_minimum_size = Vector2(520 * _sx, 96 * _sy)
		challenge_btn.add_theme_font_size_override("font_size", int(38 * _sy))
		challenge_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
		if tutorial_done:
			challenge_btn.add_theme_stylebox_override(
				"normal", StyleFactory.make_primary_button_normal()
			)
			challenge_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
			challenge_btn.add_theme_stylebox_override(
				"pressed", StyleFactory.make_primary_button_pressed()
			)
			challenge_btn.pressed.connect(
				func() -> void:
					set_process(false)
					visible = false
					start_quest_pressed.emit(_building_id, true)
			)
		else:
			challenge_btn.add_theme_stylebox_override(
				"normal", StyleFactory.make_disabled_button()
			)
			challenge_btn.add_theme_stylebox_override(
				"disabled", StyleFactory.make_disabled_button()
			)
		var ch_center := CenterContainer.new()
		ch_center.add_child(challenge_btn)
		choice_vbox.add_child(ch_center)

		var ch_desc := Label.new()
		ch_desc.text = (
			"Go straight to the graded mission"
			if tutorial_done
			else "Finish the tutorial to unlock the challenge"
		)
		ch_desc.add_theme_font_size_override("font_size", int(26 * _sy))
		ch_desc.add_theme_color_override(
			"font_color",
			StyleFactory.TEXT_MUTED if tutorial_done else StyleFactory.TEXT_MUTED
		)
		ch_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ch_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		choice_vbox.add_child(ch_desc)

		tutorial_btn.ready.connect(func() -> void: UIAnimations.make_interactive(tutorial_btn))
		if tutorial_done:
			challenge_btn.ready.connect(func() -> void: UIAnimations.make_interactive(challenge_btn))

	# Not now
	var dismiss_btn := Button.new()
	dismiss_btn.text = "Not now"
	dismiss_btn.custom_minimum_size = Vector2(240 * _sx, 80 * _sy)
	dismiss_btn.add_theme_font_size_override("font_size", int(30 * _sy))
	dismiss_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	dismiss_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	dismiss_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	dismiss_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	dismiss_btn.pressed.connect(func() -> void: hide_prompt())
	var center_dismiss := CenterContainer.new()
	center_dismiss.add_child(dismiss_btn)
	vbox.add_child(center_dismiss)

	# Show with animation
	visible = true
	UIAnimations.panel_in(self, _panel)


func _build_sequence_message(required_label: String) -> void:
	for child in get_children():
		child.queue_free()

	# Background blocker
	var blocker := ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.4)
	blocker.anchor_right = 1.0
	blocker.anchor_bottom = 1.0
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				hide_prompt()
			elif event is InputEventScreenTouch and event.pressed:
				hide_prompt()
	)
	add_child(blocker)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(16))
	_panel.custom_minimum_size = Vector2(500 * _sx, 0)
	center.add_child(_panel)

	var seq_margin := MarginContainer.new()
	seq_margin.add_theme_constant_override("margin_left", int(36 * _sx))
	seq_margin.add_theme_constant_override("margin_right", int(36 * _sx))
	seq_margin.add_theme_constant_override("margin_top", int(32 * _sy))
	seq_margin.add_theme_constant_override("margin_bottom", int(32 * _sy))
	_panel.add_child(seq_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(20 * _sy))
	seq_margin.add_child(vbox)

	var msg := Label.new()
	msg.text = "Complete %s first!" % required_label
	msg.add_theme_font_size_override("font_size", int(40 * _sy))
	msg.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(msg)

	var dismiss_btn := Button.new()
	dismiss_btn.text = "OK"
	dismiss_btn.custom_minimum_size = Vector2(200 * _sx, 84 * _sy)
	dismiss_btn.add_theme_font_size_override("font_size", int(36 * _sy))
	dismiss_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	dismiss_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	dismiss_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	dismiss_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	dismiss_btn.pressed.connect(func() -> void: hide_prompt())
	var center_btn := CenterContainer.new()
	center_btn.add_child(dismiss_btn)
	vbox.add_child(center_btn)

	visible = true
	UIAnimations.panel_in(self, _panel)
