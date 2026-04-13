extends Control
## TutorialOverlay — First-time guided walkthrough on the village map.
## Sequential steps teach movement, building interaction, and quest completion.
## Skippable at every step. Persists tutorial_done on completion.
##
## LAYOUT RULES (Godot 4):
##   - set_anchors_and_offsets_preset() must be called AFTER add_child()
##   - Use VBoxContainer+spacers instead of CenterContainer (CenterContainer has bug #97549)
##   - stagger_children() must NOT be used on VBoxContainer children (fights layout)

signal tutorial_completed

enum Step {
	WELCOME,
	MOVE_AROUND,
	WALK_TO_TOWN_HALL,
	TAP_BUILDING,
	COMPLETE_QUEST,
	POST_QUEST,
	DONE,
}

var _sx: float = 1.0
var _sy: float = 1.0
var _current_step: int = Step.WELCOME
var _transitioning: bool = false

# External refs
var _player_ref: CharacterBody2D
var _town_hall_ref: Node2D
var _town_hall_pos: Vector2 = Vector2.ZERO
var _joystick_ref: Control
var _quest_tracker_ref: Control

# Step tracking
var _movement_start_pos: Vector2 = Vector2.ZERO
var _tap_hint_panel: PanelContainer = null  # fades out when player nears Town Hall
var _tap_dim: ColorRect = null  # dim overlay for TAP_BUILDING step

# Step UI nodes (cleared between steps)
var _step_nodes: Array[Node] = []


func setup(
	sx: float,
	sy: float,
	player: CharacterBody2D,
	town_hall: Node2D,
	joystick: Control,
	quest_tracker: Control
) -> void:
	_sx = sx
	_sy = sy
	_player_ref = player
	_town_hall_ref = town_hall
	_town_hall_pos = town_hall.position
	_joystick_ref = joystick
	_quest_tracker_ref = quest_tracker
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_show_step")


func _ready() -> void:
	# Set anchors AFTER the node is in the tree (required by Godot 4)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	if _transitioning:
		return
	match _current_step:
		Step.MOVE_AROUND:
			if is_instance_valid(_player_ref):
				if _player_ref.position.distance_to(_movement_start_pos) >= 100.0:
					_advance_step()
		Step.WALK_TO_TOWN_HALL:
			if is_instance_valid(_player_ref):
				if _player_ref.position.distance_to(_town_hall_pos) < 150.0 * _sx:
					_advance_step()
		Step.TAP_BUILDING:
			if is_instance_valid(_player_ref) and is_instance_valid(_tap_hint_panel):
				if _player_ref.position.distance_to(_town_hall_pos) < 150.0 * _sx:
					# Capture refs before nulling so the tween callback can free them
					var hint_ref := _tap_hint_panel
					var dim_ref := _tap_dim
					# Stop the panel from blocking input immediately — the tween
					# is cosmetic only; we must not gate Area2D taps on it.
					hint_ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
					# Walk up to the VBoxContainer wrapper (parent of the panel)
					var hint_wrap := hint_ref.get_parent()
					if is_instance_valid(hint_wrap):
						hint_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
					var tw := create_tween().set_parallel(true)
					(
						tw
						. tween_property(hint_ref, "modulate:a", 0.0, 0.4)
						. set_trans(Tween.TRANS_QUAD)
						. set_ease(Tween.EASE_IN)
					)
					if is_instance_valid(dim_ref):
						(
							tw
							. tween_property(dim_ref, "modulate:a", 0.0, 0.4)
							. set_trans(Tween.TRANS_QUAD)
							. set_ease(Tween.EASE_IN)
						)
					_tap_hint_panel = null
					_tap_dim = null


# ═════════════════════════════════════════════════════════════════════════════
# STEP MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════════


func _advance_step() -> void:
	if _transitioning:
		return
	_transitioning = true
	_clear_step_ui()
	_current_step += 1
	if _current_step >= Step.DONE:
		_finish_tutorial()
		return
	await get_tree().create_timer(0.3).timeout
	_show_step()
	_transitioning = false


func _show_step() -> void:
	match _current_step:
		Step.WELCOME:
			_show_welcome()
		Step.MOVE_AROUND:
			_show_move_around()
		Step.WALK_TO_TOWN_HALL:
			_show_walk_to_town_hall()
		Step.TAP_BUILDING:
			_show_tap_building()
		Step.COMPLETE_QUEST:
			_show_complete_quest()
		Step.POST_QUEST:
			_show_post_quest()


func _clear_step_ui() -> void:
	for node in _step_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_step_nodes.clear()


func _skip_tutorial() -> void:
	if _transitioning:
		return
	_transitioning = true
	_clear_step_ui()
	_finish_tutorial()


