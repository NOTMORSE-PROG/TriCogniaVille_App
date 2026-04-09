extends CanvasLayer
## UnlockCutscene — Cinematic unlock sequence for each building.
## Follows the TownCelebration.gd pattern: added as child of Main,
## drives the full visual sequence, emits finished, then queue_free.
##
## Usage (from Main.gd):
##   var cs = UnlockCutscene.new()
##   add_child(cs)
##   cs.setup(vp, sx, sy, bc, camera, player, ysort, town_livener)
##   cs.play()
##   await cs.cutscene_finished

signal cutscene_finished

# Per-building theming
const BUILDING_THEMES := {
	"town_hall": {
		"emoji": "🏛️", "flavor": "The heart of the village beats again!",
		"confetti": [Color("#E8C547"), Color("#D4A017"), Color("#FFF4CC")],
	},
	"school": {
		"emoji": "🏫", "flavor": "Knowledge returns to the village!",
		"confetti": [Color("#5B9BD5"), Color("#FFFFFF"), Color("#FFD93D")],
	},
	"inn": {
		"emoji": "🏨", "flavor": "Travelers will find rest here!",
		"confetti": [Color("#C07B3A"), Color("#EB8C40"), Color("#E8C547")],
	},
	"chapel": {
		"emoji": "⛪", "flavor": "Peace and harmony restored!",
		"confetti": [Color("#FFFFFF"), Color("#C0C0D0"), Color("#C8B8E8")],
	},
	"library": {
		"emoji": "📚", "flavor": "Wisdom fills the air!",
		"confetti": [Color("#8B5CF6"), Color("#A78BFA"), Color("#E8C547")],
	},
	"well": {
		"emoji": "⛲", "flavor": "The waters flow once more!",
		"confetti": [Color("#3E8948"), Color("#40C8C0"), Color("#5BEAD5")],
	},
	"market": {
		"emoji": "🏪", "flavor": "Commerce returns to the village!",
		"confetti": [Color("#EB6B1F"), Color("#E94560"), Color("#E8C547")],
	},
	"bakery": {
		"emoji": "🧁", "flavor": "The sweetest place in town!",
		"confetti": [Color("#E94560"), Color("#FFB3C6"), Color("#FFEEDD")],
	},
}

# ─── Particle textures ──────────────────────────────────────────────────────
var _tex_circle: Texture2D
var _tex_star: Texture2D
var _tex_spark: Texture2D
var _tex_flame: Texture2D

# ─── Injected references ────────────────────────────────────────────────────
var _bc: Node2D  # BuildingController
var _building_id: String
var _building_label: String
var _building_color: Color
var _camera: Camera2D
var _player: Node2D
var _ysort: Node2D
var _town_livener: Node2D
var _vp: Vector2
var _sx: float
var _sy: float

# ─── State ───────────────────────────────────────────────────────────────────
var _original_cam_offset: Vector2
var _original_cam_smooth_speed: float
var _banner_layer: CanvasLayer


func _init() -> void:
	layer = 15
	name = "UnlockCutscene"


func setup(
	vp: Vector2, sx: float, sy: float,
	building_controller: Node2D, camera: Camera2D,
	player: Node2D, ysort: Node2D, town_livener: Node2D
) -> void:
	_vp = vp
	_sx = sx
	_sy = sy
	_bc = building_controller
	_building_id = _bc.building_id
	_building_label = _bc.building_label
	_building_color = _bc.building_color
	_camera = camera
	_player = player
	_ysort = ysort
	_town_livener = town_livener

	# Preload textures
	_tex_circle = _safe_load("res://assets/particles/kenney/circle_05.png")
	_tex_star = _safe_load("res://assets/particles/kenney/star_06.png")
	_tex_spark = _safe_load("res://assets/particles/kenney/spark_05.png")
	_tex_flame = _safe_load("res://assets/particles/kenney/flame_02.png")


func _safe_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


# ═════════════════════════════════════════════════════════════════════════════
# MAIN SEQUENCE
# ═════════════════════════════════════════════════════════════════════════════

