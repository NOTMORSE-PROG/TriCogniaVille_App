class_name BuildingController
extends Node2D
## BuildingController — Phase 1 sprite-based visuals.
## Each building is rendered via Sprite2D + building_unlock.gdshader.
## Grayscale: shader color_amount=0.0 (locked) / 1.0 (unlocked).

signal building_tapped(controller: BuildingController)

# ─── Public ──────────────────────────────────────────────────────────────────
var building_id: String = ""
var building_label: String = ""
var building_color: Color = Color.WHITE
var is_unlocked: bool = false

# ─── Scale helpers (set by Main.gd) ──────────────────────────────────────────
var _sx: float = 1.0
var _sy: float = 1.0

# ─── Building dimensions (in 1920×1080 space) ────────────────────────────────
var _bw: float  # base width
var _bh: float  # base height

# ─── Tap debounce ────────────────────────────────────────────────────────────
var _tap_cooldown: bool = false

# ─── Node references ─────────────────────────────────────────────────────────
var _sprite: Sprite2D
var _padlock: Node2D
var _name_label: Label
var _area: Area2D
var _particles: CPUParticles2D



# ─────────────────────────────────────────────────────────────────────────────
## Call right after add_child(). id/label/color from BUILDING_DATA; sx/sy from Main.
func setup(id: String, label: String, color: Color, unlocked: bool, sx: float, sy: float) -> void:
	building_id = id
	building_label = label
	building_color = color
	is_unlocked = unlocked
	_sx = sx
	_sy = sy

	# Dimensions per building type (1920×1080 reference)
	match id:
		"town_hall":
			_bw = 240.0
			_bh = 340.0
		"school":
			_bw = 180.0
			_bh = 260.0
		"inn":
			_bw = 180.0
			_bh = 250.0
		"chapel":
			_bw = 190.0
			_bh = 290.0
		"library":
			_bw = 160.0
			_bh = 290.0
		"market":
			_bw = 220.0
			_bh = 210.0
		"bakery":
			_bw = 170.0
			_bh = 200.0
		"well":
			_bw = 130.0
			_bh = 170.0
		_:
			_bw = 180.0
			_bh = 240.0

	_bw *= _sx
	_bh *= _sy

	_build_visuals()
	_apply_state()


# ─────────────────────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if is_instance_valid(_padlock) and _padlock.visible:
		var t := Time.get_ticks_msec() * 0.0025
		var p := 0.55 + sin(t) * 0.45
		var glow := _padlock.get_node_or_null("Glow")
		if glow:
			glow.modulate.a = p * 0.7
		var body := _padlock.get_node_or_null("Body")
		if body:
			body.modulate = Color.WHITE.lerp(Color("#80D8FF"), p * 0.35)


# ═════════════════════════════════════════════════════════════════════════════
# VISUALS ENTRY POINT
# ═════════════════════════════════════════════════════════════════════════════
func _build_visuals() -> void:
	_build_shadow()
	_build_entrance_path()
	_build_foundation()
	_build_sprite()
	_build_collision()
	_build_padlock()
	_build_name_label()
	_build_touch_area()
	_build_particles()


# ═════════════════════════════════════════════════════════════════════════════
# SHARED STRUCTURE
# ═════════════════════════════════════════════════════════════════════════════
func _build_shadow() -> void:
	# Perspective-correct drop shadow — technique from SDV / Zelda-style 2D RPGs.
	# Shadow is SQUASHED (based on width, not height) and offset diagonally to
	# simulate light coming from upper-left. Sits at z=-2 (behind everything).

	# Half-width used as the radius for perspective squashing
	var sr := _bw * 0.55  # shadow radius (half-width)
	var shy := sr * 0.35  # shadow height squashed to ~35% of radius (perspective)
	var ox := _bw * 0.10  # horizontal offset (light from upper-left → shadow right)
	var oy := _bw * 0.12  # vertical offset below ground line

	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(Vector2(ox + cos(a) * sr, oy + sin(a) * shy))
	var shad := Polygon2D.new()
	shad.polygon = pts
	var sc := Color(0, 0, 0)
	sc.a = 0.48
	shad.color = sc
	shad.z_index = -2
	add_child(shad)


func _build_entrance_path() -> void:
	# Trapezoidal dirt path from door base (y=0) downward — "roots" building to ground.
	# Well has no traditional entrance; skip it.
	if building_id == "well":
		return
	var door_w := _bw * 0.55  # wider path — clearly connects building to road
	var path_h := 28.0 * _sy
	var top_w := door_w
	var bot_w := door_w * 1.6
	var ep := Polygon2D.new()
	ep.polygon = PackedVector2Array(
		[
			Vector2(-top_w * 0.5, 0.0),
			Vector2(top_w * 0.5, 0.0),
			Vector2(bot_w * 0.5, path_h),
			Vector2(-bot_w * 0.5, path_h),
		]
	)
	ep.color = Color("#c4811a")
	ep.z_index = -1
	add_child(ep)
	# Stays dirt color even when building is locked


