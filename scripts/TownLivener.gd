extends Node2D
## TownLivener — Progressive town vitality system.
## As buildings unlock (tiers 1-8), new visual elements, NPCs, and ambient
## audio layers are added to make the village feel increasingly alive.
##
## Lives as a child of Main._ysort so all Node2D children auto-participate
## in Y-sort depth ordering.
##
## Usage (from Main.gd):
##   _town_livener = TownLivener.new()
##   _ysort.add_child(_town_livener)
##   _town_livener.setup(_vp, _sx, _sy, _building_controllers)

signal celebration_finished

# Ambient layer config: tier → {path, db}
const AMBIENT_LAYERS := {
	1: {"path": "res://assets/audio/ambient/birds.ogg",          "db": -18.0},
	2: {"path": "res://assets/audio/ambient/wind_chimes.ogg",    "db": -22.0},
	3: {"path": "res://assets/audio/ambient/chatter.mp3",        "db": -24.0},
	6: {"path": "res://assets/audio/ambient/water_fountain.ogg", "db": -20.0},
	7: {"path": "res://assets/audio/ambient/market_bustle.mp3",  "db": -18.0},
}

# ─── Scale / viewport ────────────────────────────────────────────────────────
var _vp: Vector2
var _sx: float
var _sy: float
var _building_controllers: Dictionary  # id → BuildingController

# ─── Tier state ──────────────────────────────────────────────────────────────
var _current_tier: int = 0

# ─── Ambient audio players (one per tier that has a loop) ───────────────────
var _ambient_players: Dictionary = {}  # tier → AudioStreamPlayer

# ─── Walking NPC tween handles (to avoid GC) ────────────────────────────────
var _npc_tweens: Array[Tween] = []

# ─── TownCelebration instance ────────────────────────────────────────────────
var _celebration: Node = null


# ─────────────────────────────────────────────────────────────────────────────
## Call once from Main.gd after add_child().
func setup(vp: Vector2, sx: float, sy: float, building_controllers: Dictionary) -> void:
	_vp = vp
	_sx = sx
	_sy = sy
	_building_controllers = building_controllers

	# Connect to live unlock signals
	if not GameManager.building_unlocked.is_connected(_on_building_unlocked):
		GameManager.building_unlocked.connect(_on_building_unlocked)
	if not GameManager.all_buildings_unlocked.is_connected(_on_all_buildings_unlocked):
		GameManager.all_buildings_unlocked.connect(_on_all_buildings_unlocked)

	# Idempotent catch-up: apply all tiers already unlocked (no animation)
	var already_unlocked := GameManager.unlocked_buildings.size()
	if already_unlocked > 0:
		_apply_up_to(already_unlocked, false)


# ─────────────────────────────────────────────────────────────────────────────
func _on_building_unlocked(_building_id: String) -> void:
	var new_tier := GameManager.unlocked_buildings.size()
	_apply_up_to(new_tier, true)


func _on_all_buildings_unlocked() -> void:
	_launch_celebration()


# ─────────────────────────────────────────────────────────────────────────────
## Apply all tiers from (_current_tier+1) up to `target_tier`.
## animate=false → instant (catch-up on load); animate=true → fade-in.
func _apply_up_to(target_tier: int, animate: bool) -> void:
	for t in range(_current_tier + 1, target_tier + 1):
		_apply_tier(t, animate)
	_current_tier = max(_current_tier, target_tier)