func _finish_tutorial() -> void:
	if ApiClient.is_authenticated:
		GameManager.current_student["tutorial_done"] = 1
		NetworkGate.run(
			func(cb: Callable) -> void: ApiClient.patch_me({"tutorialDone": true}, cb),
			func(_data: Dictionary) -> void: pass
		)
	print("[TutorialOverlay] Tutorial completed.")
	tutorial_completed.emit()
	queue_free()


# ═════════════════════════════════════════════════════════════════════════════
# STEP BUILDERS
# ═════════════════════════════════════════════════════════════════════════════


func _show_welcome() -> void:
	var dim := _make_dim_overlay(true)

	# VBox+spacers: reliable vertical centering (avoids CenterContainer bug #97549)
	# Anchors set AFTER add_child so parent size is known
	var vbox_wrap := VBoxContainer.new()
	vbox_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox_wrap)
	vbox_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_step_nodes.append(vbox_wrap)

	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_wrap.add_child(top_space)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(16))
	card.custom_minimum_size = Vector2(700 * _sx, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox_wrap.add_child(card)

	var bot_space := Control.new()
	bot_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bot_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_wrap.add_child(bot_space)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", int(40 * _sx))
	card_margin.add_theme_constant_override("margin_right", int(40 * _sx))
	card_margin.add_theme_constant_override("margin_top", int(32 * _sy))
	card_margin.add_theme_constant_override("margin_bottom", int(32 * _sy))
	card.add_child(card_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(22 * _sy))
	card_margin.add_child(vbox)

	var title := Label.new()
	title.text = "Welcome to your village! 🏡"
	title.add_theme_font_size_override("font_size", int(48 * _sy))
	title.add_theme_color_override("font_color", StyleFactory.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "Your village has lost its voice. Complete reading quests to restore each building, one by one!"
	desc.add_theme_font_size_override("font_size", int(34 * _sy))
	desc.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", int(24 * _sx))
	vbox.add_child(btn_row)

	var skip_btn := _make_skip_button()
	btn_row.add_child(skip_btn)

	var next_btn := _make_primary_button("Next")
	next_btn.pressed.connect(func() -> void: _advance_step())
	btn_row.add_child(next_btn)

	UIAnimations.panel_in(self, card)


func _show_move_around() -> void:
	var dim := _make_dim_overlay(false, 0.25)

	if is_instance_valid(_player_ref):
		_movement_start_pos = _player_ref.position

	var msg := _make_message_panel(
		"Move your character! 🕹️",
		"Use the joystick (bottom-left) to walk around the village.\nOr press Next to continue.",
		true,
		Callable(self, "_advance_step"),
		false,
		true
	)

	# Pulsing glow near joystick area (left side, bottom-ish)
	var vp_size := get_viewport().get_visible_rect().size
	var glow := Panel.new()
	glow.size = Vector2(100 * _sx, 100 * _sy)
	glow.position = Vector2(60 * _sx, vp_size.y * 0.75 - 50 * _sy)
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color(
		StyleFactory.SKY_BLUE.r, StyleFactory.SKY_BLUE.g, StyleFactory.SKY_BLUE.b, 0.15
	)
	glow_style.corner_radius_top_left = 50
	glow_style.corner_radius_top_right = 50
	glow_style.corner_radius_bottom_left = 50
	glow_style.corner_radius_bottom_right = 50
	glow_style.border_width_left = 3
	glow_style.border_width_right = 3
	glow_style.border_width_top = 3
	glow_style.border_width_bottom = 3
	glow_style.border_color = StyleFactory.SKY_BLUE
	glow.add_theme_stylebox_override("panel", glow_style)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	_step_nodes.append(glow)

	var tw := glow.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)


func _show_walk_to_town_hall() -> void:
	var dim := _make_dim_overlay(false, 0.25)

	var msg := _make_message_panel(
		"Walk to the Town Hall! 🏛️",
		"Head toward the Town Hall in the center of the village.\nOr press Next to continue.",
		true,
		Callable(self, "_advance_step"),
		false,
		true
	)

	var arrow := _make_arrow_toward(_town_hall_pos)
	if arrow != null:
		_step_nodes.append(arrow)


func _show_tap_building() -> void:
	_tap_dim = _make_dim_overlay(false, 0.25)

	_tap_hint_panel = _make_message_panel(
		"Tap the Town Hall! 👆", "Tap the glowing building to start your first reading quest!", true
	)

	# Spotlight on town hall building
	if is_instance_valid(_town_hall_ref):
		var vp_size := get_viewport().get_visible_rect().size
		var spotlight := Panel.new()
		spotlight.size = Vector2(120 * _sx, 120 * _sy)
		var camera: Camera2D = get_viewport().get_camera_2d()
		var screen_pos: Vector2 = _town_hall_pos
		if camera != null:
			screen_pos = _town_hall_pos - camera.get_screen_center_position() + vp_size * 0.5
		spotlight.position = screen_pos - Vector2(60 * _sx, 90 * _sy)

		var sp_style := StyleBoxFlat.new()
		sp_style.bg_color = Color(0, 0, 0, 0)
		sp_style.corner_radius_top_left = int(12 * _sx)
		sp_style.corner_radius_top_right = int(12 * _sx)
		sp_style.corner_radius_bottom_left = int(12 * _sx)
		sp_style.corner_radius_bottom_right = int(12 * _sx)
		sp_style.border_width_left = 3
		sp_style.border_width_right = 3
		sp_style.border_width_top = 3
		sp_style.border_width_bottom = 3
		sp_style.border_color = StyleFactory.GOLD
		spotlight.add_theme_stylebox_override("panel", sp_style)
		spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(spotlight)
		_step_nodes.append(spotlight)

		var tw := spotlight.create_tween().set_loops()
		tw.tween_property(spotlight, "modulate:a", 0.4, 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(spotlight, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

	if not QuestManager.quest_started.is_connected(_on_quest_started_for_tutorial):
		QuestManager.quest_started.connect(_on_quest_started_for_tutorial, CONNECT_ONE_SHOT)


func _on_quest_started_for_tutorial(_building_id: String) -> void:
	_advance_step()


func _show_complete_quest() -> void:
	# Brief message at bottom — quest overlay takes over screen
	var msg := _make_message_panel(
		"Answer the questions! 📖",
		"Complete the reading quest to unlock the Town Hall. Good luck!",
		false,
		Callable(),
		true  # at_bottom = true
	)

	var tw := create_tween()
	(
		tw
		. tween_property(msg, "modulate:a", 0.0, 0.5)
		. set_delay(2.0)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)

	if not QuestManager.quest_completed.is_connected(_on_quest_completed_for_tutorial):
		QuestManager.quest_completed.connect(_on_quest_completed_for_tutorial, CONNECT_ONE_SHOT)


func _on_quest_completed_for_tutorial(_building_id: String, _passed: bool, _score: int) -> void:
	get_tree().create_timer(2.5).timeout.connect(
		func() -> void:
			if is_instance_valid(self):
				_advance_step()
	)


func _show_post_quest() -> void:
	var dim := _make_dim_overlay(true)

	# VBox+spacers centering (same pattern as welcome)
	var vbox_wrap := VBoxContainer.new()
	vbox_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox_wrap)
	vbox_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_step_nodes.append(vbox_wrap)

	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_wrap.add_child(top_space)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(16))
	card.custom_minimum_size = Vector2(700 * _sx, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox_wrap.add_child(card)

	var bot_space := Control.new()
	bot_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bot_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_wrap.add_child(bot_space)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", int(40 * _sx))
	card_margin.add_theme_constant_override("margin_right", int(40 * _sx))
	card_margin.add_theme_constant_override("margin_top", int(32 * _sy))
	card_margin.add_theme_constant_override("margin_bottom", int(32 * _sy))
	card.add_child(card_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(20 * _sy))
	card_margin.add_child(vbox)

	var title := Label.new()
	title.text = "You unlocked your first building!"
	title.add_theme_font_size_override("font_size", int(44 * _sy))
	title.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "Check the quest tracker on the right to see what's next. Keep restoring buildings to bring your village back to life!"
	desc.add_theme_font_size_override("font_size", int(32 * _sy))
	desc.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc)

	var btn_center := CenterContainer.new()
	vbox.add_child(btn_center)
	var done_btn := _make_primary_button("Got it!")
	done_btn.pressed.connect(func() -> void: _advance_step())
	btn_center.add_child(done_btn)

	UIAnimations.panel_in(self, card)
	UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.1))