# ─────────────────────────────────────────────────────────────────────────────
# Foundation slab — dark earth strip that straddles y=0, making the building
# look embedded in the ground rather than floating above it.
# Technique: "base embedding" used in Stardew Valley / RPG Maker style games.
# ─────────────────────────────────────────────────────────────────────────────
func _build_foundation() -> void:
	var fw := _bw * 1.06
	var fh := _bh * 0.18
	# Centre at y = -fh*0.30 so 70% is below ground, 30% above — bottom of
	# building sprite sits on top of this strip, visually embedding it.
	var fy := -fh * 0.30
	var foundation := ColorRect.new()
	foundation.size = Vector2(fw, fh)
	foundation.position = Vector2(-fw * 0.5, fy - fh * 0.5)
	var fc := Color("#3a2010")
	fc.a = 0.72
	foundation.color = fc
	foundation.z_index = -1
	add_child(foundation)


# ═════════════════════════════════════════════════════════════════════════════
# SPRITE — loads PNG from assets/sprites/buildings/{id}.png + unlock shader
# ═════════════════════════════════════════════════════════════════════════════
func _build_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/buildings/%s.png" % building_id)

	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/building_unlock.gdshader")
	mat.set_shader_parameter("color_amount", 1.0 if is_unlocked else 0.0)
	_sprite.material = mat

	# Scale sprite to fill the building's reference dimensions
	var tex_size := _sprite.texture.get_size()
	_sprite.scale = Vector2(_bw / tex_size.x, _bh / tex_size.y)

	# Embed sprite 12% into the ground plane — the bottom of the sprite overlaps
	# slightly with the foundation slab, which is the classic 2D RPG technique
	# (used in Stardew Valley / Zelda) to make buildings look planted, not floating.
	_sprite.position = Vector2(0.0, -_bh * 0.5 + _bh * 0.12)

	add_child(_sprite)


# ═════════════════════════════════════════════════════════════════════════════
# COLLISION — StaticBody2D so CharacterBody2D.move_and_slide() is blocked
# ═════════════════════════════════════════════════════════════════════════════
func _build_collision() -> void:
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	# Cover the lower 45% of the building — the physical "base" footprint.
	# Upper roof area is intentionally excluded so approaching from any side
	# feels natural and the collision wall isn't taller than the visible base.
	# Collision covers the embedded lower portion — shifted to match sprite embed
	shape.size = Vector2(_bw * 0.88, _bh * 0.45)
	col.shape = shape
	col.position = Vector2(0.0, -_bh * 0.225 + _bh * 0.12)
	body.add_child(col)
	add_child(body)


