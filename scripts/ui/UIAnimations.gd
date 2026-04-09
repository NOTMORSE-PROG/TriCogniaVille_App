class_name UIAnimations
## UIAnimations — Reusable tween animation utilities for TriCognia Ville UI.
## All functions are static and create auto-managed tweens.

# ── Panel Transitions ─────────────────────────────────────────────────────────


## Slide + fade a panel in from below (or specified direction)
static func panel_in(node: Node, panel: Control, offset_y: float = 50.0) -> void:
	panel.visible = true
	panel.modulate.a = 0.0
	await node.get_tree().process_frame
	if not is_instance_valid(panel):
		return
	var final_y := panel.position.y
	panel.position.y += offset_y

	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_property(panel, "position:y", final_y, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(
		Tween.EASE_OUT
	)


## Slide + fade a panel out downward, then hide
static func panel_out(node: Node, panel: Control, offset_y: float = 40.0) -> Signal:
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	(
		tween
		. tween_property(panel, "position:y", panel.position.y + offset_y, 0.25)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_IN)
	)
	tween.chain().tween_callback(
		func():
			panel.visible = false
			panel.position.y -= offset_y  # Reset position for next show
			panel.modulate.a = 1.0
	)
	return tween.finished


## Crossfade transition between two views (hide old, show new)
static func crossfade(
	node: Node, old_view: Control, new_view: Control, duration: float = 0.3
) -> Signal:
	new_view.visible = true
	new_view.modulate.a = 0.0
	var tween := node.create_tween().set_parallel(true)
	(
		tween
		. tween_property(old_view, "modulate:a", 0.0, duration * 0.6)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	(
		tween
		. tween_property(new_view, "modulate:a", 1.0, duration)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	tween.chain().tween_callback(
		func():
			old_view.visible = false
			old_view.modulate.a = 1.0
	)
	return tween.finished


# ── Slide Transitions (Onboarding) ────────────────────────────────────────────


## Horizontal slide transition between two controls
static func slide_horizontal(
	node: Node, old_ctrl: Control, new_ctrl: Control, direction: int = 1, duration: float = 0.4  # 1 = forward (left), -1 = backward (right)
) -> Signal:
	var width := old_ctrl.size.x
	if width <= 0:
		width = node.get_viewport().get_visible_rect().size.x

	# Position new control offscreen
	new_ctrl.visible = true
	new_ctrl.modulate.a = 0.0
	var new_start_x := new_ctrl.position.x + width * direction
	var old_final_x := old_ctrl.position.x - width * direction * 0.3
	var new_original_x := new_ctrl.position.x
	var old_original_x := old_ctrl.position.x
	new_ctrl.position.x = new_start_x

	var tween := node.create_tween().set_parallel(true)
	# Old slide exits
	(
		tween
		. tween_property(old_ctrl, "position:x", old_final_x, duration)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_IN_OUT)
	)
	(
		tween
		. tween_property(old_ctrl, "modulate:a", 0.0, duration * 0.7)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	# New slide enters
	(
		tween
		. tween_property(new_ctrl, "position:x", new_original_x, duration)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_IN_OUT)
	)
	(
		tween
		. tween_property(new_ctrl, "modulate:a", 1.0, duration * 0.8)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
		. set_delay(duration * 0.2)
	)

	tween.chain().tween_callback(
		func():
			old_ctrl.visible = false
			old_ctrl.position.x = old_original_x
			old_ctrl.modulate.a = 1.0
	)
	return tween.finished


# ── PIN Dot Animation ─────────────────────────────────────────────────────────


## Animate a PIN dot filling with scale pop
static func dot_fill(node: Node, dot: Panel, filled: bool) -> void:
	dot.add_theme_stylebox_override("panel", StyleFactory.make_pin_dot(filled))
	if filled:
		dot.pivot_offset = dot.size / 2.0
		dot.scale = Vector2(1.4, 1.4)
		var tween := node.create_tween()
		tween.tween_property(dot, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(
			Tween.EASE_OUT
		)


## Clear all dots to empty state
static func dots_clear(dots_container: HBoxContainer) -> void:
	for dot in dots_container.get_children():
		if dot is Panel:
			dot.add_theme_stylebox_override("panel", StyleFactory.make_pin_dot(false))
			dot.scale = Vector2.ONE


# ── Error Shake ───────────────────────────────────────────────────────────────


## Shake a control horizontally to indicate error
static func shake_error(node: Node, target: Control) -> Signal:
	var original_x := target.position.x
	var tween := node.create_tween()
	for i in 3:
		tween.tween_property(target, "position:x", original_x + 12, 0.06).set_trans(
			Tween.TRANS_SINE
		)
		tween.tween_property(target, "position:x", original_x - 12, 0.06).set_trans(
			Tween.TRANS_SINE
		)
	tween.tween_property(target, "position:x", original_x, 0.06)
	return tween.finished


# ── Staggered List Entrance ───────────────────────────────────────────────────


## Animate children appearing one by one with stagger
static func stagger_children(node: Node, container: Control, delay: float = 0.07) -> void:
	var index := 0
	for child in container.get_children():
		if child is Control:
			child.modulate.a = 0.0
			var original_y: float = child.position.y
			child.position.y += 25

			var tween := node.create_tween().set_parallel(true)
			(
				tween
				. tween_property(child, "modulate:a", 1.0, 0.3)
				. set_trans(Tween.TRANS_QUAD)
				. set_ease(Tween.EASE_OUT)
				. set_delay(index * delay)
			)
			(
				tween
				. tween_property(child, "position:y", original_y, 0.35)
				. set_trans(Tween.TRANS_BACK)
				. set_ease(Tween.EASE_OUT)
				. set_delay(index * delay)
			)
			index += 1


# ── Celebration / Reveal ──────────────────────────────────────────────────────


## Elastic scale-in for celebration (badges, icons)
static func elastic_reveal(node: Node, target: Control) -> Signal:
	target.pivot_offset = target.size / 2.0
	target.scale = Vector2.ZERO
	target.modulate.a = 0.0
	target.visible = true

	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(target, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_property(target, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	return tween.finished


## Fade in with slight upward motion
static func fade_in_up(node: Node, target: Control, delay: float = 0.0) -> void:
	target.modulate.a = 0.0
	var original_y: float = target.position.y
	target.position.y += 20

	var tween := node.create_tween().set_parallel(true)
	(
		tween
		. tween_property(target, "modulate:a", 1.0, 0.35)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
		. set_delay(delay)
	)
	(
		tween
		. tween_property(target, "position:y", original_y, 0.4)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_OUT)
		. set_delay(delay)
	)


## Brief colored screen flash overlay
static func flash_screen(
	node: Node, color: Color = Color(0.357, 0.851, 0.635, 0.15), duration: float = 0.4
) -> void:
	var flash := ColorRect.new()
	flash.color = color
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(flash)

	var tween := node.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_callback(flash.queue_free)


# ── Button Micro-Interactions ─────────────────────────────────────────────────


## Attach hover/press micro-interactions to a button
static func make_interactive(btn: Button) -> void:
	btn.mouse_entered.connect(
		func():
			btn.pivot_offset = btn.size / 2.0
			var tw := btn.create_tween()
			(
				tw
				. tween_property(btn, "scale", Vector2(1.03, 1.03), 0.12)
				. set_trans(Tween.TRANS_CUBIC)
				. set_ease(Tween.EASE_OUT)
			)
	)
	btn.mouse_exited.connect(
		func():
			btn.pivot_offset = btn.size / 2.0
			var tw := btn.create_tween()
			(
				tw
				. tween_property(btn, "scale", Vector2.ONE, 0.12)
				. set_trans(Tween.TRANS_CUBIC)
				. set_ease(Tween.EASE_OUT)
			)
	)
	btn.button_down.connect(
		func():
			btn.pivot_offset = btn.size / 2.0
			var tw := btn.create_tween()
			(
				tw
				. tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
				. set_trans(Tween.TRANS_QUAD)
				. set_ease(Tween.EASE_IN)
			)
	)
	btn.button_up.connect(
		func():
			btn.pivot_offset = btn.size / 2.0
			var tw := btn.create_tween()
			tw.tween_property(btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(
				Tween.EASE_OUT
			)
	)


# ── Page Indicator Dots ───────────────────────────────────────────────────────


## Animate page indicator dots — active dot becomes wider pill
static func update_page_dots(node: Node, dots: Array, active_index: int) -> void:
	for i in dots.size():
		var dot: Panel = dots[i]
		var is_active := i == active_index
		var target_width := 36.0 if is_active else 16.0
		var color := StyleFactory.ACCENT_CORAL if is_active else StyleFactory.PIN_EMPTY

		var tween := node.create_tween()
		(
			tween
			. tween_property(dot, "custom_minimum_size:x", target_width, 0.25)
			. set_trans(Tween.TRANS_CUBIC)
			. set_ease(Tween.EASE_OUT)
		)

		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.anti_aliasing = true
		dot.add_theme_stylebox_override("panel", style)


# ── Cutscene Helpers ─────────────────────────────────────────────────────────


## Shake a Node2D (e.g. YSortLayer) for screen-shake effect
static func screen_shake(
	node: Node, target: Node2D, intensity: float = 6.0, cycles: int = 4
) -> Signal:
	var original_pos := target.position
	var tween := node.create_tween()
	for i in cycles:
		var x_off := intensity * (1.0 - float(i) / float(cycles))
		var y_off := x_off * 0.5
		tween.tween_property(target, "position", original_pos + Vector2(x_off, y_off), 0.06)
		tween.tween_property(target, "position", original_pos + Vector2(-x_off, -y_off), 0.06)
	tween.tween_property(target, "position", original_pos, 0.06)
	return tween.finished


## Flash overlay on a CanvasLayer (used by UnlockCutscene)
static func flash_screen_on_layer(
	layer: CanvasLayer,
	vp_size: Vector2,
	color: Color = Color(1, 1, 0.9, 0.35),
	duration: float = 0.3,
) -> void:
	var flash := ColorRect.new()
	flash.color = color
	flash.size = vp_size
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	var tween := flash.create_tween()
	(
		tween
		. tween_property(flash, "modulate:a", 0.0, duration)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_callback(flash.queue_free)


# ── Cinematic Reveal Helpers ─────────────────────────────────────────────────


## Typewriter reveal for RichTextLabel — tweens visible_characters 0 → total.
static func typewriter_reveal(
	node: Node, rtl: RichTextLabel, duration: float = 1.5
) -> Signal:
	rtl.visible_characters = 0
	var total := rtl.get_total_character_count()
	if total <= 0:
		await node.get_tree().process_frame
		total = rtl.get_total_character_count()
	var tween := node.create_tween()
	tween.tween_method(
		func(v: int) -> void:
			if is_instance_valid(rtl):
				rtl.visible_characters = v,
		0, total, duration
	).set_trans(Tween.TRANS_LINEAR)
	return tween.finished


## Brief scale pop: 1.0 → peak → 1.0 with elastic easing.
static func scale_pulse(
	node: Node, target: Control, peak: float = 1.15, duration: float = 0.4
) -> Signal:
	target.pivot_offset = target.size / 2.0
	var tween := node.create_tween()
	(
		tween
		. tween_property(target, "scale", Vector2(peak, peak), duration * 0.4)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	(
		tween
		. tween_property(target, "scale", Vector2.ONE, duration * 0.6)
		. set_trans(Tween.TRANS_ELASTIC)
		. set_ease(Tween.EASE_OUT)
	)
	return tween.finished


## Expand a ColorRect from zero width to final_width, staying centered.
static func expand_from_center(
	node: Node, rect: ColorRect, final_width: float, duration: float = 0.6
) -> Signal:
	var center_x := rect.position.x + rect.size.x * 0.5
	rect.size.x = 0.0
	rect.position.x = center_x
	var tween := node.create_tween().set_parallel(true)
	(
		tween
		. tween_property(rect, "size:x", final_width, duration)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_OUT)
	)
	(
		tween
		. tween_property(rect, "position:x", center_x - final_width * 0.5, duration)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_OUT)
	)
	return tween.finished
