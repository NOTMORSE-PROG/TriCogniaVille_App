extends CanvasLayer
## TownCelebration — Grand finale for completing all 8 buildings.
## Plays fireworks (with Kenney spark textures), confetti rain (star textures),
## golden glow on all buildings, and a polished congratulations overlay
## with bokeh particle background, styled trophy, glass-card stat cards,
## count-up number animations, and a skip button.
##
## Usage (from TownLivener):
##   var cel = TownCelebration.new()
##   get_tree().root.add_child(cel)
##   cel.finished.connect(my_callback)
##   cel.start(vp, sx, sy, building_controllers)

signal finished

# Building accent colors in unlock order (for fireworks)
const BUILDING_COLORS := [
	Color("#E8C547"), Color("#5B9BD5"), Color("#C07B3A"), Color("#9AA8BF"),
	Color("#8B5CF6"), Color("#3E8948"), Color("#EB6B1F"), Color("#E94560"),
]

var _vp: Vector2
var _sx: float
var _sy: float
var _building_controllers: Dictionary
var _glow_tweens: Array[Tween] = []
var _music_player: AudioStreamPlayer



func _init() -> void:
	layer = 20
	name = "TownCelebration"


func start(vp: Vector2, sx: float, sy: float, building_controllers: Dictionary) -> void:
	_vp = vp
	_sx = sx
	_sy = sy
	_building_controllers = building_controllers

	_run_sequence()


func _run_sequence() -> void:
	# ── 1. Golden glow on all buildings ────────────────────────────────────────
	_apply_golden_glow()

	# ── 2. Congratulations overlay (t=1s) ──────────────────────────────────────
	get_tree().create_timer(1.0).timeout.connect(_show_overlay)

	# ── 3. Celebration music ───────────────────────────────────────────────────
	_play_celebration_music()


func _apply_golden_glow() -> void:
	for id in _building_controllers:
		var bc = _building_controllers[id]
		if is_instance_valid(bc) and bc.is_unlocked:
			var sprite = bc.get_node_or_null("Sprite2D")
			if sprite and sprite.material is ShaderMaterial:
				var tw: Tween = bc.create_tween()
				tw.tween_method(
					func(v: float) -> void:
						if is_instance_valid(sprite) and sprite.material is ShaderMaterial:
							(sprite.material as ShaderMaterial).set_shader_parameter("glow_amount", v),
					0.0, 0.8, 1.2
				)
				_glow_tweens.append(tw)