# ═════════════════════════════════════════════════════════════════════════════
# PADLOCK — drawn from ColorRects, pulsing glow
# ═════════════════════════════════════════════════════════════════════════════
func _build_padlock() -> void:
	_padlock = Node2D.new()
	_padlock.name = "PadlockNode"
	# Position padlock centered on upper half of building
	var lock_y := -_bh * 0.75 if building_id != "well" else -_bh * 0.95
	_padlock.position = Vector2(0, lock_y)

	var bw_l := 44.0 * _sx
	var bh_l := 32.0 * _sy
	var shw := 8.0 * _sx  # shackle thickness
	var shh := 22.0 * _sy  # shackle arm height
	var sht := 8.0 * _sy  # shackle top bar height

	# Glow (behind everything, pulsing alpha)
	var glow_panel := Panel.new()
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color("#4FC3F7")
	glow_style.bg_color.a = 0.45
	var glow_r := int(min(bw_l + 24 * _sx, bh_l + 24 * _sy) * 0.5)
	glow_style.corner_radius_top_left = glow_r
	glow_style.corner_radius_top_right = glow_r
	glow_style.corner_radius_bottom_left = glow_r
	glow_style.corner_radius_bottom_right = glow_r
	glow_style.content_margin_left = 0.0
	glow_style.content_margin_right = 0.0
	glow_style.content_margin_top = 0.0
	glow_style.content_margin_bottom = 0.0
	glow_panel.add_theme_stylebox_override("panel", glow_style)
	glow_panel.size = Vector2(bw_l + 24 * _sx, bh_l + shh + 24 * _sy)
	glow_panel.position = Vector2(-bw_l * 0.5 - 12 * _sx, -shh - 12 * _sy)
	glow_panel.name = "Glow"
	glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_padlock.add_child(glow_panel)

	# Body (rounded rectangle)
	var body_panel := Panel.new()
	var body_style := StyleBoxFlat.new()
	body_style.bg_color = Color("#4FC3F7")
	body_style.corner_radius_top_left = int(bh_l * 0.25)
	body_style.corner_radius_top_right = int(bh_l * 0.25)
	body_style.corner_radius_bottom_left = int(bh_l * 0.25)
	body_style.corner_radius_bottom_right = int(bh_l * 0.25)
	body_style.content_margin_left = 0.0
	body_style.content_margin_right = 0.0
	body_style.content_margin_top = 0.0
	body_style.content_margin_bottom = 0.0
	body_panel.add_theme_stylebox_override("panel", body_style)
	body_panel.size = Vector2(bw_l, bh_l)
	body_panel.position = Vector2(-bw_l * 0.5, 0)
	body_panel.name = "Body"
	body_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_padlock.add_child(body_panel)

	# Shackle — U shape: left bar, top bar, right bar
	var sl := ColorRect.new()
	sl.name = "ShackleL"
	sl.color = Color("#4FC3F7")
	sl.size = Vector2(shw, shh)
	sl.position = Vector2(-bw_l * 0.28, -shh)
	_padlock.add_child(sl)

	var sr := ColorRect.new()
	sr.name = "ShackleR"
	sr.color = Color("#4FC3F7")
	sr.size = Vector2(shw, shh)
	sr.position = Vector2(bw_l * 0.28 - shw, -shh)
	_padlock.add_child(sr)

	var st := ColorRect.new()
	st.name = "ShackleTop"
	st.color = Color("#4FC3F7")
	st.size = Vector2(bw_l * 0.56, sht)
	st.position = Vector2(-bw_l * 0.28, -shh - sht * 0.5)
	_padlock.add_child(st)

	# Keyhole (dark rect on body)
	var kh := ColorRect.new()
	kh.name = "Keyhole"
	kh.color = Color("#1a2a3a")
	kh.size = Vector2(10.0 * _sx, 14.0 * _sy)
	kh.position = Vector2(-5.0 * _sx, bh_l * 0.25)
	_padlock.add_child(kh)

	add_child(_padlock)


# ═════════════════════════════════════════════════════════════════════════════
# NAME LABEL
# ═════════════════════════════════════════════════════════════════════════════
func _build_name_label() -> void:
	# Styled panel container with dark background for readability
	var container := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.243, 0.141, 0.031, 0.80)  # #3E2408 semi-transparent
	panel_style.corner_radius_top_left = int(6 * _sx)
	panel_style.corner_radius_top_right = int(6 * _sx)
	panel_style.corner_radius_bottom_left = int(6 * _sx)
	panel_style.corner_radius_bottom_right = int(6 * _sx)
	panel_style.content_margin_left = 8.0 * _sx
	panel_style.content_margin_right = 8.0 * _sx
	panel_style.content_margin_top = 3.0 * _sy
	panel_style.content_margin_bottom = 3.0 * _sy
	panel_style.border_width_left = int(max(1, 1 * _sx))
	panel_style.border_width_right = int(max(1, 1 * _sx))
	panel_style.border_width_top = int(max(1, 1 * _sy))
	panel_style.border_width_bottom = int(max(1, 1 * _sy))
	panel_style.border_color = Color("#8B6914")
	container.add_theme_stylebox_override("panel", panel_style)
	container.size = Vector2(_bw * 1.6, 32.0 * _sy)
	container.position = Vector2(-_bw * 0.80, 10.0 * _sy)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.name = "LabelPanel"

	# Text shadow (offset label behind main)
	var shadow_label := Label.new()
	shadow_label.text = building_label
	shadow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow_label.add_theme_font_size_override("font_size", int(21.0 * _sy))
	shadow_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.5))
	shadow_label.size = Vector2(_bw * 1.6, 42.0 * _sy)
	shadow_label.position = Vector2(1.0 * _sx, 1.0 * _sy)
	shadow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(shadow_label)

	# Main label
	_name_label = Label.new()
	_name_label.text = building_label
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", int(21.0 * _sy))
	_name_label.add_theme_color_override("font_color", Color("#FFF8E7"))
	_name_label.size = Vector2(_bw * 1.6, 42.0 * _sy)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.name = "NameLabel"
	container.add_child(_name_label)

	add_child(container)
	# Label panel always full brightness (not affected by grayscale shader)


# ═════════════════════════════════════════════════════════════════════════════
# TOUCH / CLICK AREA
# ═════════════════════════════════════════════════════════════════════════════
func _build_touch_area() -> void:
	_area = Area2D.new()
	_area.name = "TouchArea"
	_area.input_pickable = true
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(_bw, _bh)
	col.shape = shape
	col.position = Vector2(0.0, -_bh * 0.5)
	_area.add_child(col)
	_area.input_event.connect(_on_area_input)
	add_child(_area)


