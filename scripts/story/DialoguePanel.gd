extends Control
## DialoguePanel — Bottom-screen dialogue box for Luminara story system.
## Built entirely in code (no .tscn). Matches existing glass_card / StyleFactory patterns.
## Supports typewriter text, mood-based portraits, dialogue choices, and skip.

signal dialogue_sequence_finished
signal choice_selected(choice_key: String)

const CHARS_PER_SECOND := 30.0
const BLIP_INTERVAL := 3  # Play blip every N characters
const AUTO_ADVANCE_DELAY := 3.5

var _sx: float = 1.0
var _sy: float = 1.0

# ── State ─────────────────────────────────────────────────────────────────────
var _sequence: Array[Dictionary] = []
var _current_index: int = -1
var _typing: bool = false
var _waiting_for_choice: bool = false
var _active: bool = false
var _last_advance_frame: int = -1  # deduplicates double-events from touch emulation

# ── Branch support ────────────────────────────────────────────────────────────
# Maps lore keys to their dialogue arrays, set before show_sequence()
var _branches: Dictionary = {}

# ── UI Nodes ──────────────────────────────────────────────────────────────────
var _blocker: ColorRect
var _panel: PanelContainer
var _portrait_panel: PanelContainer
var _portrait_label: Label
var _speaker_label: Label
var _text_label: RichTextLabel
var _continue_label: Label
var _skip_btn: Button
var _choice_container: HBoxContainer
var _content_vbox: VBoxContainer

# ── Tweens ────────────────────────────────────────────────────────────────────
var _typewriter_tween: Tween
var _blink_tween: Tween
var _glow_tween: Tween
var _auto_advance_tween: Tween

func setup(sx: float, sy: float) -> void:
	_sx = sx
	_sy = sy
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layout()


# ═════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═════════════════════════════════════════════════════════════════════════════


## Show a sequence of dialogue lines. Optionally provide branch data for choices.
## branches format: { "lore_1": Array[Dictionary], "prologue_lore": Array[Dictionary] }
func show_sequence(lines: Array[Dictionary], branches: Dictionary = {}) -> void:
	_sequence = lines
	_branches = branches
	_current_index = -1
	_active = true
	_waiting_for_choice = false

	# Show with animation
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Fade blocker in
	_blocker.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_blocker, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)

	# Animate panel in
	UIAnimations.panel_in(self, _panel)

	# Reveal portrait with elastic pop (slight delay)
	_portrait_panel.visible = true
	_portrait_panel.modulate.a = 0.0
	_portrait_panel.scale = Vector2.ZERO
	_portrait_panel.pivot_offset = _portrait_panel.size / 2.0
	await get_tree().create_timer(0.15).timeout
	if not is_instance_valid(self):
		return
	var ptw := create_tween().set_parallel(true)
	(
		ptw
		. tween_property(_portrait_panel, "scale", Vector2.ONE, 0.6)
		. set_trans(Tween.TRANS_ELASTIC)
		. set_ease(Tween.EASE_OUT)
	)
	(
		ptw
		. tween_property(_portrait_panel, "modulate:a", 1.0, 0.25)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)

	# Start first line
	_advance()


## Advance to next line (called on tap or skip button)
func advance() -> void:
	if not _active:
		return

	if _waiting_for_choice:
		return  # Must select a choice

	if _typing:
		# Complete typewriter instantly — auto-advance timer starts after
		_complete_typewriter()
		return

	# Text already fully shown: cancel auto-advance and go to next line immediately
	_cancel_auto_advance()
	_advance()


## Skip all remaining dialogue immediately
func skip_all() -> void:
	if not _active:
		return
	_kill_tweens()
	_hide_panel()


# ═════════════════════════════════════════════════════════════════════════════
# LAYOUT
# ═════════════════════════════════════════════════════════════════════════════