func _show_overlay() -> void:
	# Background panel
	var bg := ColorRect.new()
	bg.color = Color(
		StyleFactory.BG_DEEP.r, StyleFactory.BG_DEEP.g, StyleFactory.BG_DEEP.b, 0.88
	)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	bg.modulate.a = 0.0
	var bg_tw := create_tween()
	bg_tw.tween_property(bg, "modulate:a", 1.0, 0.5)

	# ── Bokeh particle background (gold-tinted floating particles) ──────────
	var bokeh_shader_path := "res://assets/shaders/bokeh_particles.gdshader"
	if ResourceLoader.exists(bokeh_shader_path):
		var bokeh_rect := ColorRect.new()
		bokeh_rect.anchor_right = 1.0
		bokeh_rect.anchor_bottom = 1.0
		bokeh_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bokeh_mat := ShaderMaterial.new()
		bokeh_mat.shader = load(bokeh_shader_path)
		bokeh_mat.set_shader_parameter("particle_count", 18.0)
		bokeh_mat.set_shader_parameter("particle_size", 0.012)
		bokeh_mat.set_shader_parameter("speed", 0.02)
		bokeh_mat.set_shader_parameter("particle_color", Color(0.886, 0.725, 0.290, 0.10))
		bokeh_rect.material = bokeh_mat
		add_child(bokeh_rect)

	# ── Styled trophy composition ───────────────────────────────────────────
	var trophy_container := CenterContainer.new()
	trophy_container.anchor_left = 0.3
	trophy_container.anchor_right = 0.7
	trophy_container.anchor_top = 0.10
	trophy_container.anchor_bottom = 0.28
	trophy_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(trophy_container)

	# Gold circular panel background
	var trophy_bg := Panel.new()
	var trophy_style := StyleBoxFlat.new()
	var trophy_radius := int(60 * _sy)
	trophy_style.bg_color = Color(0.886, 0.725, 0.290, 0.20)
	trophy_style.border_color = Color(0.886, 0.725, 0.290, 0.35)
	trophy_style.border_width_left = int(2 * _sx)
	trophy_style.border_width_right = int(2 * _sx)
	trophy_style.border_width_top = int(2 * _sy)
	trophy_style.border_width_bottom = int(2 * _sy)
	trophy_style.corner_radius_top_left = trophy_radius
	trophy_style.corner_radius_top_right = trophy_radius
	trophy_style.corner_radius_bottom_left = trophy_radius
	trophy_style.corner_radius_bottom_right = trophy_radius
	trophy_style.anti_aliasing = true
	trophy_bg.add_theme_stylebox_override("panel", trophy_style)
	trophy_bg.custom_minimum_size = Vector2(120 * _sy, 120 * _sy)
	trophy_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trophy_container.add_child(trophy_bg)

	# Trophy emoji inside
	var trophy := Label.new()
	trophy.text = "★"
	trophy.add_theme_color_override("font_color", StyleFactory.GOLD)
	trophy.add_theme_font_size_override("font_size", int(72 * _sy))
	trophy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trophy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trophy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trophy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trophy_bg.add_child(trophy)

	trophy_container.modulate.a = 0.0

	# ── "Congratulations!" title ────────────────────────────────────────────
	var title := Label.new()
	title.text = "Congratulations!"
	title.add_theme_font_size_override("font_size", int(48 * _sy))
	title.add_theme_color_override("font_color", StyleFactory.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.05
	title.anchor_right = 0.95
	title.anchor_top = 0.32
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	title.modulate.a = 0.0

	# ── Subtitle ────────────────────────────────────────────────────────────
	var subtitle := Label.new()
	subtitle.text = "You restored the village!"
	subtitle.add_theme_font_size_override("font_size", int(28 * _sy))
	subtitle.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.anchor_left = 0.05
	subtitle.anchor_right = 0.95
	subtitle.anchor_top = 0.42
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)
	subtitle.modulate.a = 0.0

	# ── Glass-card stat row ─────────────────────────────────────────────────
	var stats_container := HBoxContainer.new()
	stats_container.anchor_left = 0.08
	stats_container.anchor_right = 0.92
	stats_container.anchor_top = 0.53
	stats_container.custom_minimum_size = Vector2(0, 130 * _sy)
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_container.add_theme_constant_override("separation", int(24 * _sx))
	stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats_container)
	stats_container.modulate.a = 0.0

	var student := GameManager.current_student
	var xp: int = student.get("xp", 0)
	var reading_level: int = student.get("reading_level", 1)

	_add_stat_card(stats_container, "⌂", GameManager.unlocked_buildings.size(), "Buildings", StyleFactory.GOLD)
	_add_stat_card(stats_container, "✦", xp, "XP", StyleFactory.ACCENT_CORAL)
	_add_stat_card(stats_container, "◆", reading_level, "Level", StyleFactory.SKY_BLUE)

	# ── Tap to continue hint ────────────────────────────────────────────────
	var hint := Label.new()
	hint.text = "Tap anywhere to continue"
	hint.add_theme_font_size_override("font_size", int(18 * _sy))
	hint.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.anchor_left = 0.05
	hint.anchor_right = 0.95
	hint.anchor_top = 0.88
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	hint.modulate.a = 0.0

	# ── Skip button (top-right, delayed fade-in) ───────────────────────────
	var skip_btn := Button.new()
	skip_btn.text = "Skip >"
	skip_btn.flat = true
	skip_btn.add_theme_font_size_override("font_size", int(16 * _sy))
	skip_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	skip_btn.anchor_left = 0.82
	skip_btn.anchor_right = 0.96
	skip_btn.anchor_top = 0.03
	skip_btn.anchor_bottom = 0.08
	skip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(skip_btn)
	skip_btn.modulate.a = 0.0

	# ── Animate everything in ───────────────────────────────────────────────
	await bg_tw.finished
	UIAnimations.elastic_reveal(self, trophy_container)
	await get_tree().create_timer(0.25).timeout
	UIAnimations.elastic_reveal(self, title)
	await get_tree().create_timer(0.25).timeout
	UIAnimations.fade_in_up(self, subtitle)
	await get_tree().create_timer(0.3).timeout
	UIAnimations.stagger_children(self, stats_container, 0.0)
	stats_container.modulate.a = 1.0
	await get_tree().create_timer(0.4).timeout
	UIAnimations.fade_in_up(self, hint)
	# Skip button fades in after 1s delay
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if is_instance_valid(skip_btn):
			UIAnimations.fade_in_up(self, skip_btn)
	)

	# ── Wait for tap or 10s auto-dismiss ────────────────────────────────────
	var dismissed := false
	var dismiss_fn := func() -> void:
		if not dismissed:
			dismissed = true
			_dismiss()

	# Input listener on bg
	bg.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventScreenTouch and ev.pressed) or \
				(ev is InputEventMouseButton and ev.pressed):
			dismiss_fn.call()
	)
	skip_btn.pressed.connect(dismiss_fn)
	get_tree().create_timer(10.0).timeout.connect(dismiss_fn)


