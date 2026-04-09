extends CanvasLayer
## UnlockCutscene — Cinematic unlock sequence for each building.
## Follows the TownCelebration.gd pattern: added as child of Main,
## drives the full visual sequence, emits finished, then queue_free.
##
## Usage (from Main.gd):
##   var cs = UnlockCutscene.new()
##   add_child(cs)
##   cs.setup(vp, sx, sy, bc, camera, player, town_livener)
##   cs.play()
##   await cs.cutscene_finished

signal cutscene_finished

# Per-building theming
const BUILDING_THEMES := {
	"town_hall": {
		"emoji": "🏛️", "flavor": "The heart of the village beats again!",
	},
	"school": {
		"emoji": "🏫", "flavor": "Knowledge returns to the village!",
	},
	"inn": {
		"emoji": "🏨", "flavor": "Travelers will find rest here!",
	},
	"chapel": {
		"emoji": "⛪", "flavor": "Peace and harmony restored!",
	},
	"library": {
		"emoji": "📚", "flavor": "Wisdom fills the air!",
	},
	"well": {
		"emoji": "⛲", "flavor": "The waters flow once more!",
	},
	"market": {
		"emoji": "🏪", "flavor": "Commerce returns to the village!",
	},
	"bakery": {
		"emoji": "🧁", "flavor": "The sweetest place in town!",
	},
}

# ─── Injected references ────────────────────────────────────────────────────
var _bc: BuildingController
var _building_id: String
var _building_label: String
var _building_color: Color
var _camera: Camera2D
var _player: Node2D
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
	building_controller: BuildingController, camera: Camera2D,
	player: Node2D, town_livener: Node2D
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
	_town_livener = town_livener


# ═════════════════════════════════════════════════════════════════════════════
# MAIN SEQUENCE
# ═════════════════════════════════════════════════════════════════════════════

func play() -> void:
	# Register the unlock (state only, no animation)
	_bc.unlock(true)

	# Store camera state
	_original_cam_offset = _camera.offset
	_original_cam_smooth_speed = _camera.position_smoothing_speed

	# Phase 1: Camera pan to building (0.5s)
	_phase_camera_pan()
	await get_tree().create_timer(0.5).timeout

	# Phase 2: Padlock fade + color reveal + SFX
	_phase_padlock_fade()
	_phase_color_reveal()
	AudioManager.play_sfx("building_unlock")
	await get_tree().create_timer(1.8).timeout

	# Phase 3: Banner (2.2s)
	_phase_banner()
	await get_tree().create_timer(2.2).timeout
	_dismiss_banner()
	await get_tree().create_timer(0.5).timeout

	# Phase 4: Village tour
	var new_tier := GameManager.unlocked_buildings.size()
	if new_tier <= GameManager.TOTAL_BUILDINGS:
		var highlights: Array[Dictionary] = _town_livener.apply_tier_animated(new_tier)
		await get_tree().create_timer(0.3).timeout
		await _phase_tour(highlights)

	# Phase 5: Restore
	await _phase_restore()

	cutscene_finished.emit()
	await get_tree().create_timer(0.5).timeout
	queue_free()


# ═════════════════════════════════════════════════════════════════════════════
# PHASE IMPLEMENTATIONS
# ═════════════════════════════════════════════════════════════════════════════

func _phase_camera_pan() -> void:
	var building_world := _bc.get_building_center_world_pos()
	var target_offset := building_world - _player.global_position

	# Clamp within camera limits
	var half_vp := _vp * 0.5
	var min_pos := Vector2(_camera.limit_left, _camera.limit_top) + half_vp
	var max_pos := Vector2(_camera.limit_right, _camera.limit_bottom) - half_vp
	var final_pos := (_player.global_position + target_offset).clamp(min_pos, max_pos)
	target_offset = final_pos - _player.global_position

	_camera.position_smoothing_speed = 20.0
	var tw := create_tween()
	tw.tween_property(_camera, "offset", target_offset, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _phase_padlock_fade() -> void:
	var padlock: Node2D = _bc.get_padlock()
	if not is_instance_valid(padlock):
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(padlock, "scale", Vector2(1.3, 1.3), 0.25)
	tw.tween_property(padlock, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(func() -> void:
		if is_instance_valid(padlock):
			padlock.queue_free()
	)


func _phase_color_reveal() -> void:
	var sprite := _bc.get_building_sprite()
	if not is_instance_valid(sprite) or not sprite.material:
		return
	var mat := sprite.material as ShaderMaterial
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(v: float) -> void:
		if is_instance_valid(mat):
			mat.set_shader_parameter("color_amount", v)
	, 0.0, 1.0, 1.8)


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
		pan_tw.tween_property(_camera, "offset", target_offset, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await pan_tw.finished

		# Hold on highlight
		await get_tree().create_timer(0.8).timeout


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
# HELPERS
# ═════════════════════════════════════════════════════════════════════════════

func _get_theme() -> Dictionary:
	if BUILDING_THEMES.has(_building_id):
		return BUILDING_THEMES[_building_id]
	return {"emoji": "🏗️", "flavor": "A new building!"}