func play() -> void:
	# Register the unlock (state only, no animation)
	_bc.unlock(true)

	# Store camera state
	_original_cam_offset = _camera.offset
	_original_cam_smooth_speed = _camera.position_smoothing_speed

	# Phase 1: Camera pan to building (0.8s)
	_phase_camera_pan()
	await get_tree().create_timer(0.8).timeout

	# Phase 3: Padlock shatter (0.5s)
	_phase_padlock_shatter()
	await get_tree().create_timer(0.5).timeout

	# Phase 4: Gentle color flash + SFX (0.4s)
	var flash_color := Color(_building_color.r, _building_color.g, _building_color.b, 0.18).lightened(0.2)
	UIAnimations.flash_screen_on_layer(self, _vp, flash_color, 0.4)
	AudioManager.play_sfx("building_unlock")
	await get_tree().create_timer(0.3).timeout

	# Phase 5: Color reveal + confetti + bounce (2.0s)
	_phase_color_reveal()
	await get_tree().create_timer(0.5).timeout
	_phase_confetti()
	_phase_building_bonus()
	await get_tree().create_timer(0.4).timeout
	_phase_bounce()
	await get_tree().create_timer(1.1).timeout

	# Phase 6: Banner (2.0s)
	_phase_banner()
	await get_tree().create_timer(2.2).timeout
	_dismiss_banner()
	await get_tree().create_timer(0.5).timeout

	# Phase 7: Village tour (1.5-3s)
	var new_tier := GameManager.unlocked_buildings.size()
	if new_tier <= 7:
		var highlights: Array[Dictionary] = _town_livener.apply_tier_animated(new_tier)
		await get_tree().create_timer(0.3).timeout
		await _phase_tour(highlights)

	# Phase 8: Restore (1.0s)
	await _phase_restore()

	# Done
	cutscene_finished.emit()

	# Delayed cleanup for particles to finish
	await get_tree().create_timer(2.0).timeout
	queue_free()


# ═════════════════════════════════════════════════════════════════════════════
# PHASE IMPLEMENTATIONS
# ═════════════════════════════════════════════════════════════════════════════

func _phase_spotlight() -> void:
	# Shader-based spotlight centered on building
	_spotlight = ColorRect.new()
	_spotlight.size = _vp
	_spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec2 focus_uv = vec2(0.5, 0.5);