func _apply_tier(tier: int, animate: bool) -> void:
	var root := Node2D.new()
	root.name = "Tier%d" % tier
	add_child(root)

	match tier:
		1: _build_tier_1(root)
		2: _build_tier_2(root)
		3: _build_tier_3(root)
		4: _build_tier_4(root)
		5: _build_tier_5(root)
		6: _build_tier_6(root)
		7: _build_tier_7(root)

	# Ambient audio layer
	if AMBIENT_LAYERS.has(tier):
		_start_ambient(tier, animate)

	# Fade-in animation for live unlocks
	if animate and is_instance_valid(root):
		root.modulate.a = 0.0
		var tw := root.create_tween()
		tw.tween_property(root, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(
			Tween.EASE_OUT
		)


# ═════════════════════════════════════════════════════════════════════════════
# TIER 1 — Town Hall: First Signs of Life
# Flowers + overhead bird silhouettes + bird ambient
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_1(root: Node2D) -> void:
	# Flower clusters in 3 different areas
	_add_flowers(root, Vector2(_vp.x * 0.30, _vp.y * 0.70))
	_add_flowers(root, Vector2(_vp.x * 0.72, _vp.y * 0.65))
	_add_flowers(root, Vector2(_vp.x * 0.55, _vp.y * 0.78))

	# Bird silhouettes drifting across the upper sky
	var birds := CPUParticles2D.new()
	birds.name = "BirdSilhouettes"
	birds.emitting = true
	birds.one_shot = false
	birds.amount = 4
	birds.lifetime = 9.0
	birds.explosiveness = 0.0
	birds.spread = 20.0
	birds.direction = Vector2(1.0, 0.15)
	birds.gravity = Vector2(0, -4)
	birds.initial_velocity_min = 14.0
	birds.initial_velocity_max = 22.0
	birds.angular_velocity_min = -8.0
	birds.angular_velocity_max = 8.0
	birds.scale_amount_min = 3.0
	birds.scale_amount_max = 5.0
	birds.position = Vector2(_vp.x * 0.0, _vp.y * 0.12)
	birds.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	birds.emission_rect_extents = Vector2(_vp.x * 0.05, _vp.y * 0.06)
	birds.z_index = 5
	var b_grad := Gradient.new()
	b_grad.set_color(0, Color(0.18, 0.18, 0.22, 0.55))
	b_grad.set_color(1, Color(0.15, 0.15, 0.20, 0.0))
	birds.color_ramp = b_grad
	root.add_child(birds)


# ═════════════════════════════════════════════════════════════════════════════
# TIER 2 — School: Growing Community
# Child NPCs near school + more flowers + butterflies + wind chimes
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_2(root: Node2D) -> void:
	# Additional flower clusters
	_add_flowers(root, Vector2(_vp.x * 0.20, _vp.y * 0.52))
	_add_flowers(root, Vector2(_vp.x * 0.10,_vp.y * 0.64))

	# Child NPC silhouettes near school (school is at 0.15, 0.44)
	var school_pos := Vector2(_vp.x * 0.15, _vp.y * 0.44)
	_add_idle_npc(root, school_pos + Vector2(50 * _sx, 30 * _sy),  Color("#5B9BD5"), Color("#FFD6A5"))
	_add_idle_npc(root, school_pos + Vector2(80 * _sx, 20 * _sy),  Color("#E8C547"), Color("#FFD6A5"))
	_add_idle_npc(root, school_pos + Vector2(-40 * _sx, 35 * _sy), Color("#9AA8BF"), Color("#FFD6A5"))

	# Extra butterflies near school area
	var btf := CPUParticles2D.new()
	btf.name = "SchoolButterflies"
	btf.emitting = true
	btf.one_shot = false
	btf.amount = 5
	btf.lifetime = 8.0
	btf.explosiveness = 0.0
	btf.spread = 180.0
	btf.gravity = Vector2(0, -6)
	btf.initial_velocity_min = 10.0
	btf.initial_velocity_max = 22.0
	btf.angular_velocity_min = -25.0
	btf.angular_velocity_max = 25.0
	btf.scale_amount_min = 2.5
	btf.scale_amount_max = 4.5
	btf.position = school_pos + Vector2(0, -20 * _sy)
	btf.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	btf.emission_rect_extents = Vector2(_vp.x * 0.12, _vp.y * 0.10)
	btf.z_index = 3
	var btf_grad := Gradient.new()
	btf_grad.set_color(0, Color(1.0, 0.55, 0.8, 0.75))
	btf_grad.add_point(0.4, Color(0.6, 0.85, 1.0, 0.7))
	btf_grad.add_point(0.7, Color(1.0, 0.85, 0.3, 0.65))
	btf_grad.set_color(1, Color(0.9, 0.5, 1.0, 0.0))
	btf.color_ramp = btf_grad
	root.add_child(btf)


# ═════════════════════════════════════════════════════════════════════════════
# TIER 3 — Inn: Visitors Arriving
# Lamp post glows + inn chimney smoke + barrel+wagon decorations + chatter
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_3(root: Node2D) -> void:
	# Warm lamp glow pools at path intersections
	_add_lamp_glow(root, Vector2(_vp.x * 0.44, _vp.y * 0.55))
	_add_lamp_glow(root, Vector2(_vp.x * 0.62, _vp.y * 0.55))

	# Inn chimney smoke (inn is at 0.34, 0.50)
	var inn_pos := Vector2(_vp.x * 0.34, _vp.y * 0.50)
	_add_chimney_smoke(root, inn_pos + Vector2(-8 * _sx, -95 * _sy))

	# Barrel cluster near inn
	_add_barrel_cluster(root, Vector2(_vp.x * 0.26, _vp.y * 0.58))

	# Wagon near market area
	_add_small_wagon(root, Vector2(_vp.x * 0.22, _vp.y * 0.74))


# ═════════════════════════════════════════════════════════════════════════════
# TIER 4 — Chapel: Spiritual Life
# Chapel bell (one-shot SFX) + benches + walking NPCs + garden patches
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_4(root: Node2D) -> void:
	# Chapel bell one-shot SFX (only on live unlock, not catch-up)
	AudioManager.play_sfx("chapel_bell")

	# Benches
	_add_bench(root, Vector2(_vp.x * 0.40, _vp.y * 0.63))
	_add_bench(root, Vector2(_vp.x * 0.68, _vp.y * 0.59))

	# Walking NPCs
	var wa := Vector2(_vp.x * 0.48, _vp.y * 0.57)
	var wb := Vector2(_vp.x * 0.60, _vp.y * 0.57)
	var npc_a := _add_walking_npc(root, wa, Color("#9AA8BF"), Color("#F5CBA7"))
	var npc_b := _add_walking_npc(root, wb, Color("#C07B3A"), Color("#F5CBA7"))
	_start_npc_walk(npc_a, wa, wb, 5.0)
	_start_npc_walk(npc_b, wb, wa, 6.0)

	# Garden patches
	_add_garden(root, Vector2(_vp.x * 0.64, _vp.y * 0.57))
	_add_garden(root, Vector2(_vp.x * 0.52, _vp.y * 0.40))


# ═════════════════════════════════════════════════════════════════════════════
# TIER 5 — Library: Culture
# Banners/flags + reading NPC + intensify lamp glows
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_5(root: Node2D) -> void:
	# Pennant flags on poles
	_add_pennant(root, Vector2(_vp.x * 0.50, _vp.y * 0.25), Color("#E8C547"))  # town hall yellow
	_add_pennant(root, Vector2(_vp.x * 0.15, _vp.y * 0.35), Color("#5B9BD5"))  # school blue
	_add_pennant(root, Vector2(_vp.x * 0.82, _vp.y * 0.32), Color("#8B5CF6"))  # library purple

	# Reading NPC near library (library at 0.80, 0.40)
	var lib_pos := Vector2(_vp.x * 0.80, _vp.y * 0.40)
	_add_reading_npc(root, lib_pos + Vector2(45 * _sx, 40 * _sy))

	# Brighter lamp glow boost at existing lamp positions
	_add_lamp_glow(root, Vector2(_vp.x * 0.44, _vp.y * 0.55), 0.18)
	_add_lamp_glow(root, Vector2(_vp.x * 0.62, _vp.y * 0.55), 0.18)


# ═════════════════════════════════════════════════════════════════════════════
# TIER 6 — Well: Infrastructure
# Well sparkles + fountain + path pebbles + water ambient
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_6(root: Node2D) -> void:
	# Well water sparkle particles (well at 0.50, 0.58)
	var well_pos := Vector2(_vp.x * 0.50, _vp.y * 0.58)
	var sparkles := CPUParticles2D.new()
	sparkles.name = "WellSparkles"
	sparkles.emitting = true
	sparkles.one_shot = false
	sparkles.amount = 6
	sparkles.lifetime = 1.8
	sparkles.explosiveness = 0.0
	sparkles.spread = 25.0
	sparkles.direction = Vector2(0, -1)
	sparkles.gravity = Vector2(0, 30)
	sparkles.initial_velocity_min = 12.0
	sparkles.initial_velocity_max = 22.0
	sparkles.scale_amount_min = 1.5
	sparkles.scale_amount_max = 3.5
	sparkles.position = well_pos + Vector2(0, -40 * _sy)
	sparkles.z_index = 4
	var sp_grad := Gradient.new()
	sp_grad.set_color(0, Color(0.6, 0.88, 1.0, 0.8))
	sp_grad.set_color(1, Color(0.8, 0.96, 1.0, 0.0))
	sparkles.color_ramp = sp_grad
	root.add_child(sparkles)

	# Fountain water droplets near town center
	var fountain := CPUParticles2D.new()
	fountain.name = "FountainDroplets"
	fountain.emitting = true
	fountain.one_shot = false
	fountain.amount = 8
	fountain.lifetime = 1.4
	fountain.explosiveness = 0.0
	fountain.spread = 40.0
	fountain.direction = Vector2(0, -1)
	fountain.gravity = Vector2(0, 120)
	fountain.initial_velocity_min = 30.0
	fountain.initial_velocity_max = 55.0
	fountain.scale_amount_min = 2.0
	fountain.scale_amount_max = 4.0
	fountain.position = Vector2(_vp.x * 0.50, _vp.y * 0.65)
	fountain.z_index = 3
	var f_grad := Gradient.new()
	f_grad.set_color(0, Color(0.5, 0.80, 1.0, 0.75))
	f_grad.add_point(0.5, Color(0.65, 0.90, 1.0, 0.55))
	f_grad.set_color(1, Color(0.7, 0.92, 1.0, 0.0))
	fountain.color_ramp = f_grad
	root.add_child(fountain)

	# Extra path pebbles along horizontal path
	for i in range(7):
		var px := _vp.x * (0.30 + i * 0.06)
		var py := _vp.y * 0.61 + randf_range(-6, 6) * _sy
		var pebble := Polygon2D.new()
		pebble.polygon = _oval_pts(px, py, randf_range(3, 5) * _sx, randf_range(2, 4) * _sy, 8)
		pebble.color = Color("#8E8E96") if i % 2 == 0 else Color("#6B6B73")
		pebble.z_index = -1
		root.add_child(pebble)


# ═════════════════════════════════════════════════════════════════════════════
# TIER 7 — Market: Commerce
# Market stalls + more NPCs + hanging lanterns + market bustle audio
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_7(root: Node2D) -> void:
	# Market stalls (market at 0.18, 0.68)
	_add_market_stall(root, Vector2(_vp.x * 0.12, _vp.y * 0.73), Color("#EB6B1F"))
	_add_market_stall(root, Vector2(_vp.x * 0.24, _vp.y * 0.76), Color("#E8C547"))

	# NPCs near market
	var market_pos := Vector2(_vp.x * 0.18, _vp.y * 0.68)
	var mw1a := market_pos + Vector2(50 * _sx, 40 * _sy)
	var mw1b := market_pos + Vector2(90 * _sx, 35 * _sy)
	var mnpc1 := _add_walking_npc(root, mw1a, Color("#EB6B1F"), Color("#F5CBA7"))
	_start_npc_walk(mnpc1, mw1a, mw1b, 4.5)

	var mw2a := market_pos + Vector2(-30 * _sx, 50 * _sy)
	var mw2b := market_pos + Vector2(30 * _sx, 45 * _sy)
	var mnpc2 := _add_walking_npc(root, mw2a, Color("#E94560"), Color("#F5CBA7"))
	_start_npc_walk(mnpc2, mw2a, mw2b, 5.5)

	# Hanging lanterns at 3 positions
	_add_hanging_lantern(root, Vector2(_vp.x * 0.14, _vp.y * 0.60))
	_add_hanging_lantern(root, Vector2(_vp.x * 0.50, _vp.y * 0.53))
	_add_hanging_lantern(root, Vector2(_vp.x * 0.78, _vp.y * 0.62))


# ═════════════════════════════════════════════════════════════════════════════
# CELEBRATION — Tier 8 (bakery fully unlocked)
# ═════════════════════════════════════════════════════════════════════════════
func _launch_celebration() -> void:
	var cel_script := load("res://scripts/TownCelebration.gd")
	if cel_script == null:
		push_warning("[TownLivener] TownCelebration.gd not found — skipping celebration.")
		celebration_finished.emit()
		return

	_celebration = cel_script.new()
	_celebration.name = "TownCelebration"
	get_tree().root.add_child(_celebration)

	if _celebration.has_signal("finished"):
		_celebration.finished.connect(func() -> void:
			celebration_finished.emit()
		)
	else:
		# Fallback: emit after a fixed delay
		get_tree().create_timer(8.0).timeout.connect(func() -> void:
			celebration_finished.emit()
		)

	_celebration.call("start", _vp, _sx, _sy, _building_controllers)


# ═════════════════════════════════════════════════════════════════════════════
# AMBIENT AUDIO HELPERS
# ═════════════════════════════════════════════════════════════════════════════
func _start_ambient(tier: int, fade_in: bool) -> void:
	if _ambient_players.has(tier):
		return  # Already playing
	var cfg: Dictionary = AMBIENT_LAYERS[tier]
	var path: String = cfg["path"]
	var target_db: float = cfg["db"]

	if not ResourceLoader.exists(path):
		push_warning("[TownLivener] Ambient audio not found: %s" % path)
		return

	var player := AudioStreamPlayer.new()
	player.bus = "Master"
	player.volume_db = -40.0
	add_child(player)

	var stream = load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	player.stream = stream
	player.finished.connect(func() -> void:
		if is_instance_valid(player) and player.stream != null:
			player.play()
	)
	player.play()

	if fade_in:
		var tw := create_tween()
		tw.tween_property(player, "volume_db", target_db, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(
			Tween.EASE_OUT
		)
	else:
		player.volume_db = target_db

	_ambient_players[tier] = player


# ═════════════════════════════════════════════════════════════════════════════
# PROP BUILDERS — procedural, all accept a root Node2D parent
# ═════════════════════════════════════════════════════════════════════════════

## Flower cluster (matches Main.gd _add_flowers pattern)
func _add_flowers(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	seed(int(pos.x * 3.7 + pos.y * 5.3))
	var petal_colors := [
		Color("#FF6B6B"), Color("#FFD93D"), Color("#E8A0BF"),
		Color("#FF8E53"), Color("#B088F9"), Color("#7BCFED")
	]
	var center_colors := [Color("#FFE066"), Color("#FFA500"), Color("#FFFFFF")]

	for _fi in range(randi_range(3, 5)):
		var fx := randf_range(-14, 14) * _sx
		var fy := randf_range(-12, 4) * _sy
		var pr := randf_range(3.0, 5.0) * _sx
		var pc: Color = petal_colors[randi() % petal_colors.size()]
		# Stem
		var stem := ColorRect.new()
		stem.color = Color("#3D8B20")
		stem.size = Vector2(2 * _sx, randf_range(7, 13) * _sy)
		stem.position = Vector2(fx - 1 * _sx, fy)
		stem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		group.add_child(stem)
		# Petals
		for pi in range(5):
			var pa := TAU * pi / 5.0
			var petal := _make_circle_panel(
				Vector2(fx + cos(pa) * pr * 1.2 - pr * 0.6, fy + sin(pa) * pr * 1.2 - pr * 0.6),
				pr * 1.2, pc
			)
			group.add_child(petal)
		# Center
		var cc: Color = center_colors[randi() % center_colors.size()]
		group.add_child(_make_circle_panel(Vector2(fx - pr * 0.4, fy - pr * 0.4), pr * 0.8, cc))
	root.add_child(group)


## Warm glow pool beneath a lamp post
func _add_lamp_glow(root: Node2D, pos: Vector2, extra_alpha: float = 0.0) -> void:
	var glow := _make_circle_panel(
		pos - Vector2(28 * _sx, 28 * _sx),
		56 * _sx,
		Color(1.0, 0.85, 0.35, 0.14 + extra_alpha)
	)
	glow.z_index = 1
	root.add_child(glow)
	# Subtle pulse
	var tw := glow.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.7, 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)


## Chimney smoke (replicates BuildingController._make_smoke)
func _add_chimney_smoke(root: Node2D, pos: Vector2) -> void:
	var s := CPUParticles2D.new()
	s.emitting = true
	s.one_shot = false
	s.amount = 8
	s.lifetime = 2.4
	s.explosiveness = 0.0
	s.spread = 16.0
	s.gravity = Vector2(0, -18)
	s.initial_velocity_min = 16.0
	s.initial_velocity_max = 28.0
	s.scale_amount_min = 2.0
	s.scale_amount_max = 4.5
	s.color = Color(0.82, 0.82, 0.82, 0.45)
	s.direction = Vector2(0, -1)
	s.position = pos
	s.z_index = 5
	root.add_child(s)


## Small barrel cluster (simplified)
func _add_barrel_cluster(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(10 * _sx, 4 * _sy, 26 * _sx, 8 * _sy, 10)
	shad.color = Color(0, 0, 0, 0.16)
	group.add_child(shad)
	for i in range(2):
		var bx := float(i) * 22.0 * _sx
		var r := 12.0 * _sx
		group.add_child(_make_circle_panel(Vector2(bx - r, -r * 2.0 - r), r * 2.0, Color("#5C3D11")))
		# Metal bands
		for band_y in [-r * 2.5, -r * 1.5]:
			var band := ColorRect.new()
			band.color = Color("#8B8B8B")
			band.size = Vector2(r * 2.0, 3 * _sy)
			band.position = Vector2(bx - r, band_y)
			band.mouse_filter = Control.MOUSE_FILTER_IGNORE
			group.add_child(band)
	root.add_child(group)


## Small wagon
func _add_small_wagon(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(6 * _sx, 5 * _sy, 26 * _sx, 8 * _sy, 10)
	shad.color = Color(0, 0, 0, 0.16)
	group.add_child(shad)
	_add_rect(group, Vector2(-18 * _sx, -18 * _sy), Vector2(38 * _sx, 15 * _sy), Color("#8B5E3C"))
	_add_rect(group, Vector2(-18 * _sx, -18 * _sy), Vector2(38 * _sx, 2 * _sy),  Color("#5C3D11"))
	group.add_child(_make_circle_panel(Vector2(-20 * _sx, -6 * _sy), 10 * _sx, Color("#3E2408")))
	group.add_child(_make_circle_panel(Vector2(14 * _sx,  -6 * _sy), 10 * _sx, Color("#3E2408")))
	root.add_child(group)


## Bench (matches Main.gd _add_bench)
func _add_bench(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(4 * _sx, 4 * _sy, 28 * _sx, 8 * _sy, 10)
	shad.color = Color(0, 0, 0, 0.16)
	shad.z_index = -1
	group.add_child(shad)
	# Backrest
	_add_rect(group, Vector2(-26 * _sx, -22 * _sy), Vector2(52 * _sx, 6 * _sy), Color("#4A2E0C"))
	# Seat planks
	for i in range(3):
		_add_rect(
			group,
			Vector2(-26 * _sx, -16 * _sy + i * 4 * _sy),
			Vector2(52 * _sx, 4 * _sy),
			Color("#5C3D11") if i % 2 == 0 else Color("#7A5522")
		)
	# Armrests
	for ax in [-26.0 * _sx, 22.0 * _sx]:
		_add_rect(group, Vector2(ax, -22 * _sy), Vector2(6 * _sx, 8 * _sy), Color("#4A2E0C"))
	# Legs
	for lx in [-20.0 * _sx, 14.0 * _sx]:
		_add_rect(group, Vector2(lx, -4 * _sy), Vector2(4 * _sx, 10 * _sy), Color("#3E2408"))
	root.add_child(group)


## Garden patch with small dot "vegetables"
func _add_garden(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Soil patch
	_add_rect(group, Vector2(-18 * _sx, -14 * _sy), Vector2(36 * _sx, 14 * _sy), Color("#4A3018"))
	# Row marks
	for row in range(2):
		_add_rect(
			group,
			Vector2(-18 * _sx, -12 * _sy + row * 6 * _sy),
			Vector2(36 * _sx, 1 * _sy),
			Color("#3A2210")
		)
	# Veggie dots
	var veg_colors := [Color("#3D8B20"), Color("#E03E3E"), Color("#F5A623"), Color("#4DB82A")]
	for vi in range(5):
		var vx := -14 * _sx + vi * 7 * _sx
		var vc: Color = veg_colors[vi % veg_colors.size()]
		group.add_child(_make_circle_panel(Vector2(vx, -16 * _sy), 6 * _sx, vc))
	root.add_child(group)


## Triangular pennant flag on a pole
func _add_pennant(root: Node2D, pos: Vector2, flag_color: Color) -> void:
	var group := Node2D.new()
	group.position = pos
	# Pole
	_add_rect(group, Vector2(-2 * _sx, -60 * _sy), Vector2(4 * _sx, 60 * _sy), Color("#5C3D11"))
	# Flag triangle
	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([
		Vector2(2 * _sx, -58 * _sy),
		Vector2(24 * _sx, -50 * _sy),
		Vector2(2 * _sx, -42 * _sy),
	])
	flag.color = flag_color
	group.add_child(flag)
	# Ground anchor (small dark rect)
	_add_rect(group, Vector2(-4 * _sx, -2 * _sy), Vector2(8 * _sx, 4 * _sy), Color("#3E2408"))
	root.add_child(group)


## Reading NPC seated with a book
func _add_reading_npc(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Shadow
	group.add_child(_make_oval_shadow(Vector2(0, 0), 18 * _sx, 5 * _sy))
	# Body (seated, slightly leaning)
	_add_rect(group, Vector2(-6 * _sx, -26 * _sy), Vector2(12 * _sx, 16 * _sy), Color("#8B5CF6"))
	# Head
	group.add_child(_make_circle_panel(Vector2(-7 * _sx, -38 * _sy), 14 * _sx, Color("#F5CBA7")))
	# Book (in lap)
	_add_rect(group, Vector2(-9 * _sx, -14 * _sy), Vector2(18 * _sx, 12 * _sy), Color("#FFEEDD"))
	_add_rect(group, Vector2(-1 * _sx, -14 * _sy), Vector2(2 * _sx, 12 * _sy), Color("#CCA870"))
	# Gentle head bob
	var tw := group.create_tween().set_loops()
	tw.tween_property(group, "position:y", group.position.y - 2 * _sy, 2.0).set_trans(
		Tween.TRANS_SINE
	)
	tw.tween_property(group, "position:y", group.position.y, 2.0).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Market stall: table + triangular awning
func _add_market_stall(root: Node2D, pos: Vector2, color: Color) -> void:
	var group := Node2D.new()
	group.position = pos
	# Shadow
	group.add_child(_make_oval_shadow(Vector2(0, 0), 32 * _sx, 8 * _sy))
	# Table legs
	for lx in [-22.0 * _sx, 16.0 * _sx]:
		_add_rect(group, Vector2(lx, -24 * _sy), Vector2(4 * _sx, 24 * _sy), Color("#5C3D11"))
	# Table top
	_add_rect(group, Vector2(-26 * _sx, -28 * _sy), Vector2(52 * _sx, 5 * _sy), Color("#8B5E3C"))
	# Items on table (small colored rects as "goods")
	for ii in range(3):
		var ix := -18 * _sx + ii * 14 * _sx
		_add_rect(group, Vector2(ix, -36 * _sy), Vector2(10 * _sx, 8 * _sy), color.lightened(0.3))
	# Awning (triangle)
	var awning := Polygon2D.new()
	awning.polygon = PackedVector2Array([
		Vector2(-32 * _sx, -30 * _sy),
		Vector2(32 * _sx, -30 * _sy),
		Vector2(24 * _sx, -52 * _sy),
		Vector2(-24 * _sx, -52 * _sy),
	])
	awning.color = color
	group.add_child(awning)
	# Awning fringe (darker edge)
	var fringe := ColorRect.new()
	fringe.color = color.darkened(0.2)
	fringe.size = Vector2(64 * _sx, 4 * _sy)
	fringe.position = Vector2(-32 * _sx, -34 * _sy)
	fringe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(fringe)
	root.add_child(group)


## Hanging lantern (warm circle with a string)
func _add_hanging_lantern(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# String
	_add_rect(group, Vector2(-1 * _sx, -22 * _sy), Vector2(2 * _sx, 14 * _sy), Color("#5C3D11"))
	# Lantern body
	group.add_child(_make_circle_panel(Vector2(-6 * _sx, -18 * _sy), 12 * _sx, Color("#E8A030")))
	# Glow
	group.add_child(_make_circle_panel(Vector2(-14 * _sx, -26 * _sy), 28 * _sx, Color(1.0, 0.7, 0.2, 0.15)))
	# Gentle sway
	var tw := group.create_tween().set_loops()
	tw.tween_property(group, "rotation_degrees", 4.0, 1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(group, "rotation_degrees", -4.0, 1.8).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


# ═════════════════════════════════════════════════════════════════════════════
# NPC HELPERS
# ═════════════════════════════════════════════════════════════════════════════

## Idle NPC (standing, gentle bob)
func _add_idle_npc(root: Node2D, pos: Vector2, body_color: Color, head_color: Color) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 10 * _sx, 3 * _sy))
	_add_rect(group, Vector2(-5 * _sx, -20 * _sy), Vector2(10 * _sx, 14 * _sy), body_color)
	group.add_child(_make_circle_panel(Vector2(-5 * _sx, -30 * _sy), 10 * _sx, head_color))
	# Idle bob
	var tw := group.create_tween().set_loops()
	tw.tween_property(group, "position:y", pos.y - 2 * _sy, 1.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(group, "position:y", pos.y, 1.5).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Walking NPC (returns node; caller starts tween via _start_npc_walk)
func _add_walking_npc(root: Node2D, pos: Vector2, body_color: Color, head_color: Color) -> Node2D:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 10 * _sx, 3 * _sy))
	_add_rect(group, Vector2(-5 * _sx, -20 * _sy), Vector2(10 * _sx, 14 * _sy), body_color)
	group.add_child(_make_circle_panel(Vector2(-5 * _sx, -30 * _sy), 10 * _sx, head_color))
	root.add_child(group)
	return group


func _start_npc_walk(npc: Node2D, from: Vector2, to: Vector2, duration: float) -> void:
	var tw := npc.create_tween().set_loops()
	tw.tween_property(npc, "position", to, duration).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
	tw.tween_property(npc, "position", from, duration).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
	_npc_tweens.append(tw)


# ═════════════════════════════════════════════════════════════════════════════
# SHARED PRIMITIVE HELPERS (mirrors Main.gd private helpers)
# ═════════════════════════════════════════════════════════════════════════════

func _make_circle_panel(pos: Vector2, diam: float, color: Color) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	var r := int(diam * 0.5)
	style.bg_color = color
	style.corner_radius_top_left = r
	style.corner_radius_top_right = r
	style.corner_radius_bottom_left = r
	style.corner_radius_bottom_right = r
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	panel.add_theme_stylebox_override("panel", style)
	panel.size = Vector2(diam, diam)
	panel.position = pos
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _make_oval_shadow(pos: Vector2, rx: float, ry: float) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = _oval_pts(pos.x, pos.y, rx, ry, 12)
	p.color = Color(0, 0, 0, 0.16)
	p.z_index = -1
	return p


func _oval_pts(cx: float, cy: float, rx: float, ry: float, steps: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * i / float(steps)
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return pts


func _add_rect(parent: Node, pos: Vector2, sz: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