# ═════════════════════════════════════════════════════════════════════════════
# PARTICLES
# ═════════════════════════════════════════════════════════════════════════════
func _build_particles() -> void:
	# Confetti burst on unlock
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.explosiveness = 0.95
	_particles.amount = 32
	_particles.lifetime = 1.6
	_particles.spread = 170.0
	_particles.gravity = Vector2(0, 220)
	_particles.initial_velocity_min = 100.0
	_particles.initial_velocity_max = 240.0
	_particles.scale_amount_min = 3.0
	_particles.scale_amount_max = 8.0
	_particles.color = building_color
	# Sprite is embedded 12% into ground → sprite center is at -_bh*0.38,
	# so place confetti at ~60% up the visible building.
	_particles.position = Vector2(0, -_bh * 0.58)
	add_child(_particles)



# ═════════════════════════════════════════════════════════════════════════════
# STATE APPLICATION  (gray / color)
# ═════════════════════════════════════════════════════════════════════════════
func _apply_state() -> void:
	if is_instance_valid(_sprite) and _sprite.material:
		(_sprite.material as ShaderMaterial).set_shader_parameter(
			"color_amount", 1.0 if is_unlocked else 0.0
		)
	if is_instance_valid(_padlock):
		_padlock.visible = not is_unlocked


# ═════════════════════════════════════════════════════════════════════════════
# UNLOCK ANIMATION
# ═════════════════════════════════════════════════════════════════════════════
func is_player_nearby(player_pos: Vector2, threshold: float = 150.0) -> bool:
	return position.distance_to(player_pos) < threshold * _sx


func _on_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _tap_cooldown:
		return
	var tapped := false
	if event is InputEventScreenTouch and event.pressed:
		tapped = true
	elif (
		event is InputEventMouseButton
		and event.pressed
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	):
		tapped = true
	if tapped:
		_tap_cooldown = true
		get_tree().create_timer(0.5).timeout.connect(func() -> void: _tap_cooldown = false)
		building_tapped.emit(self)


func unlock(cutscene_mode: bool = false) -> void:
	if is_unlocked:
		return
	is_unlocked = true
	GameManager.register_unlocked_building(building_id, not cutscene_mode)

	if cutscene_mode:
		# UnlockCutscene drives all visual animation externally.
		return

	# ── Fallback animation (non-cutscene, e.g. catch-up on reload) ──

	# 1. Padlock exit: scale up + fade out → free
	if is_instance_valid(_padlock):
		var lock_tween := create_tween()
		lock_tween.set_parallel(true)
		lock_tween.tween_property(_padlock, "scale", Vector2(1.5, 1.5), 0.4)
		lock_tween.tween_property(_padlock, "modulate", Color(1, 1, 1, 0), 0.4)
		lock_tween.chain().tween_callback(func() -> void: _padlock.queue_free())

	# 2. Color reveal: tween shader color_amount 0 → 1 over 1.5s
	var color_tween := create_tween()
	color_tween.set_ease(Tween.EASE_IN_OUT)
	color_tween.set_trans(Tween.TRANS_CUBIC)
	color_tween.tween_method(
		func(v: float) -> void:
			if is_instance_valid(_sprite) and _sprite.material:
				(_sprite.material as ShaderMaterial).set_shader_parameter("color_amount", v),
		0.0,
		1.0,
		1.5
	)

	# 3. Scale bounce on whole building
	var bounce := create_tween()
	bounce.set_ease(Tween.EASE_OUT)
	bounce.set_trans(Tween.TRANS_BACK)
	bounce.tween_property(self, "scale", Vector2(1.08, 1.08), 0.18)
	bounce.tween_property(self, "scale", Vector2(1.00, 1.00), 0.28)

	# 4. Particle burst after reveal
	var t := get_tree().create_timer(1.5)
	t.timeout.connect(func() -> void:
		if is_instance_valid(_particles):
			_particles.emitting = true
	)


# ═════════════════════════════════════════════════════════════════════════════
# CUTSCENE GETTERS — expose internals for UnlockCutscene to drive animation
# ═════════════════════════════════════════════════════════════════════════════

func get_padlock() -> Node2D:
	return _padlock


func get_building_sprite() -> Sprite2D:
	return _sprite


func get_confetti_particles() -> CPUParticles2D:
	return _particles


## World-space position of the building's visual center (above ground embedding).
func get_building_center_world_pos() -> Vector2:
	return global_position + Vector2(0, -_bh * 0.38)
