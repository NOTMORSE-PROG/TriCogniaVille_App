extends CanvasLayer
## TownCelebration — Grand finale for completing all 8 buildings.
## Plays fireworks, confetti rain, golden glow on all buildings,
## and a congratulations overlay with player stats.
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
	# ── 1. Fireworks (t=0) ──────────────────────────────────────────────────
	_launch_fireworks()

	# ── 2. Golden glow on all buildings (t=1s) ──────────────────────────────
	get_tree().create_timer(1.0).timeout.connect(_apply_golden_glow)

	# ── 3. Confetti rain (t=1s) ─────────────────────────────────────────────
	get_tree().create_timer(1.0).timeout.connect(_launch_confetti)

	# ── 4. Congratulations overlay (t=2.5s) ─────────────────────────────────
	get_tree().create_timer(2.5).timeout.connect(_show_overlay)

	# ── 5. Celebration music ─────────────────────────────────────────────────
	_play_celebration_music()


func _launch_fireworks() -> void:
	var positions := [
		Vector2(_vp.x * 0.22, _vp.y * 0.25),
		Vector2(_vp.x * 0.50, _vp.y * 0.18),
		Vector2(_vp.x * 0.78, _vp.y * 0.25),
		Vector2(_vp.x * 0.38, _vp.y * 0.20),
	]
	for i in positions.size():
		var fw_color: Color = BUILDING_COLORS[i % BUILDING_COLORS.size()]
		var delay := float(i) * 0.6
		get_tree().create_timer(delay).timeout.connect(
			func() -> void: _spawn_firework(positions[i], fw_color)
		)
	# Repeat burst wave at t=3s
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		for i in 3:
			var fw_color2: Color = BUILDING_COLORS[(i + 2) % BUILDING_COLORS.size()]
			get_tree().create_timer(float(i) * 0.5).timeout.connect(
				func() -> void: _spawn_firework(positions[i % positions.size()], fw_color2)
			)
	)


func _spawn_firework(pos: Vector2, color: Color) -> void:
	var fw := CPUParticles2D.new()
	fw.emitting = false
	fw.one_shot = true
	fw.explosiveness = 0.95
	fw.amount = 28
	fw.lifetime = 1.8
	fw.spread = 180.0
	fw.gravity = Vector2(0, 200)
	fw.initial_velocity_min = 160.0
	fw.initial_velocity_max = 300.0
	fw.scale_amount_min = 3.5
	fw.scale_amount_max = 7.0
	fw.color = color
	fw.position = pos
	# Color: bright burst fading to transparent
	var grad := Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 1.0))
	grad.add_point(0.3, Color(1.0, 1.0, 0.8, 0.9))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	fw.color_ramp = grad
	add_child(fw)
	fw.emitting = true
	# Also spawn a white flash burst for the explosion center
	var flash := CPUParticles2D.new()
	flash.emitting = false
	flash.one_shot = true
	flash.explosiveness = 1.0
	flash.amount = 8
	flash.lifetime = 0.4
	flash.spread = 180.0
	flash.gravity = Vector2(0, 0)
	flash.initial_velocity_min = 20.0
	flash.initial_velocity_max = 60.0
	flash.scale_amount_min = 4.0
	flash.scale_amount_max = 10.0
	flash.color = Color(1.0, 1.0, 0.9, 0.9)
	flash.position = pos
	add_child(flash)
	flash.emitting = true


func _launch_confetti() -> void:
	var confetti := CPUParticles2D.new()
	confetti.name = "ConfettiRain"
	confetti.emitting = true
	confetti.one_shot = false
	confetti.amount = 45
	confetti.lifetime = 5.0
	confetti.explosiveness = 0.0
	confetti.spread = 180.0
	confetti.direction = Vector2(0, 1)
	confetti.gravity = Vector2(20, 60)
	confetti.initial_velocity_min = 40.0
	confetti.initial_velocity_max = 90.0
	confetti.angular_velocity_min = -120.0
	confetti.angular_velocity_max = 120.0
	confetti.scale_amount_min = 3.0
	confetti.scale_amount_max = 8.0
	confetti.position = Vector2(_vp.x * 0.5, -10)
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.emission_rect_extents = Vector2(_vp.x * 0.5, 5)
	# Multi-color gradient cycling through celebration palette
	var grad := Gradient.new()
	grad.set_color(0, Color(0.886, 0.725, 0.290, 0.9))   # gold
	grad.add_point(0.2, Color(0.914, 0.388, 0.431, 0.9)) # coral
	grad.add_point(0.4, Color(0.392, 0.769, 0.910, 0.9)) # sky blue
	grad.add_point(0.6, Color(0.357, 0.851, 0.635, 0.9)) # green
	grad.add_point(0.8, Color(0.698, 0.533, 0.886, 0.9)) # lavender
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	confetti.color_ramp = grad
	add_child(confetti)
	# Stop emitting after 5s but let existing particles finish
	get_tree().create_timer(5.0).timeout.connect(func() -> void:
		if is_instance_valid(confetti):
			confetti.emitting = false
	)