func _build_layout() -> void:
	# ── Blocker (full screen, catches taps to advance) ──
	_blocker = ColorRect.new()
	_blocker.color = Color(0, 0, 0, 0.5)
	_blocker.anchor_right = 1.0
	_blocker.anchor_bottom = 1.0
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.gui_input.connect(_on_blocker_input)
	add_child(_blocker)

	# ── Bottom anchor container ──
	var bottom := Control.new()
	bottom.anchor_left = 0.04
	bottom.anchor_right = 0.96
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_top = -340.0 * _sy
	bottom.offset_bottom = -20.0 * _sy
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)

	# ── Glass card panel ──
	_panel = PanelContainer.new()
	var style := StyleFactory.make_glass_card(20)
	style.content_margin_left = int(44 * _sx)
	style.content_margin_right = int(44 * _sx)
	style.content_margin_top = int(32 * _sy)
	style.content_margin_bottom = int(32 * _sy)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_blocker_input)
	bottom.add_child(_panel)

	# ── Main VBox ──
	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", int(18 * _sy))
	_panel.add_child(_content_vbox)

	# ── Top row: Portrait + Text + Skip ──
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", int(16 * _sx))
	top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_vbox.add_child(top_hbox)

	# Portrait circle
	_portrait_panel = PanelContainer.new()
	var portrait_size := int(120 * minf(_sx, _sy))
	_portrait_panel.custom_minimum_size = Vector2(portrait_size, portrait_size)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = StoryData.MOOD_COLORS.get("hopeful", StyleFactory.GOLD)
	@warning_ignore("integer_division")
	var radius := portrait_size / 2
	portrait_style.corner_radius_top_left = radius
	portrait_style.corner_radius_top_right = radius
	portrait_style.corner_radius_bottom_left = radius
	portrait_style.corner_radius_bottom_right = radius
	portrait_style.shadow_color = Color(
		StyleFactory.GOLD.r, StyleFactory.GOLD.g, StyleFactory.GOLD.b, 0.3
	)
	portrait_style.shadow_size = 8
	portrait_style.shadow_offset = Vector2.ZERO
	portrait_style.anti_aliasing = true
	_portrait_panel.add_theme_stylebox_override("panel", portrait_style)
	_portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(_portrait_panel)

	# Portrait icon
	_portrait_label = Label.new()
	_portrait_label.text = "\u2726"  # ✦
	_portrait_label.add_theme_font_size_override("font_size", int(54 * minf(_sx, _sy)))
	_portrait_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portrait_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_panel.add_child(_portrait_label)

	# Text column
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", int(4 * _sy))
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(text_vbox)

	# Speaker name
	_speaker_label = Label.new()
	_speaker_label.text = "Lumi"
	_speaker_label.add_theme_font_size_override("font_size", int(32 * _sy))
	_speaker_label.add_theme_color_override("font_color", StyleFactory.GOLD)
	_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(_speaker_label)

	# Dialogue text (RichTextLabel for typewriter)
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.add_theme_font_size_override("normal_font_size", int(40 * _sy))
	_text_label.add_theme_color_override("default_color", StyleFactory.TEXT_PRIMARY)
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(_text_label)

	# Skip button
	_skip_btn = Button.new()
	_skip_btn.text = "Skip"
	_skip_btn.add_theme_font_size_override("font_size", int(28 * _sy))
	_skip_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	var skip_style := StyleFactory.make_secondary_button_normal()
	skip_style.content_margin_left = int(20 * _sx)
	skip_style.content_margin_right = int(20 * _sx)
	skip_style.content_margin_top = int(12 * _sy)
	skip_style.content_margin_bottom = int(12 * _sy)
	_skip_btn.add_theme_stylebox_override("normal", skip_style)
	_skip_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	_skip_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	_skip_btn.pressed.connect(
		func() -> void:
			AudioManager.play_sfx("button_tap")
			skip_all()
	)
	_skip_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_hbox.add_child(_skip_btn)
	_skip_btn.ready.connect(func() -> void: UIAnimations.make_interactive(_skip_btn))

	# ── "Tap to continue" indicator ──
	_continue_label = Label.new()
	_continue_label.text = "Tap to continue  \u25bc"
	_continue_label.add_theme_font_size_override("font_size", int(28 * _sy))
	_continue_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_vbox.add_child(_continue_label)

	# ── Choice buttons container (hidden by default) ──
	_choice_container = HBoxContainer.new()
	_choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_container.add_theme_constant_override("separation", int(12 * _sx))
	_choice_container.visible = false
	_choice_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_vbox.add_child(_choice_container)

	# Start glow pulse on portrait
	_start_glow_pulse()


# ═════════════════════════════════════════════════════════════════════════════
# DIALOGUE FLOW
# ═════════════════════════════════════════════════════════════════════════════


func _advance() -> void:
	_current_index += 1

	if _current_index >= _sequence.size():
		# Sequence complete
		_hide_panel()
		return

	var line: Dictionary = _sequence[_current_index]
	_show_line(line)


func _show_line(line: Dictionary) -> void:
	_cancel_auto_advance()

	var speaker: String = line.get("speaker", "Lumi")
	var mood: String = line.get("mood", "hopeful")
	var text: String = line.get("text", "")
	var choices: Array = line.get("choices", [])

	# Update speaker
	_speaker_label.text = speaker

	# Update mood (portrait color + panel border)
	_update_mood(mood)

	# Hide choices, show continue label
	_choice_container.visible = false
	_continue_label.visible = true
	_waiting_for_choice = false

	# Fade out old text, then type new text
	if _text_label.text.length() > 0:
		var fade_tw := create_tween()
		(
			fade_tw
			. tween_property(_text_label, "modulate:a", 0.0, 0.15)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_IN)
		)
		await fade_tw.finished
		if not is_instance_valid(self):
			return

	# Set new text and start typewriter
	_text_label.text = text
	_text_label.visible_characters = 0
	_text_label.modulate.a = 1.0

	# Slight upward slide for new text
	var orig_y := _text_label.position.y
	_text_label.position.y += 5 * _sy
	var slide_tw := create_tween()
	(
		slide_tw
		. tween_property(_text_label, "position:y", orig_y, 0.2)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)

	AudioManager.play_sfx("button_tap")  # dialogue_advance (falls back to button_tap)

	_start_typewriter(text, choices)