uniform float radius = 0.0;
uniform float softness = 0.18;
uniform float dim_amount = 0.0;
void fragment() {
	float d = length(UV - focus_uv);
	float mask = smoothstep(radius, radius + softness, d);
	COLOR = vec4(0.0, 0.0, 0.03, mask * dim_amount);
}
"""
	_spotlight_mat = ShaderMaterial.new()
	_spotlight_mat.shader = shader

	# Calculate building UV position
	var building_world := _bc.get_building_center_world_pos()
	var focus_uv := building_world / _vp
	focus_uv = focus_uv.clamp(Vector2(0.1, 0.1), Vector2(0.9, 0.9))
	_spotlight_mat.set_shader_parameter("focus_uv", focus_uv)
	_spotlight_mat.set_shader_parameter("radius", 0.0)
	_spotlight_mat.set_shader_parameter("dim_amount", 0.0)
	_spotlight.material = _spotlight_mat
	add_child(_spotlight)

	# Animate spotlight appearing
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float) -> void:
		if is_instance_valid(_spotlight_mat):
			_spotlight_mat.set_shader_parameter("radius", v)
	, 0.0, 0.12, 0.6)
	tw.tween_method(func(v: float) -> void:
		if is_instance_valid(_spotlight_mat):
			_spotlight_mat.set_shader_parameter("dim_amount", v)
	, 0.0, 0.55, 0.6)


func _phase_camera_pan() -> void:
	var building_world := _bc.get_building_center_world_pos()
	var target_offset := building_world - _player.global_position

	# Clamp offset so camera stays within viewport limits
	var cam_target := _player.global_position + target_offset
	cam_target.x = clampf(cam_target.x, _vp.x * 0.5, _vp.x * 0.5)
	cam_target.y = clampf(cam_target.y, _vp.y * 0.5, _vp.y * 0.5)
	target_offset = cam_target - _player.global_position

	# Clamp within camera limits
	var half_vp := _vp * 0.5
	var min_pos := Vector2(_camera.limit_left, _camera.limit_top) + half_vp
	var max_pos := Vector2(_camera.limit_right, _camera.limit_bottom) - half_vp
	var final_pos := (_player.global_position + target_offset).clamp(min_pos, max_pos)
	target_offset = final_pos - _player.global_position

	_camera.position_smoothing_speed = 20.0
	var tw := create_tween()
	tw.tween_property(_camera, "offset", target_offset, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _phase_padlock_shatter() -> void:
	var padlock := _bc.get_padlock()
	if not is_instance_valid(padlock):
		return

	# Shake padlock
	var orig_pos := padlock.position
	var tw := create_tween()
	for i in 3:
		var intensity := 4.0 * _sx * (1.0 - float(i) / 3.0)
		tw.tween_property(padlock, "position", orig_pos + Vector2(intensity, 0), 0.05)
		tw.tween_property(padlock, "position", orig_pos + Vector2(-intensity, 0), 0.05)
	tw.tween_property(padlock, "position", orig_pos, 0.04)

	# After shake: scale up + rotate + fade
	tw.tween_property(padlock, "scale", Vector2(2.0, 2.0), 0.15)
	tw.parallel().tween_property(padlock, "rotation_degrees", 15.0, 0.15)
	tw.parallel().tween_property(padlock, "modulate:a", 0.0, 0.15)

	# Spawn shard particles at padlock position
	var shard_pos := _bc.global_position + padlock.position
	_spawn_shards(shard_pos)

	# Free padlock after animation
	tw.tween_callback(func() -> void:
		if is_instance_valid(padlock):
			padlock.queue_free()
	)


func _spawn_shards(pos: Vector2) -> void:
	var shards := CPUParticles2D.new()
	shards.emitting = true
	shards.one_shot = true
	shards.explosiveness = 1.0
	shards.amount = 8
	shards.lifetime = 0.6
	shards.spread = 120.0
	shards.gravity = Vector2(0, 400)
	shards.initial_velocity_min = 140.0
	shards.initial_velocity_max = 260.0
	shards.scale_amount_min = 3.0
	shards.scale_amount_max = 6.0
	shards.angular_velocity_min = -200.0
	shards.angular_velocity_max = 200.0
	shards.position = pos
	shards.z_index = 10
	if _tex_spark:
		shards.texture = _tex_spark
	var grad := Gradient.new()
	grad.set_color(0, Color("#4FC3F7"))
	grad.set_color(1, Color(0.3, 0.76, 0.97, 0.0))
	shards.color_ramp = grad
	_ysort.add_child(shards)
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if is_instance_valid(shards):
			shards.queue_free()
	)


func _phase_flash_and_burst() -> void:
	# Screen flash with building-tinted color
	var flash_color := Color(_building_color.r, _building_color.g, _building_color.b, 0.3).lightened(0.4)
	UIAnimations.flash_screen_on_layer(self, _vp, flash_color, 0.35)

	# Radial light ring particles
	var burst_pos := _bc.get_building_center_world_pos()
	var ring := CPUParticles2D.new()
	ring.emitting = true
	ring.one_shot = true
	ring.explosiveness = 1.0
	ring.amount = 24
	ring.lifetime = 0.8
	ring.spread = 180.0
	ring.gravity = Vector2.ZERO
	ring.initial_velocity_min = 280.0
	ring.initial_velocity_max = 350.0
	ring.scale_amount_min = 4.0
	ring.scale_amount_max = 10.0
	ring.position = burst_pos
	ring.z_index = 10
	if _tex_spark:
		ring.texture = _tex_spark
	var rg := Gradient.new()
	rg.set_color(0, Color(_building_color.r, _building_color.g, _building_color.b, 0.7))
	rg.set_color(1, Color(_building_color.r, _building_color.g, _building_color.b, 0.0))
	ring.color_ramp = rg
	_ysort.add_child(ring)

	# Screen shake
	UIAnimations.screen_shake(self, _ysort, 6.0 * _sx, 4)

	# Cleanup
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)


func _phase_color_reveal() -> void:
	var sprite := _bc.get_building_sprite()
	if not is_instance_valid(sprite) or not sprite.material:
		return
	var mat := sprite.material as ShaderMaterial

	# Color reveal: 0 → 1 over 1.8s
	var color_tw := create_tween()
	color_tw.set_ease(Tween.EASE_IN_OUT)
	color_tw.set_trans(Tween.TRANS_CUBIC)
	color_tw.tween_method(func(v: float) -> void:
		if is_instance_valid(mat):
			mat.set_shader_parameter("color_amount", v)
	, 0.0, 1.0, 1.8)



func _phase_confetti() -> void:
	var burst_pos := _bc.get_building_center_world_pos()
	var theme := _get_theme()
	var colors: Array = theme["confetti"]

	# Main confetti burst (120 particles)
	var confetti := CPUParticles2D.new()
	confetti.emitting = true
	confetti.one_shot = true
	confetti.explosiveness = 0.92
	confetti.amount = 120
	confetti.lifetime = 2.2
	confetti.spread = 180.0
	confetti.gravity = Vector2(15, 180)
	confetti.initial_velocity_min = 160.0
	confetti.initial_velocity_max = 320.0
	confetti.angular_velocity_min = -180.0
	confetti.angular_velocity_max = 180.0
	confetti.scale_amount_min = 3.0
	confetti.scale_amount_max = 8.0
	confetti.position = burst_pos
	confetti.z_index = 10
	if _tex_circle:
		confetti.texture = _tex_circle
	var cg := Gradient.new()
	cg.set_color(0, colors[0])
	cg.add_point(0.3, colors[1])
	cg.add_point(0.6, colors[2])
	cg.set_color(1, Color(colors[0].r, colors[0].g, colors[0].b, 0.0))
	confetti.color_ramp = cg
	_ysort.add_child(confetti)

	# Sparkle burst (40 particles)
	var sparkles := CPUParticles2D.new()
	sparkles.emitting = true
	sparkles.one_shot = true
	sparkles.explosiveness = 0.98
	sparkles.amount = 40
	sparkles.lifetime = 1.0
	sparkles.spread = 180.0
	sparkles.gravity = Vector2(0, 60)
	sparkles.initial_velocity_min = 200.0
	sparkles.initial_velocity_max = 400.0
	sparkles.scale_amount_min = 1.5
	sparkles.scale_amount_max = 4.0
	sparkles.position = burst_pos
	sparkles.z_index = 11
	if _tex_star:
		sparkles.texture = _tex_star
	var sg := Gradient.new()
	sg.set_color(0, Color(1.0, 1.0, 1.0, 0.9))
	sg.add_point(0.4, Color(1.0, 0.9, 0.5, 0.7))
	sg.set_color(1, Color(1.0, 0.85, 0.3, 0.0))
	sparkles.color_ramp = sg
	_ysort.add_child(sparkles)

	# Cleanup
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(confetti):
			confetti.queue_free()
		if is_instance_valid(sparkles):
			sparkles.queue_free()
	)


func _phase_building_bonus() -> void:
	var burst_pos := _bc.get_building_center_world_pos()

	match _building_id:
		"town_hall":
			_bonus_sunburst(burst_pos)
		"school":
			_bonus_rising_stars(burst_pos)
		"inn":
			_bonus_embers(burst_pos)
		"chapel":
			_bonus_dove_light(burst_pos)
		"library":
			_bonus_page_flutter(burst_pos)
		"well":
			_bonus_water_burst(burst_pos)
		"market":
			_bonus_coin_shower(burst_pos)
		"bakery":
			_bonus_heart_warmth(burst_pos)


func _phase_bounce() -> void:
	var tw := create_tween()
	tw.tween_property(_bc, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bc, "scale", Vector2(0.97, 0.97), 0.12)
	tw.tween_property(_bc, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _phase_banner() -> void:
	_banner_layer = CanvasLayer.new()
	_banner_layer.layer = 16
	add_child(_banner_layer)

	var theme := _get_theme()

	# Dark backdrop panel
	var panel := ColorRect.new()
	panel.color = Color(0.04, 0.08, 0.15, 0.85)
	panel.size = Vector2(_vp.x * 0.6, 120 * _sy)
	panel.position = Vector2(_vp.x * 0.2, _vp.y * 0.12)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_layer.add_child(panel)

	# Gold border (using a slightly larger rect behind)
	var border := ColorRect.new()
	border.color = Color("#E8C547")
	border.size = panel.size + Vector2(4, 4)
	border.position = panel.position - Vector2(2, 2)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_layer.add_child(border)
	# Ensure panel is on top of border
	_banner_layer.move_child(panel, -1)

	# Title: emoji + building name
	var title := Label.new()
	title.text = "%s %s" % [theme["emoji"], _building_label]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", int(38 * _sx))
	title.add_theme_color_override("font_color", Color("#E8C547"))
	title.size = Vector2(panel.size.x, 50 * _sy)
	title.position = Vector2(panel.position.x, panel.position.y + 12 * _sy)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_layer.add_child(title)

	# Subtitle: flavor text
	var subtitle := Label.new()
	subtitle.text = theme["flavor"]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", int(20 * _sx))
	subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	subtitle.size = Vector2(panel.size.x, 30 * _sy)
	subtitle.position = Vector2(panel.position.x, panel.position.y + 55 * _sy)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_layer.add_child(subtitle)

	# Accent bar (building color)
	var accent := ColorRect.new()
	accent.color = _building_color
	accent.size = Vector2(160 * _sx, 4 * _sy)
	accent.position = Vector2(panel.position.x + (panel.size.x - 160 * _sx) * 0.5, panel.position.y + 90 * _sy)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_layer.add_child(accent)

	# Animate in
	UIAnimations.elastic_reveal(self, panel)
	UIAnimations.fade_in_up(self, title, 0.15)
	UIAnimations.fade_in_up(self, subtitle, 0.3)
	UIAnimations.fade_in_up(self, accent, 0.4)


func _dismiss_banner() -> void:
	if is_instance_valid(_banner_layer):
		var tw := create_tween()
		tw.tween_property(_banner_layer, "offset", Vector2(0, -30), 0.4)
		for child in _banner_layer.get_children():
			if child is Control:
				var ftw := child.create_tween()
				ftw.tween_property(child, "modulate:a", 0.0, 0.4)
		tw.tween_callback(func() -> void:
			if is_instance_valid(_banner_layer):
				_banner_layer.queue_free()
		)


func _phase_tour(highlights: Array[Dictionary]) -> void:
	if highlights.is_empty():
		return

	# Tour at most 2 highlights
	var count := mini(highlights.size(), 2)
	for i in range(count):
		var hl: Dictionary = highlights[i]
		var hl_pos: Vector2 = hl["pos"]

		# Pan camera to highlight
		var target_offset := hl_pos - _player.global_position
		var half_vp := _vp * 0.5
		var min_pos := Vector2(_camera.limit_left, _camera.limit_top) + half_vp
		var max_pos := Vector2(_camera.limit_right, _camera.limit_bottom) - half_vp
		var final_pos := (_player.global_position + target_offset).clamp(min_pos, max_pos)
		target_offset = final_pos - _player.global_position

		var pan_tw := create_tween()
		pan_tw.tween_property(_camera, "offset", target_offset, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await pan_tw.finished

		# Pulse highlight circle at position
		_spawn_highlight_pulse(hl_pos)

		# Hold
		await get_tree().create_timer(0.8).timeout


func _spawn_highlight_pulse(pos: Vector2) -> void:
	var pulse := CPUParticles2D.new()
	pulse.emitting = true
	pulse.one_shot = true
	pulse.explosiveness = 1.0
	pulse.amount = 8
	pulse.lifetime = 0.8
	pulse.spread = 180.0
	pulse.gravity = Vector2.ZERO
	pulse.initial_velocity_min = 40.0
	pulse.initial_velocity_max = 80.0
	pulse.scale_amount_min = 3.0
	pulse.scale_amount_max = 7.0
	pulse.position = pos
	pulse.z_index = 8
	if _tex_circle:
		pulse.texture = _tex_circle
	var pg := Gradient.new()
	pg.set_color(0, Color(1.0, 0.9, 0.5, 0.6))
	pg.set_color(1, Color(1.0, 0.85, 0.3, 0.0))
	pulse.color_ramp = pg
	_ysort.add_child(pulse)
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if is_instance_valid(pulse):
			pulse.queue_free()
	)


func _phase_restore() -> void:
	# Pan camera back
	var cam_tw := create_tween()
	cam_tw.tween_property(_camera, "offset", Vector2.ZERO, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# Restore camera smoothing speed
	get_tree().create_timer(0.8).timeout.connect(func() -> void:
		if is_instance_valid(_camera):
			_camera.position_smoothing_speed = _original_cam_smooth_speed
	)

	await get_tree().create_timer(1.0).timeout


# ═════════════════════════════════════════════════════════════════════════════
# PER-BUILDING BONUS EFFECTS
# ═════════════════════════════════════════════════════════════════════════════

func _bonus_sunburst(pos: Vector2) -> void:
	# Golden star sparkles floating upward (no blinding rays)
	var stars := CPUParticles2D.new()
	stars.emitting = true
	stars.one_shot = true
	stars.explosiveness = 0.4
	stars.amount = 14
	stars.lifetime = 1.8
	stars.spread = 50.0
	stars.direction = Vector2(0, -1)
	stars.gravity = Vector2(0, -15)
	stars.initial_velocity_min = 30.0
	stars.initial_velocity_max = 80.0
	stars.angular_velocity_min = -20.0
	stars.angular_velocity_max = 20.0
	stars.scale_amount_min = 2.0
	stars.scale_amount_max = 5.0
	stars.position = pos
	stars.z_index = 9
	if _tex_star:
		stars.texture = _tex_star
	var rg := Gradient.new()
	rg.set_color(0, Color(0.91, 0.77, 0.28, 0.85))
	rg.add_point(0.5, Color(1.0, 0.9, 0.5, 0.6))
	rg.set_color(1, Color(1.0, 0.85, 0.3, 0.0))
	stars.color_ramp = rg
	_ysort.add_child(stars)
	_delayed_free(stars, 2.5)


func _bonus_rising_stars(pos: Vector2) -> void:
	var stars := CPUParticles2D.new()
	stars.emitting = true
	stars.one_shot = true
	stars.explosiveness = 0.5
	stars.amount = 16
	stars.lifetime = 2.0
	stars.spread = 60.0
	stars.direction = Vector2(0, -1)
	stars.gravity = Vector2(0, -20)
	stars.initial_velocity_min = 40.0
	stars.initial_velocity_max = 100.0
	stars.angular_velocity_min = -30.0
	stars.angular_velocity_max = 30.0
	stars.scale_amount_min = 3.0
	stars.scale_amount_max = 7.0
	stars.position = pos
	stars.z_index = 9
	if _tex_star:
		stars.texture = _tex_star
	var sg := Gradient.new()
	sg.set_color(0, Color(0.36, 0.61, 0.84, 0.9))
	sg.add_point(0.5, Color(1.0, 0.85, 0.3, 0.7))
	sg.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	stars.color_ramp = sg
	_ysort.add_child(stars)
	_delayed_free(stars, 3.0)


func _bonus_embers(pos: Vector2) -> void:
	var embers := CPUParticles2D.new()
	embers.emitting = true
	embers.one_shot = true
	embers.explosiveness = 0.3
	embers.amount = 20
	embers.lifetime = 2.5
	embers.spread = 40.0
	embers.direction = Vector2(0, -1)
	embers.gravity = Vector2(5, -15)
	embers.initial_velocity_min = 20.0
	embers.initial_velocity_max = 50.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 5.0
	embers.position = pos
	embers.z_index = 9
	if _tex_flame:
		embers.texture = _tex_flame
	var eg := Gradient.new()
	eg.set_color(0, Color(1.0, 0.7, 0.2, 0.85))
	eg.add_point(0.5, Color(1.0, 0.4, 0.1, 0.6))
	eg.set_color(1, Color(0.8, 0.2, 0.05, 0.0))
	embers.color_ramp = eg
	_ysort.add_child(embers)
	_delayed_free(embers, 3.5)


func _bonus_dove_light(pos: Vector2) -> void:
	var orbs := CPUParticles2D.new()
	orbs.emitting = true
	orbs.one_shot = true
	orbs.explosiveness = 0.3
	orbs.amount = 8
	orbs.lifetime = 3.0
	orbs.spread = 80.0
	orbs.direction = Vector2(0.5, -1)
	orbs.gravity = Vector2(0, -5)
	orbs.initial_velocity_min = 12.0
	orbs.initial_velocity_max = 25.0
	orbs.scale_amount_min = 5.0
	orbs.scale_amount_max = 10.0
	orbs.position = pos + Vector2(0, -30 * _sy)
	orbs.z_index = 9
	if _tex_circle:
		orbs.texture = _tex_circle
	var og := Gradient.new()
	og.set_color(0, Color(1, 1, 1, 0.65))
	og.set_color(1, Color(1, 1, 1, 0.0))
	orbs.color_ramp = og
	_ysort.add_child(orbs)
	_delayed_free(orbs, 4.0)


func _bonus_page_flutter(pos: Vector2) -> void:
	# White rectangles tumbling as pages
	var pages := CPUParticles2D.new()
	pages.emitting = true
	pages.one_shot = true
	pages.explosiveness = 0.4
	pages.amount = 12
	pages.lifetime = 2.5
	pages.spread = 80.0
	pages.direction = Vector2(0.3, -1)
	pages.gravity = Vector2(10, 20)
	pages.initial_velocity_min = 30.0
	pages.initial_velocity_max = 80.0
	pages.angular_velocity_min = -120.0
	pages.angular_velocity_max = 120.0
	pages.scale_amount_min = 3.0
	pages.scale_amount_max = 7.0
	pages.position = pos
	pages.z_index = 9
	var pg := Gradient.new()
	pg.set_color(0, Color(1.0, 0.98, 0.92, 0.85))
	pg.set_color(1, Color(0.9, 0.88, 0.82, 0.0))
	pages.color_ramp = pg
	_ysort.add_child(pages)

	# Star sparkles alongside
	var sparkles := CPUParticles2D.new()
	sparkles.emitting = true
	sparkles.one_shot = true
	sparkles.explosiveness = 0.5
	sparkles.amount = 8
	sparkles.lifetime = 1.5
	sparkles.spread = 180.0
	sparkles.gravity = Vector2(0, -10)
	sparkles.initial_velocity_min = 60.0
	sparkles.initial_velocity_max = 120.0
	sparkles.scale_amount_min = 2.0
	sparkles.scale_amount_max = 5.0
	sparkles.position = pos
	sparkles.z_index = 10
	if _tex_star:
		sparkles.texture = _tex_star
	var sg := Gradient.new()
	sg.set_color(0, Color(0.55, 0.36, 0.96, 0.8))
	sg.set_color(1, Color(0.85, 0.7, 1.0, 0.0))
	sparkles.color_ramp = sg
	_ysort.add_child(sparkles)

	_delayed_free(pages, 3.5)
	_delayed_free(sparkles, 2.5)


func _bonus_water_burst(pos: Vector2) -> void:
	var splash := CPUParticles2D.new()
	splash.emitting = true
	splash.one_shot = true
	splash.explosiveness = 0.85
	splash.amount = 16
	splash.lifetime = 1.5
	splash.spread = 60.0
	splash.direction = Vector2(0, -1)
	splash.gravity = Vector2(0, 180)
	splash.initial_velocity_min = 100.0
	splash.initial_velocity_max = 200.0
	splash.scale_amount_min = 2.0
	splash.scale_amount_max = 6.0
	splash.position = pos
	splash.z_index = 9
	if _tex_circle:
		splash.texture = _tex_circle
	var wg := Gradient.new()
	wg.set_color(0, Color(0.3, 0.8, 1.0, 0.85))
	wg.add_point(0.5, Color(0.5, 0.9, 1.0, 0.6))
	wg.set_color(1, Color(0.6, 0.95, 1.0, 0.0))
	splash.color_ramp = wg
	_ysort.add_child(splash)
	_delayed_free(splash, 2.5)


func _bonus_coin_shower(pos: Vector2) -> void:
	var coins := CPUParticles2D.new()
	coins.emitting = true
	coins.one_shot = true
	coins.explosiveness = 0.6
	coins.amount = 20
	coins.lifetime = 2.0
	coins.spread = 90.0
	coins.direction = Vector2(0, -1)
	coins.gravity = Vector2(0, 150)
	coins.initial_velocity_min = 80.0
	coins.initial_velocity_max = 180.0
	coins.angular_velocity_min = -60.0
	coins.angular_velocity_max = 60.0
	coins.scale_amount_min = 2.5
	coins.scale_amount_max = 5.0
	coins.position = pos + Vector2(0, -40 * _sy)
	coins.z_index = 9
	if _tex_circle:
		coins.texture = _tex_circle
	var cg := Gradient.new()
	cg.set_color(0, Color(0.91, 0.77, 0.15, 0.9))
	cg.add_point(0.5, Color(1.0, 0.85, 0.3, 0.7))
	cg.set_color(1, Color(0.85, 0.7, 0.1, 0.0))
	coins.color_ramp = cg
	_ysort.add_child(coins)
	_delayed_free(coins, 3.0)


func _bonus_heart_warmth(pos: Vector2) -> void:
	# Soft pink circles
	var hearts := CPUParticles2D.new()
	hearts.emitting = true
	hearts.one_shot = true
	hearts.explosiveness = 0.3
	hearts.amount = 12
	hearts.lifetime = 2.5
	hearts.spread = 60.0
	hearts.direction = Vector2(0, -1)
	hearts.gravity = Vector2(0, -10)
	hearts.initial_velocity_min = 15.0
	hearts.initial_velocity_max = 40.0
	hearts.scale_amount_min = 3.0
	hearts.scale_amount_max = 8.0
	hearts.position = pos
	hearts.z_index = 9
	if _tex_circle:
		hearts.texture = _tex_circle
	var hg := Gradient.new()
	hg.set_color(0, Color(0.91, 0.36, 0.38, 0.7))
	hg.add_point(0.5, Color(1.0, 0.7, 0.78, 0.5))
	hg.set_color(1, Color(1.0, 0.85, 0.88, 0.0))
	hearts.color_ramp = hg
	_ysort.add_child(hearts)

	# Warm glow embers
	var embers := CPUParticles2D.new()
	embers.emitting = true
	embers.one_shot = true
	embers.explosiveness = 0.4
	embers.amount = 8
	embers.lifetime = 2.0
	embers.spread = 40.0
	embers.direction = Vector2(0, -1)
	embers.gravity = Vector2(3, -12)
	embers.initial_velocity_min = 10.0
	embers.initial_velocity_max = 30.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 4.0
	embers.position = pos
	embers.z_index = 10
	if _tex_flame:
		embers.texture = _tex_flame
	var eg := Gradient.new()
	eg.set_color(0, Color(1.0, 0.7, 0.3, 0.7))
	eg.set_color(1, Color(1.0, 0.5, 0.1, 0.0))
	embers.color_ramp = eg
	_ysort.add_child(embers)

	_delayed_free(hearts, 3.5)
	_delayed_free(embers, 3.0)


# ═════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════════════════════════

func _get_theme() -> Dictionary:
	if BUILDING_THEMES.has(_building_id):
		return BUILDING_THEMES[_building_id]
	return {"emoji": "🏗️", "flavor": "A new building!", "confetti": [_building_color, Color.WHITE, Color.GOLD]}


func _delayed_free(node: Node, delay: float) -> void:
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if is_instance_valid(node):
			node.queue_free()
	)