# ═════════════════════════════════════════════════════════════════════════════
# UI HELPERS
# ═════════════════════════════════════════════════════════════════════════════


func _make_dim_overlay(blocks_input: bool, alpha: float = 0.45) -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, alpha)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP if blocks_input else Control.MOUSE_FILTER_IGNORE
	# Tapping outside the tutorial card advances the step.
	# Prevents the blocking dim from silently swallowing building taps (Godot 4:
	# MOUSE_FILTER_STOP calls accept_event() which suppresses Area2D.input_event).
	if blocks_input:
		dim.gui_input.connect(
			func(event: InputEvent) -> void:
				if not _transitioning and (
					(event is InputEventMouseButton and event.pressed)
					or (event is InputEventScreenTouch and event.pressed)
				):
					_advance_step()
		)
	# add_child FIRST, THEN set anchors (required — Godot needs parent in tree)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_step_nodes.append(dim)
	dim.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(dim, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	return dim


func _make_message_panel(
	title_text: String,
	desc_text: String,
	show_skip: bool,
	next_callback: Callable = Callable(),
	at_bottom: bool = false,
	at_center: bool = false
) -> PanelContainer:
	## Returns a compact floating card — positioned at top, center, or bottom.
	## Uses VBox+spacers so panel shrinks to content (no full-height stretch).
	## Anchors set AFTER add_child per Godot 4 requirement.

	var vbox_wrap := VBoxContainer.new()
	vbox_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox_wrap)
	vbox_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_step_nodes.append(vbox_wrap)

	# Top spacer: expanding (bottom/center) OR fixed 50px gap (top)
	var top_space := Control.new()
	top_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if at_bottom or at_center:
		top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		top_space.custom_minimum_size = Vector2(0, 50 * _sy)
	vbox_wrap.add_child(top_space)

	# The card — shrinks to content height, centers horizontally
	var panel := PanelContainer.new()
	var style: StyleBoxFlat = StyleFactory.make_glass_card(14)
	style.bg_color = Color(0.05, 0.09, 0.18, 0.92)
	style.border_width_top = 2
	style.border_color = StyleFactory.SKY_BLUE
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(660 * _sx, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox_wrap.add_child(panel)

	# Bottom spacer: expanding (top/center) OR tiny gap (bottom)
	var bot_space := Control.new()
	bot_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not at_bottom:
		bot_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		bot_space.custom_minimum_size = Vector2(0, 20 * _sy)
	vbox_wrap.add_child(bot_space)

	# Panel content
	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", int(36 * _sx))
	panel_margin.add_theme_constant_override("margin_right", int(36 * _sx))
	panel_margin.add_theme_constant_override("margin_top", int(28 * _sy))
	panel_margin.add_theme_constant_override("margin_bottom", int(28 * _sy))
	panel.add_child(panel_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(16 * _sy))
	panel_margin.add_child(vbox)

	if show_skip:
		var skip_row := HBoxContainer.new()
		skip_row.alignment = BoxContainer.ALIGNMENT_END
		var skip_btn := _make_skip_button()
		skip_row.add_child(skip_btn)
		vbox.add_child(skip_row)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", int(44 * _sy))
	title.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = desc_text
	desc.add_theme_font_size_override("font_size", int(32 * _sy))
	desc.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc)

	if next_callback.is_valid():
		var btn_row := HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_row.add_theme_constant_override("separation", int(18 * _sx))
		vbox.add_child(btn_row)
		var next_btn := _make_primary_button("Next →")
		next_btn.pressed.connect(next_callback)
		btn_row.add_child(next_btn)

	UIAnimations.panel_in(self, panel)
	return panel