func _start_typewriter(text: String, choices: Array) -> void:
	_typing = true
	var char_count := text.length()
	if char_count == 0:
		_typing = false
		_on_typewriter_done(choices)
		return

	var duration := float(char_count) / CHARS_PER_SECOND

	_typewriter_tween = create_tween()
	(
		_typewriter_tween
		. tween_method(
			func(val: float) -> void:
				if not is_instance_valid(_text_label):
					return
				var chars := int(val)
				# Play blip at intervals
				if (
					chars > 0
					and chars % BLIP_INTERVAL == 0
					and chars != _text_label.visible_characters
				):
					AudioManager.play_sfx("button_tap")  # dialogue_blip (falls back to button_tap)
				_text_label.visible_characters = chars,
			0.0,
			float(char_count),
			duration
		)
		. set_trans(Tween.TRANS_LINEAR)
	)

	_typewriter_tween.tween_callback(
		func() -> void:
			_typing = false
			_on_typewriter_done(choices)
	)


func _complete_typewriter() -> void:
	if _typewriter_tween and _typewriter_tween.is_running():
		_typewriter_tween.kill()
	_text_label.visible_characters = -1  # Show all
	_typing = false

	# Check if current line has choices
	if _current_index >= 0 and _current_index < _sequence.size():
		var choices: Array = _sequence[_current_index].get("choices", [])
		_on_typewriter_done(choices)


func _on_typewriter_done(choices: Array) -> void:
	if choices.size() > 0:
		_show_choices(choices)
	else:
		# Show "tap to continue" with blink, then auto-advance after delay
		_continue_label.visible = true
		_start_blink()
		_start_auto_advance(AUTO_ADVANCE_DELAY)


func _show_choices(choices: Array) -> void:
	_continue_label.visible = false
	_waiting_for_choice = true

	# Clear old choice buttons
	for child in _choice_container.get_children():
		child.queue_free()

	# Create choice buttons
	var colors: Array[Color] = [
		StyleFactory.SKY_BLUE, StyleFactory.GOLD, StyleFactory.SUCCESS_GREEN
	]
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = choice.get("label", "...")
		btn.custom_minimum_size = Vector2(420 * _sx, 90 * _sy)
		btn.add_theme_font_size_override("font_size", int(34 * _sy))
		btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)

		var btn_style := StyleFactory.make_secondary_button_normal()
		btn_style.border_color = colors[i % colors.size()]
		btn.add_theme_stylebox_override("normal", btn_style)
		var btn_hover := StyleFactory.make_secondary_button_hover()
		btn_hover.border_color = colors[i % colors.size()]
		btn_hover.bg_color = Color(
			colors[i % colors.size()].r,
			colors[i % colors.size()].g,
			colors[i % colors.size()].b,
			0.1
		)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())

		var next_key: String = choice.get("next", "end")
		btn.pressed.connect(
			func() -> void:
				AudioManager.play_sfx("button_tap")
				_on_choice_pressed(btn, next_key)
		)
		_choice_container.add_child(btn)
		btn.ready.connect(func() -> void: UIAnimations.make_interactive(btn))

	_choice_container.visible = true

	# Stagger entrance
	UIAnimations.stagger_children(self, _choice_container, 0.07)


func _on_choice_pressed(selected_btn: Button, next_key: String) -> void:
	_waiting_for_choice = false

	# Pop selected button, fade others
	for child in _choice_container.get_children():
		if child == selected_btn:
			child.pivot_offset = child.size / 2.0
			var pop_tw := create_tween()
			(
				pop_tw
				. tween_property(child, "scale", Vector2(1.06, 1.06), 0.1)
				. set_trans(Tween.TRANS_BACK)
				. set_ease(Tween.EASE_OUT)
			)
			pop_tw.tween_property(child, "scale", Vector2.ONE, 0.1)
		else:
			var fade_tw := create_tween()
			fade_tw.tween_property(child, "modulate:a", 0.0, 0.2)

	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self):
		return

	choice_selected.emit(next_key)

	if next_key == "end":
		# Continue with remaining lines in sequence
		_choice_container.visible = false
		_continue_label.visible = true
		_advance()
	else:
		# Branch: insert branch lines into sequence after current index
		var branch_lines: Array = _branches.get(next_key, [])
		if branch_lines.size() > 0:
			var personalized: Array[Dictionary] = []
			var username: String = GameManager.current_student.get(
				"username", GameManager.current_student.get("name", "")
			)
			for line in branch_lines:
				var p: Dictionary = line.duplicate()
				p["text"] = StoryData.personalize(p.get("text", ""), username)
				personalized.append(p)

			# Insert branch lines right after current index
			var insert_pos := _current_index + 1
			for j in personalized.size():
				_sequence.insert(insert_pos + j, personalized[j])

		_choice_container.visible = false
		_continue_label.visible = true
		_advance()