func _apply_golden_glow() -> void:
	for id in _building_controllers:
		var bc = _building_controllers[id]
		if is_instance_valid(bc) and bc.is_unlocked:
			var sprite = bc.get_node_or_null("Sprite2D")
			if sprite and sprite.material is ShaderMaterial:
				var tw := bc.create_tween()
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

	# ── Star decorations ────────────────────────────────────────────────────
	for i in 5:
		var star := Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", int(randf_range(18, 30) * _sy))
		star.add_theme_color_override("font_color", StyleFactory.GOLD)
		star.anchor_left = randf_range(0.05, 0.95)
		star.anchor_top = randf_range(0.05, 0.85)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.modulate.a = randf_range(0.4, 0.9)
		add_child(star)

	# ── Trophy icon ──────────────────────────────────────────────────────────
	var trophy := Label.new()
	trophy.text = "🏆"
	trophy.add_theme_font_size_override("font_size", int(58 * _sy))
	trophy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trophy.anchor_left = 0.0
	trophy.anchor_right = 1.0
	trophy.anchor_top = 0.15
	trophy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(trophy)
	trophy.modulate.a = 0.0

	# ── "Congratulations!" title ──────────────────────────────────────────────
	var title := Label.new()
	title.text = "Congratulations!"
	title.add_theme_font_size_override("font_size", int(48 * _sy))
	title.add_theme_color_override("font_color", StyleFactory.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.05
	title.anchor_right = 0.95
	title.anchor_top = 0.30
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	title.modulate.a = 0.0

	# ── Subtitle ──────────────────────────────────────────────────────────────
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

	# ── Stats row ────────────────────────────────────────────────────────────
	var stats_container := HBoxContainer.new()
	stats_container.anchor_left = 0.1
	stats_container.anchor_right = 0.9
	stats_container.anchor_top = 0.55
	stats_container.size = Vector2(_vp.x * 0.8, 80 * _sy)
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_container.add_theme_constant_override("separation", int(32 * _sx))
	stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats_container)
	stats_container.modulate.a = 0.0

	var student := GameManager.current_student
	var quests_done: int = student.get("quests_completed", student.get("questsCompleted", 0))
	var badges_count: int = student.get("badges_count", student.get("badgesCount", GameManager.unlocked_buildings.size()))

	_add_stat_card(stats_container, "🏘️", "8 / 8", "Buildings")
	_add_stat_card(stats_container, "📚", str(quests_done), "Quests")
	_add_stat_card(stats_container, "🏅", str(badges_count), "Badges")

	# ── Tap to continue hint ──────────────────────────────────────────────────
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

	# ── Animate everything in ────────────────────────────────────────────────
	await bg_tw.finished
	UIAnimations.elastic_reveal(self, trophy)
	await get_tree().create_timer(0.25).timeout
	UIAnimations.elastic_reveal(self, title)
	await get_tree().create_timer(0.25).timeout
	UIAnimations.fade_in_up(self, subtitle)
	await get_tree().create_timer(0.3).timeout
	UIAnimations.stagger_children(self, stats_container, 0.0)
	stats_container.modulate.a = 1.0
	await get_tree().create_timer(0.4).timeout
	UIAnimations.fade_in_up(self, hint)

	# ── Wait for tap or 6s auto-dismiss ──────────────────────────────────────
	var dismissed := false
	var dismiss_fn := func() -> void:
		if not dismissed:
			dismissed = true
			_dismiss()

	# Input listener
	bg.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventScreenTouch and ev.pressed) or \
				(ev is InputEventMouseButton and ev.pressed):
			dismiss_fn.call()
	)
	get_tree().create_timer(6.5).timeout.connect(dismiss_fn)


func _add_stat_card(parent: Control, icon: String, value: String, label_text: String) -> void:
	var card := VBoxContainer.new()
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_theme_constant_override("separation", int(4 * _sy))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", int(30 * _sy))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", int(26 * _sy))
	val_lbl.add_theme_color_override("font_color", StyleFactory.GOLD)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(val_lbl)

	var cat_lbl := Label.new()
	cat_lbl.text = label_text
	cat_lbl.add_theme_font_size_override("font_size", int(15 * _sy))
	cat_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(cat_lbl)

	parent.add_child(card)


func _dismiss() -> void:
	# Fade out glow on all buildings
	for id in _building_controllers:
		var bc = _building_controllers[id]
		if is_instance_valid(bc):
			var sprite = bc.get_node_or_null("Sprite2D")
			if sprite and sprite.material is ShaderMaterial:
				var tw := bc.create_tween()
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
		var ctw := child.create_tween()
		ctw.tween_property(child, "modulate:a", 0.0, 0.6)

	await get_tree().create_timer(0.7).timeout

	# Stop celebration music, restore village BGM
	if is_instance_valid(_music_player):
		var fade_tw := _music_player.create_tween()
		fade_tw.tween_property(_music_player, "volume_db", -40.0, 0.8)
		await fade_tw.finished
		_music_player.stop()
	AudioManager.start_village_music()

	finished.emit()
	queue_free()


func _play_celebration_music() -> void:
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