func _make_primary_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300 * _sx, 90 * _sy)
	btn.add_theme_font_size_override("font_size", int(36 * _sy))
	btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	btn.ready.connect(func() -> void: UIAnimations.make_interactive(btn))
	return btn


func _make_skip_button() -> Button:
	var btn := Button.new()
	btn.text = "Skip Tutorial"
	btn.custom_minimum_size = Vector2(220 * _sx, 68 * _sy)
	btn.add_theme_font_size_override("font_size", int(26 * _sy))
	btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	btn.pressed.connect(func() -> void: _skip_tutorial())
	return btn


func _make_arrow_toward(target_pos: Vector2) -> Polygon2D:
	if not is_instance_valid(_player_ref):
		return null
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var camera: Camera2D = get_viewport().get_camera_2d()
	var screen_target: Vector2 = target_pos
	if camera != null:
		screen_target = target_pos - camera.get_screen_center_position() + vp_size * 0.5
	var center_screen: Vector2 = vp_size * 0.5
	var dir: Vector2 = (screen_target - center_screen).normalized()
	var arrow_pos: Vector2 = center_screen + dir * 120.0 * _sx

	var arrow := Polygon2D.new()
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var tip: Vector2 = dir * 20.0 * _sx
	var base1: Vector2 = -dir * 10.0 * _sx + perp * 12.0 * _sx
	var base2: Vector2 = -dir * 10.0 * _sx - perp * 12.0 * _sx
	arrow.polygon = PackedVector2Array([tip, base1, base2])
	arrow.color = StyleFactory.GOLD
	arrow.position = arrow_pos
	add_child(arrow)

	var tw := arrow.create_tween().set_loops()
	tw.tween_property(arrow, "modulate:a", 0.4, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(arrow, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	return arrow