func _add_stat_card(
	parent: Control, icon: String, value: int, label_text: String, accent_color: Color
) -> void:
	# Glass-card panel wrapper
	var card_panel := PanelContainer.new()
	card_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(16))
	card_panel.custom_minimum_size = Vector2(140 * _sx, 120 * _sy)
	card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var card_vbox := VBoxContainer.new()
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_theme_constant_override("separation", int(4 * _sy))
	card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_panel.add_child(card_vbox)

	# Accent bar at top
	var accent := ColorRect.new()
	accent.color = accent_color
	accent.custom_minimum_size = Vector2(0, 3 * _sy)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_vbox.add_child(accent)

	# Icon emoji
	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", int(30 * _sy))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_vbox.add_child(icon_lbl)

	# Value with count-up animation
	var val_lbl := Label.new()
	val_lbl.text = "0"
	val_lbl.add_theme_font_size_override("font_size", int(26 * _sy))
	val_lbl.add_theme_color_override("font_color", StyleFactory.GOLD)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_vbox.add_child(val_lbl)

	# Category label
	var cat_lbl := Label.new()
	cat_lbl.text = label_text
	cat_lbl.add_theme_font_size_override("font_size", int(15 * _sy))
	cat_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_vbox.add_child(cat_lbl)

	parent.add_child(card_panel)

	# Count-up number animation (0 → value over 0.8s, delayed until card is visible)
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if not is_instance_valid(val_lbl):
			return
		var count_tw := val_lbl.create_tween()
		count_tw.tween_method(
			func(v: int) -> void:
				if is_instance_valid(val_lbl):
					val_lbl.text = str(v),
			0, value, 0.8
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

	# Icon scale pulse
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if is_instance_valid(icon_lbl):
			UIAnimations.scale_pulse(self, icon_lbl, 1.2, 0.4)
	)


func _dismiss() -> void:
	# Fade out glow on all buildings
	for id in _building_controllers:
		var bc = _building_controllers[id]
		if is_instance_valid(bc):
			var sprite = bc.get_node_or_null("Sprite2D")
			if sprite and sprite.material is ShaderMaterial:
				var tw: Tween = bc.create_tween()
				tw.tween_method(
					func(v: float) -> void:
						if is_instance_valid(sprite) and sprite.material is ShaderMaterial:
							(sprite.material as ShaderMaterial).set_shader_parameter("glow_amount", v),
					0.8, 0.0, 0.8
				)

	# Fade out this overlay
	var tw := create_tween()
	tw.tween_property(self, "offset", Vector2.ZERO, 0.0)  # dummy to get a tween started
	# Modulate all children out
	for child in get_children():
		if not child is CanvasItem:
			continue
		var ctw := child.create_tween()
		ctw.tween_property(child, "modulate:a", 0.0, 0.6)

	await get_tree().create_timer(0.7).timeout

	# Stop celebration music, restore village BGM
	if is_instance_valid(_music_player):
		var fade_tw := _music_player.create_tween()
		fade_tw.tween_property(_music_player, "volume_db", -40.0, 1.2)
		await fade_tw.finished
		_music_player.stop()
	AudioManager.start_village_music()

	finished.emit()
	queue_free()


func _play_celebration_music() -> void:
	if not AudioManager.music_enabled:
		return
	var path := "res://assets/audio/ambient/celebration.ogg"
	if not ResourceLoader.exists(path):
		push_warning("[TownCelebration] Celebration music not found: %s" % path)
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -40.0
	add_child(_music_player)
	var stream = load(path)
	_music_player.stream = stream
	AudioManager.stop_village_music()
	_music_player.play()
	var tw := _music_player.create_tween()
	tw.tween_property(_music_player, "volume_db", -8.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