# ═════════════════════════════════════════════════════════════════════════════
# MOOD & VISUAL
# ═════════════════════════════════════════════════════════════════════════════


func _update_mood(mood: String) -> void:
	var color: Color = StoryData.MOOD_COLORS.get(mood, StyleFactory.GOLD)

	# Animate portrait ring color
	var portrait_style: StyleBoxFlat = _portrait_panel.get_theme_stylebox("panel").duplicate()
	portrait_style.bg_color = color
	portrait_style.shadow_color = Color(color.r, color.g, color.b, 0.4)
	_portrait_panel.add_theme_stylebox_override("panel", portrait_style)

	# Animate panel top border color
	var panel_style: StyleBoxFlat = _panel.get_theme_stylebox("panel").duplicate()
	panel_style.border_width_top = 3
	panel_style.border_color = color
	_panel.add_theme_stylebox_override("panel", panel_style)


func _start_glow_pulse() -> void:
	# Subtle pulse on portrait shadow — gives Lumi a "living light" feel
	_glow_tween = create_tween().set_loops()
	(
		_glow_tween
		. tween_method(
			func(val: float) -> void:
				if not is_instance_valid(_portrait_panel):
					return
				var style: StyleBoxFlat = _portrait_panel.get_theme_stylebox("panel").duplicate()
				style.shadow_size = int(val)
				_portrait_panel.add_theme_stylebox_override("panel", style),
			6.0,
			10.0,
			1.0
		)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	(
		_glow_tween
		. tween_method(
			func(val: float) -> void:
				if not is_instance_valid(_portrait_panel):
					return
				var style: StyleBoxFlat = _portrait_panel.get_theme_stylebox("panel").duplicate()
				style.shadow_size = int(val)
				_portrait_panel.add_theme_stylebox_override("panel", style),
			10.0,
			6.0,
			1.0
		)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)


func _start_blink() -> void:
	if _blink_tween and _blink_tween.is_running():
		_blink_tween.kill()
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(_continue_label, "modulate:a", 0.3, 0.4).set_trans(Tween.TRANS_SINE)
	_blink_tween.tween_property(_continue_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)


# ═════════════════════════════════════════════════════════════════════════════
# HIDE / CLEANUP
# ═════════════════════════════════════════════════════════════════════════════


func _hide_panel() -> void:
	_active = false
	_kill_tweens()

	# Fade blocker
	var blocker_tw := create_tween()
	(
		blocker_tw
		. tween_property(_blocker, "modulate:a", 0.0, 0.2)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)

	# Slide panel out
	await UIAnimations.panel_out(self, _panel)

	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Reset state
	_sequence.clear()
	_branches.clear()
	_current_index = -1
	_typing = false
	_waiting_for_choice = false

	dialogue_sequence_finished.emit()


func _kill_tweens() -> void:
	if _typewriter_tween and _typewriter_tween.is_running():
		_typewriter_tween.kill()
	if _blink_tween and _blink_tween.is_running():
		_blink_tween.kill()
	if _glow_tween and _glow_tween.is_running():
		_glow_tween.kill()
	_cancel_auto_advance()
	_typing = false


func _start_auto_advance(delay: float) -> void:
	_cancel_auto_advance()
	_auto_advance_tween = create_tween()
	_auto_advance_tween.tween_interval(delay)
	_auto_advance_tween.tween_callback(
		func() -> void:
			if _active and not _typing and not _waiting_for_choice:
				_advance()
	)


func _cancel_auto_advance() -> void:
	if _auto_advance_tween and _auto_advance_tween.is_running():
		_auto_advance_tween.kill()
	_auto_advance_tween = null


# ═════════════════════════════════════════════════════════════════════════════
# INPUT
# ═════════════════════════════════════════════════════════════════════════════


func _on_blocker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance_once()
	elif event is InputEventScreenTouch and event.pressed:
		_advance_once()


func _advance_once() -> void:
	# Guard against double-firing (Godot emulates MouseButton from ScreenTouch,
	# so one tap can produce two events in the same frame).
	var frame := Engine.get_process_frames()
	if frame == _last_advance_frame:
		return
	_last_advance_frame = frame
	advance()
