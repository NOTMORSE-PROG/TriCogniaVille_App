extends Node2D
## Main.gd — TriCognia Ville top-down village map.
## Procedural: grass + paths + trees + props + scattered buildings + player.
## All objects share a YSortLayer (y_sort_enabled) for correct depth ordering.

enum TreeType { OAK, PINE, FRUIT }

const BUILDING_DATA := [
	{"id": "town_hall", "label": "Town Hall", "color": Color("#E8C547"), "x": 0.50, "y": 0.34},
	{"id": "school", "label": "School", "color": Color("#5B9BD5"), "x": 0.15, "y": 0.44},
	{"id": "inn", "label": "The Inn", "color": Color("#C07B3A"), "x": 0.34, "y": 0.50},
	{"id": "chapel", "label": "The Chapel", "color": Color("#9AA8BF"), "x": 0.64, "y": 0.50},
	{"id": "library", "label": "Library", "color": Color("#8B5CF6"), "x": 0.80, "y": 0.40},
	{"id": "well", "label": "Well", "color": Color("#3E8948"), "x": 0.50, "y": 0.58},
	{"id": "market", "label": "Market", "color": Color("#EB6B1F"), "x": 0.18, "y": 0.68},
	{"id": "bakery", "label": "Bakery", "color": Color("#E94560"), "x": 0.76, "y": 0.64},
]

# ─── Viewport ────────────────────────────────────────────────────────────────
var _vp: Vector2
var _sx: float
var _sy: float

# ─── Scene containers ─────────────────────────────────────────────────────────
var _ysort: Node2D  # y_sort_enabled — holds trees, buildings, props, player
var _joystick: Control  # VirtualJoystick reference

# ─── Quest system ────────────────────────────────────────────────────────────
var _building_controllers: Dictionary = {}  # building_id → BuildingController
var _town_livener: Node2D
var _quest_overlay: Control
var _quest_prompt: Control
var _quest_tracker: Control
var _tutorial_overlay: Control
var _dialogue_panel: Control
var _profile_panel: Control
var _profile_btn: Control

# ─── Preloaded shaders ───────────────────────────────────────────────────────
var _foliage_shader: Shader



# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_vp = get_viewport().get_visible_rect().size
	# Uniform scale: prevents horizontal stretching on wider-than-16:9 phones
	# (e.g. 20:9 / 19.5:9 landscape devices). _sx and _sy are kept as
	# separate variables so the ~40 call sites below don't need editing.
	var scale_val: float = min(_vp.x / 1920.0, _vp.y / 1080.0)
	_sx = scale_val
	_sy = scale_val

	_foliage_shader = load("res://shaders/foliage_sway.gdshader")

	# Y-Sort layer — all depth-ordered objects go here
	_ysort = Node2D.new()
	_ysort.y_sort_enabled = true
	_ysort.name = "YSortLayer"
	add_child(_ysort)

	_build_grass()
	_build_paths()
	_build_trees()
	_build_props()
	_spawn_buildings()
	_build_ui()  # must come before _spawn_player (player needs joystick ref)
	_spawn_player()
	_build_town_livener()
	_connect_signals()
	_build_quest_tracker()
	_build_vignette()
	_check_tutorial()
	AudioManager.start_village_music()


# ═════════════════════════════════════════════════════════════════════════════
# GRASS  z=-10  (3-layer: base + ink-blob patches + noise-driven tufts)
# ═════════════════════════════════════════════════════════════════════════════
func _build_grass() -> void:
	# ── Layer 0: Procedural grass shader base ──
	var base := ColorRect.new()
	base.color = Color("#3d9815")
	base.size = _vp
	base.z_index = -10
	var grass_mat := ShaderMaterial.new()
	grass_mat.shader = load("res://shaders/grass_procedural.gdshader")
	base.material = grass_mat
	add_child(base)

	# ── Layer 1: Irregular ink-blob patches (~35) — elongated, not circular ──
	seed(42)
	for _i in range(35):
		var cx := randf() * _vp.x
		var cy := randf() * _vp.y
		var r := randf_range(45.0, 140.0) * _sx
		var pts := PackedVector2Array()
		for v in range(9):
			var a := TAU * v / 9.0
			var push := r * randf_range(0.60, 1.35)
			pts.append(
				Vector2(
					cx + cos(a) * push * randf_range(1.1, 1.9),
					cy + sin(a) * push * randf_range(0.45, 0.80)
				)
			)
		var blob := Polygon2D.new()
		blob.polygon = pts
		var bc := Color("#44a318")
		bc.a = randf_range(0.40, 0.55)
		blob.color = bc
		blob.z_index = -10
		add_child(blob)

	# ── Layer 2: Noise-driven grass blade clusters (~50, 3 blades each) ──
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.03
	noise.seed = 77
	seed(55)
	var tuft_colors := [
		Color("#70c725"), Color("#5BAF20"), Color("#8ED44B"), Color("#4DB82A"), Color("#3D9815")
	]
	var placed := 0
	var tries := 0
	while placed < 50 and tries < 500:
		tries += 1
		var tx := randf() * _vp.x
		var ty := randf() * _vp.y
		if noise.get_noise_2d(tx, ty) > 0.10:
			var rot := randf_range(-20.0, 20.0)
			var sf := randf_range(0.9, 1.5) * _sx
			# Draw 3 blades per cluster
			for blade_i in range(3):
				var blade_offset := randf_range(-4.0, 4.0) * _sx
				var blade_rot := rot + randf_range(-15.0, 15.0)
				var blade_sf := sf * randf_range(0.7, 1.1)
				var tuft := Polygon2D.new()
				tuft.polygon = _blade_pts(tx + blade_offset, ty, blade_rot, blade_sf)
				var tc: Color = tuft_colors[randi() % tuft_colors.size()]
				tc.a = randf_range(0.50, 0.70)
				tuft.color = tc
				tuft.z_index = -9
				add_child(tuft)
			placed += 1


# ═════════════════════════════════════════════════════════════════════════════
# DIRT PATH NETWORK  z=-9  (3-zone depth + grass fringe + pebble scatter)
# ═════════════════════════════════════════════════════════════════════════════
func _build_paths() -> void:
	var c_edge := Color("#8a5a10")
	var c_mid := Color("#c4811a")
	var c_center := Color("#ecac22")
	var c_fringe := Color("#328530")

	# Preload dirt shader for textured paths
	var _path_shader: Shader = load("res://shaders/path_dirt.gdshader")

	# ── Path geometry (same positions as before) ──
	var vx0 := _vp.x * 0.46
	var vx1 := _vp.x * 0.54
	var vw := vx1 - vx0
	var hy0 := _vp.y * 0.56
	var hy1 := _vp.y * 0.66
	var hh := hy1 - hy0
	var sbx0 := _vp.x * 0.11
	var sbx1 := _vp.x * 0.19
	var sbw := sbx1 - sbx0
	var sbyo := _vp.y * 0.44
	var sbyb := hy0
	var lbx0 := _vp.x * 0.76
	var lbx1 := _vp.x * 0.84
	var lbw := lbx1 - lbx0
	var lbyo := _vp.y * 0.40
	var lbyb := hy0

	# ── Pass 1: Edge bases (full width, darkest) + dirt shader ──
	_add_path_rect(Vector2(vx0, 0), Vector2(vw, _vp.y), c_edge, _path_shader, "#6B3A0A", "#8a5a10")
	_add_path_rect(Vector2(0, hy0), Vector2(_vp.x, hh), c_edge, _path_shader, "#6B3A0A", "#8a5a10")
	_add_path_rect(
		Vector2(sbx0, sbyo), Vector2(sbw, sbyb - sbyo), c_edge, _path_shader, "#6B3A0A", "#8a5a10"
	)
	_add_path_rect(
		Vector2(lbx0, lbyo), Vector2(lbw, lbyb - lbyo), c_edge, _path_shader, "#6B3A0A", "#8a5a10"
	)

	# ── Pass 2: Grass fringe tabs along all path edges ──
	seed(201)
	_path_fringe_v(vx0, 0.0, _vp.y, true, c_fringe)
	_path_fringe_v(vx1, 0.0, _vp.y, false, c_fringe)
	_path_fringe_h(hy0, 0.0, _vp.x, true, c_fringe)
	_path_fringe_h(hy1, 0.0, _vp.x, false, c_fringe)
	_path_fringe_v(sbx0, sbyo, sbyb - sbyo, true, c_fringe)
	_path_fringe_v(sbx1, sbyo, sbyb - sbyo, false, c_fringe)
	_path_fringe_v(lbx0, lbyo, lbyb - lbyo, true, c_fringe)
	_path_fringe_v(lbx1, lbyo, lbyb - lbyo, false, c_fringe)

	# ── Pass 3: Mid zones (80% of path width, medium dirt) ──
	_add_path_rect(
		Vector2(vx0 + vw * 0.10, 0),
		Vector2(vw * 0.80, _vp.y),
		c_mid,
		_path_shader,
		"#8a5a10",
		"#c4811a"
	)
	_add_path_rect(
		Vector2(0, hy0 + hh * 0.10),
		Vector2(_vp.x, hh * 0.80),
		c_mid,
		_path_shader,
		"#8a5a10",
		"#c4811a"
	)
	_add_path_rect(
		Vector2(sbx0 + sbw * 0.10, sbyo),
		Vector2(sbw * 0.80, sbyb - sbyo),
		c_mid,
		_path_shader,
		"#8a5a10",
		"#c4811a"
	)
	_add_path_rect(
		Vector2(lbx0 + lbw * 0.10, lbyo),
		Vector2(lbw * 0.80, lbyb - lbyo),
		c_mid,
		_path_shader,
		"#8a5a10",
		"#c4811a"
	)

	# ── Pass 4: Center strips (40% of path width, lightest — most worn) ──
	_add_path_rect(
		Vector2(vx0 + vw * 0.30, 0),
		Vector2(vw * 0.40, _vp.y),
		c_center,
		_path_shader,
		"#c4811a",
		"#ecac22"
	)
	_add_path_rect(
		Vector2(0, hy0 + hh * 0.30),
		Vector2(_vp.x, hh * 0.40),
		c_center,
		_path_shader,
		"#c4811a",
		"#ecac22"
	)
	_add_path_rect(
		Vector2(sbx0 + sbw * 0.30, sbyo),
		Vector2(sbw * 0.40, sbyb - sbyo),
		c_center,
		_path_shader,
		"#c4811a",
		"#ecac22"
	)
	_add_path_rect(
		Vector2(lbx0 + lbw * 0.30, lbyo),
		Vector2(lbw * 0.40, lbyb - lbyo),
		c_center,
		_path_shader,
		"#c4811a",
		"#ecac22"
	)

	# ── Pass 5: Crossroads cobblestone circle ──
	var cross_cx := (vx0 + vx1) * 0.5
	var cross_cy := (hy0 + hy1) * 0.5
	# Concentric stone rings — tight around the crossroads center
	var stone_colors := [
		Color("#7A6E65"), Color("#6E6358"), Color("#8A7D72"), Color("#6A5E55"), Color("#9A8D80")
	]
	for ring in range(4, 0, -1):
		var rx := vw * 0.05 * ring
		var ry := hh * 0.045 * ring
		var stone_ring := Polygon2D.new()
		stone_ring.polygon = _oval_pts(cross_cx, cross_cy, rx, ry, 16 + ring * 4)
		stone_ring.color = stone_colors[ring % stone_colors.size()]
		stone_ring.z_index = -9
		add_child(stone_ring)
	# Center worn area
	var center_stone := Polygon2D.new()
	center_stone.polygon = _oval_pts(cross_cx, cross_cy, vw * 0.04, hh * 0.035, 12)
	center_stone.color = Color("#A09080")
	center_stone.z_index = -9
	add_child(center_stone)
	# Individual stone gaps
	seed(333)
	for _i in range(12):
		var sa := randf() * TAU
		var sd := randf_range(0.3, 0.9)
		var gap_x := cross_cx + cos(sa) * vw * 0.05 * 3 * sd
		var gap_y := cross_cy + sin(sa) * hh * 0.045 * 3 * sd
		var gap := Polygon2D.new()
		gap.polygon = _oval_pts(gap_x, gap_y, 2 * _sx, 1.5 * _sy, 6)
		var gc := Color("#4B3B2B")
		gc.a = 0.40
		gap.color = gc
		gap.z_index = -9
		add_child(gap)

	# ── Pass 6: Pebble scatter (~35 micro-ellipses, noise-clustered) ──
	var pn := FastNoiseLite.new()
	pn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	pn.frequency = 0.10
	pn.seed = 44
	seed(123)
	var pcount := 0
	var pattempts := 0
	while pcount < 35 and pattempts < 500:
		pattempts += 1
		var px := 0.0
		var py := 0.0
		match randi() % 4:
			0:
				px = randf_range(vx0, vx1)
				py = randf() * _vp.y
			1:
				px = randf() * _vp.x
				py = randf_range(hy0, hy1)
			2:
				px = randf_range(sbx0, sbx1)
				py = randf_range(sbyo, sbyb)
			_:
				px = randf_range(lbx0, lbx1)
				py = randf_range(lbyo, lbyb)
		if pn.get_noise_2d(px, py) > 0.30:
			var prx := randf_range(3.0, 5.5) * _sx
			var pry := randf_range(1.5, 3.0) * _sy
			var pebble := Polygon2D.new()
			pebble.polygon = _oval_pts(px, py, prx, pry, 8)
			pebble.color = Color("#c8a882") if randf() > 0.5 else Color("#9ea8a8")
			pebble.z_index = -9
			add_child(pebble)
			pcount += 1


# ═════════════════════════════════════════════════════════════════════════════
# TREES  — multi-blob foliage with trunks, variety, added to _ysort
# ═════════════════════════════════════════════════════════════════════════════
func _build_trees() -> void:
	var r := 36.0 * _sx  # large tree radius
	var sr := 26.0 * _sx  # small tree radius

	# Corner trees (large oaks)
	_make_top_tree(_vp.x * 0.04, _vp.y * 0.08, r, TreeType.OAK)
	_make_top_tree(_vp.x * 0.94, _vp.y * 0.07, r, TreeType.OAK)
	_make_top_tree(_vp.x * 0.03, _vp.y * 0.88, r, TreeType.PINE)
	_make_top_tree(_vp.x * 0.95, _vp.y * 0.90, r, TreeType.OAK)

	# Town Hall flanking trees (small pines)
	_make_top_tree(_vp.x * 0.38, _vp.y * 0.18, sr, TreeType.PINE)
	_make_top_tree(_vp.x * 0.62, _vp.y * 0.20, sr, TreeType.PINE)

	# School area
	_make_top_tree(_vp.x * 0.05, _vp.y * 0.52, sr, TreeType.OAK)
	_make_top_tree(_vp.x * 0.28, _vp.y * 0.50, r, TreeType.OAK)

	# Library area
	_make_top_tree(_vp.x * 0.92, _vp.y * 0.50, sr, TreeType.OAK)
	_make_top_tree(_vp.x * 0.70, _vp.y * 0.50, sr, TreeType.PINE)

	# Gap fillers — fruit trees near market
	_make_top_tree(_vp.x * 0.36, _vp.y * 0.80, sr, TreeType.FRUIT)
	_make_top_tree(_vp.x * 0.64, _vp.y * 0.82, sr, TreeType.OAK)
	_make_top_tree(_vp.x * 0.08, _vp.y * 0.80, r, TreeType.OAK)
	_make_top_tree(_vp.x * 0.90, _vp.y * 0.78, sr, TreeType.FRUIT)


func _make_top_tree(cx: float, cy: float, r: float, type: TreeType = TreeType.OAK) -> void:
	var root := Node2D.new()
	root.position = Vector2(cx, cy)
	seed(int(cx * 7.3 + cy * 3.1))

	# Ground shadow oval (larger, softer)
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(r * 0.2, r * 0.5, r * 1.0, r * 0.35, 18)
	shad.color = Color(0.0, 0.0, 0.0, 0.20)
	shad.z_index = -1
	root.add_child(shad)

	# Fallen leaf scatter (4–6 leaf shapes)
	var leaf_colors := [
		Color("#c87820"), Color("#d4943a"), Color("#b06818"), Color("#e8a848"), Color("#a05010")
	]
	for _i in range(randi_range(4, 6)):
		var lx := randf_range(-r * 0.9, r * 0.9)
		var ly := randf_range(-r * 0.3, r * 0.6)
		var lr := randf_range(3.0, 6.0) * _sx
		var rot := randf_range(0.0, TAU)
		var cr2 := cos(rot)
		var sr2 := sin(rot)
		# Leaf shape (5-point, slightly curved)
		var lpts := PackedVector2Array()
		for p in [
			Vector2(0.0, -lr * 1.3),
			Vector2(lr * 0.7, -lr * 0.3),
			Vector2(lr * 0.4, lr * 0.8),
			Vector2(-lr * 0.4, lr * 0.8),
			Vector2(-lr * 0.7, -lr * 0.3)
		]:
			lpts.append(Vector2(p.x * cr2 - p.y * sr2 + lx, p.x * sr2 + p.y * cr2 + ly))
		var leaf := Polygon2D.new()
		leaf.polygon = lpts
		var lc: Color = leaf_colors[randi() % leaf_colors.size()]
		lc.a = randf_range(0.25, 0.45)
		leaf.color = lc
		leaf.z_index = -1
		root.add_child(leaf)

	# Trunk (visible beneath foliage)
	var trunk_w := r * 0.22
	var trunk_h := r * 0.6
	var trunk := ColorRect.new()
	trunk.color = Color("#5C3D11")
	trunk.size = Vector2(trunk_w, trunk_h)
	trunk.position = Vector2(-trunk_w * 0.5, -trunk_h * 0.3)
	root.add_child(trunk)
	# Trunk highlight strip
	var trunk_hi := ColorRect.new()
	trunk_hi.color = Color("#7A5522")
	trunk_hi.size = Vector2(trunk_w * 0.3, trunk_h * 0.8)
	trunk_hi.position = Vector2(-trunk_w * 0.1, -trunk_h * 0.2)
	root.add_child(trunk_hi)

	match type:
		TreeType.OAK:
			_build_oak_foliage(root, r)
		TreeType.PINE:
			_build_pine_foliage(root, r)
		TreeType.FRUIT:
			_build_oak_foliage(root, r)
			_add_fruit_dots(root, r)

	_ysort.add_child(root)


func _make_foliage_circle(pos: Vector2, diam: float, color: Color) -> Panel:
	var panel := _make_circle_panel(pos, diam, color)
	var mat := ShaderMaterial.new()
	mat.shader = _foliage_shader
	panel.material = mat
	return panel


func _build_oak_foliage(root: Node2D, r: float) -> void:
	# Multi-blob canopy: 4-5 overlapping circles of varying size and position
	var base_green := Color("#328530")
	var mid_green := Color("#3D9815")
	var light_green := Color("#70c725")
	var dark_green := Color("#285f0a")

	# Back shadow blob (lower-right)
	var b0 := _make_foliage_circle(Vector2(r * 0.05, -r * 0.6), r * 1.4, dark_green)
	root.add_child(b0)

	# Main central blob
	var b1 := _make_foliage_circle(Vector2(-r * 0.85, -r * 0.95), r * 1.7, base_green)
	root.add_child(b1)

	# Upper-left cluster
	var b2 := _make_foliage_circle(Vector2(-r * 1.1, -r * 1.3), r * 1.2, mid_green)
	root.add_child(b2)

	# Right cluster
	var b3 := _make_foliage_circle(Vector2(r * 0.1, -r * 1.1), r * 1.1, mid_green)
	root.add_child(b3)

	# Top highlight blob
	var b4 := _make_foliage_circle(Vector2(-r * 0.6, -r * 1.4), r * 0.9, light_green)
	root.add_child(b4)

	# Small bright accent
	var b5 := _make_foliage_circle(Vector2(-r * 0.3, -r * 1.5), r * 0.5, Color("#8ED44B"))
	root.add_child(b5)


func _build_pine_foliage(root: Node2D, r: float) -> void:
	# Layered triangle/diamond shapes for conifer look
	var pine_dark := Color("#1B5E20")
	var pine_mid := Color("#2E7D32")
	var pine_light := Color("#43A047")

	# Bottom layer (widest)
	var tier1 := Polygon2D.new()
	tier1.polygon = PackedVector2Array(
		[
			Vector2(0.0, -r * 0.3),
			Vector2(-r * 1.1, -r * 0.8),
			Vector2(-r * 0.6, -r * 1.0),
			Vector2(0.0, -r * 0.7),
			Vector2(r * 0.6, -r * 1.0),
			Vector2(r * 1.1, -r * 0.8),
		]
	)
	tier1.color = pine_dark
	root.add_child(tier1)

	# Middle layer
	var tier2 := Polygon2D.new()
	tier2.polygon = PackedVector2Array(
		[
			Vector2(0.0, -r * 0.6),
			Vector2(-r * 0.85, -r * 1.1),
			Vector2(-r * 0.4, -r * 1.3),
			Vector2(0.0, -r * 1.0),
			Vector2(r * 0.4, -r * 1.3),
			Vector2(r * 0.85, -r * 1.1),
		]
	)
	tier2.color = pine_mid
	root.add_child(tier2)

	# Top layer (smallest)
	var tier3 := Polygon2D.new()
	tier3.polygon = PackedVector2Array(
		[
			Vector2(0.0, -r * 0.95),
			Vector2(-r * 0.55, -r * 1.35),
			Vector2(-r * 0.2, -r * 1.55),
			Vector2(0.0, -r * 1.7),
			Vector2(r * 0.2, -r * 1.55),
			Vector2(r * 0.55, -r * 1.35),
		]
	)
	tier3.color = pine_light
	root.add_child(tier3)


func _add_fruit_dots(root: Node2D, r: float) -> void:
	# Scatter colorful fruit dots on the canopy
	var fruit_colors := [
		Color("#E03E3E"), Color("#FF6B6B"), Color("#FFD93D"), Color("#FF8E53"), Color("#E03E3E")
	]
	for _i in range(randi_range(5, 8)):
		var fx := randf_range(-r * 0.8, r * 0.8)
		var fy := randf_range(-r * 1.4, -r * 0.6)
		var fr := randf_range(2.5, 4.0) * _sx
		var fruit := _make_circle_panel(
			Vector2(fx - fr, fy - fr), fr * 2.0, fruit_colors[randi() % fruit_colors.size()]
		)
		root.add_child(fruit)


# ═════════════════════════════════════════════════════════════════════════════
# PROPS — benches, crates, barrels, flowers (in _ysort for depth sort)
# ═════════════════════════════════════════════════════════════════════════════
func _build_props() -> void:
	_add_bench(Vector2(_vp.x * 0.61, _vp.y * 0.30))
	_add_notice_board(Vector2(_vp.x * 0.41, _vp.y * 0.30))
	_add_crates(Vector2(_vp.x * 0.08, _vp.y * 0.61))
	_add_barrels(Vector2(_vp.x * 0.91, _vp.y * 0.61))
	_add_flowers(Vector2(_vp.x * 0.10, _vp.y * 0.32))
	_add_flowers(Vector2(_vp.x * 0.88, _vp.y * 0.30))
	_add_flowers(Vector2(_vp.x * 0.41, _vp.y * 0.76))
	_add_flowers(Vector2(_vp.x * 0.60, _vp.y * 0.76))
	_add_flowers(Vector2(_vp.x * 0.25, _vp.y * 0.22))
	# Water shimmer at well position (well is at x=0.50, y=0.58)
	_add_water_shimmer(Vector2(_vp.x * 0.50, _vp.y * 0.58))
	# New props
	_add_lamp_post(Vector2(_vp.x * 0.44, _vp.y * 0.50))
	_add_lamp_post(Vector2(_vp.x * 0.56, _vp.y * 0.50))
	_add_fence_segment(Vector2(_vp.x * 0.24, _vp.y * 0.40))
	_add_fence_segment(Vector2(_vp.x * 0.72, _vp.y * 0.36))
	_add_stepping_stones(Vector2(_vp.x * 0.50, _vp.y * 0.52))
	_add_wagon(Vector2(_vp.x * 0.26, _vp.y * 0.72))
	_add_mailbox(Vector2(_vp.x * 0.58, _vp.y * 0.28))


func _add_bench(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	# Shadow
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(4 * _sx, 4 * _sy, 30 * _sx, 8 * _sy, 10)
	shad.color = Color(0, 0, 0, 0.18)
	shad.z_index = -1
	root.add_child(shad)
	# Backrest
	var back := ColorRect.new()
	back.color = Color("#4A2E0C")
	back.size = Vector2(52 * _sx, 6 * _sy)
	back.position = Vector2(-26 * _sx, -22 * _sy)
	root.add_child(back)
	# Seat plank (wood grain: alternating strips)
	for i in range(3):
		var plank := ColorRect.new()
		plank.color = Color("#5C3D11") if i % 2 == 0 else Color("#7A5522")
		plank.size = Vector2(52 * _sx, 4 * _sy)
		plank.position = Vector2(-26 * _sx, -16 * _sy + i * 4 * _sy)
		root.add_child(plank)
	# Armrests
	for ax in [-26.0 * _sx, 22.0 * _sx]:
		var arm := ColorRect.new()
		arm.color = Color("#4A2E0C")
		arm.size = Vector2(6 * _sx, 8 * _sy)
		arm.position = Vector2(ax, -22 * _sy)
		root.add_child(arm)
	# Legs (×2)
	for lx in [-20.0 * _sx, 14.0 * _sx]:
		var leg := ColorRect.new()
		leg.color = Color("#3E2408")
		leg.size = Vector2(4 * _sx, 10 * _sy)
		leg.position = Vector2(lx, -4 * _sy)
		root.add_child(leg)
	_ysort.add_child(root)


func _add_notice_board(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	# Shadow
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(0, 2 * _sy, 20 * _sx, 6 * _sy, 8)
	shad.color = Color(0, 0, 0, 0.15)
	root.add_child(shad)
	# Post
	var post := ColorRect.new()
	post.color = Color("#5C3D11")
	post.size = Vector2(6 * _sx, 32 * _sy)
	post.position = Vector2(-3 * _sx, -32 * _sy)
	root.add_child(post)
	# Peaked roof over board
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array(
		[
			Vector2(-20 * _sx, -52 * _sy),
			Vector2(0, -60 * _sy),
			Vector2(20 * _sx, -52 * _sy),
		]
	)
	roof.color = Color("#8B5E3C")
	root.add_child(roof)
	# Board
	var board := ColorRect.new()
	board.color = Color("#DEB887")
	board.size = Vector2(36 * _sx, 24 * _sy)
	board.position = Vector2(-18 * _sx, -52 * _sy)
	root.add_child(board)
	# Board frame
	_add_rect_child(
		root, Vector2(-18 * _sx, -52 * _sy), Vector2(36 * _sx, 2 * _sy), Color("#8B6914")
	)
	_add_rect_child(
		root, Vector2(-18 * _sx, -30 * _sy), Vector2(36 * _sx, 2 * _sy), Color("#8B6914")
	)
	_add_rect_child(
		root, Vector2(-18 * _sx, -52 * _sy), Vector2(2 * _sx, 24 * _sy), Color("#8B6914")
	)
	_add_rect_child(
		root, Vector2(16 * _sx, -52 * _sy), Vector2(2 * _sx, 24 * _sy), Color("#8B6914")
	)
	# Paper notes pinned to board
	_add_rect_child(
		root, Vector2(-12 * _sx, -48 * _sy), Vector2(10 * _sx, 12 * _sy), Color("#FFFEF5")
	)
	_add_rect_child(root, Vector2(2 * _sx, -46 * _sy), Vector2(9 * _sx, 10 * _sy), Color("#F5F0E0"))
	_add_rect_child(root, Vector2(-6 * _sx, -42 * _sy), Vector2(8 * _sx, 8 * _sy), Color("#FFEEDD"))
	# Pin dots
	for px in [
		Vector2(-7 * _sx, -49 * _sy), Vector2(6 * _sx, -47 * _sy), Vector2(-2 * _sx, -43 * _sy)
	]:
		var pin := _make_circle_panel(px, 3 * _sx, Color("#E03E3E"))
		root.add_child(pin)
	_ysort.add_child(root)


func _add_crates(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	# Shadow
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(12 * _sx, 4 * _sy, 28 * _sx, 8 * _sy, 10)
	shad.color = Color(0, 0, 0, 0.18)
	root.add_child(shad)
	# Crate 1 (bottom)
	var c1_pos := Vector2(-15 * _sx, -28 * _sy)
	_add_rect_child(root, c1_pos, Vector2(30 * _sx, 28 * _sy), Color("#8B5E3C"))
	# Cross planks
	_add_rect_child(
		root, c1_pos + Vector2(0, 13 * _sy), Vector2(30 * _sx, 2 * _sy), Color("#5C3D11")
	)
	_add_rect_child(
		root, c1_pos + Vector2(14 * _sx, 0), Vector2(2 * _sx, 28 * _sy), Color("#5C3D11")
	)
	# Lid
	_add_rect_child(root, c1_pos, Vector2(30 * _sx, 3 * _sy), Color("#6B4B2A"))
	# Crate 2 (offset, slightly rotated look)
	var c2_pos := Vector2(10 * _sx, -34 * _sy)
	_add_rect_child(root, c2_pos, Vector2(26 * _sx, 26 * _sy), Color("#9B6E4C"))
	_add_rect_child(
		root, c2_pos + Vector2(0, 12 * _sy), Vector2(26 * _sx, 2 * _sy), Color("#6B4B2A")
	)
	_add_rect_child(
		root, c2_pos + Vector2(12 * _sx, 0), Vector2(2 * _sx, 26 * _sy), Color("#6B4B2A")
	)
	_add_rect_child(root, c2_pos, Vector2(26 * _sx, 3 * _sy), Color("#5C3D11"))
	_ysort.add_child(root)


func _add_barrels(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	# Shadow
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(14 * _sx, 4 * _sy, 28 * _sx, 8 * _sy, 10)
	shad.color = Color(0, 0, 0, 0.18)
	root.add_child(shad)
	var bx_offsets := [0.0, 26.0 * _sx]
	for idx in bx_offsets.size():
		var bx: float = bx_offsets[idx]
		var r := 14.0 * _sx
		# Main barrel body
		var barrel := _make_circle_panel(Vector2(bx - r, -r * 2.0 - r), r * 2.0, Color("#5C3D11"))
		root.add_child(barrel)
		# Stave lines (alternating darker strips)
		for sx_off in range(-int(r * 0.6), int(r * 0.6), 4):
			var stave := ColorRect.new()
			stave.color = Color("#4A2E0C")
			stave.size = Vector2(1, r * 1.6)
			stave.position = Vector2(bx + sx_off, -r * 2.8)
			stave.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(stave)
		# Metal bands (×2)
		for band_y in [-r * 2.6, -r * 1.6]:
			var band := ColorRect.new()
			band.color = Color("#8B8B8B")
			band.size = Vector2(r * 2.0, 3 * _sy)
			band.position = Vector2(bx - r, band_y)
			root.add_child(band)
		# Barrel top highlight
		var top := _make_circle_panel(Vector2(bx - r * 0.7, -r * 2.9), r * 1.4, Color("#7A5522"))
		root.add_child(top)
	_ysort.add_child(root)


func _add_flowers(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	seed(int(pos.x * 3.7 + pos.y * 5.3))
	var petal_colors := [
		Color("#FF6B6B"),
		Color("#FFD93D"),
		Color("#E8A0BF"),
		Color("#FF8E53"),
		Color("#B088F9"),
		Color("#7BCFED")
	]
	var center_colors := [Color("#FFE066"), Color("#FFA500"), Color("#FFFFFF")]

	for fi in range(randi_range(3, 5)):
		var fx := randf_range(-16, 16) * _sx
		var fy := randf_range(-16, 4) * _sy
		var petal_r := randf_range(3.0, 5.0) * _sx
		var pc: Color = petal_colors[randi() % petal_colors.size()]

		# Stem
		var stem := ColorRect.new()
		stem.color = Color("#3D8B20")
		stem.size = Vector2(2 * _sx, randf_range(8, 14) * _sy)
		stem.position = Vector2(fx - 1 * _sx, fy)
		root.add_child(stem)
		# Leaf on stem
		var leaf := Polygon2D.new()
		leaf.polygon = PackedVector2Array(
			[
				Vector2(fx + 1 * _sx, fy + 4 * _sy),
				Vector2(fx + 6 * _sx, fy + 2 * _sy),
				Vector2(fx + 4 * _sx, fy + 6 * _sy),
			]
		)
		leaf.color = Color("#4DB82A")
		root.add_child(leaf)

		# Daisy petals (5 small circles around center)
		for pi in range(5):
			var pa := TAU * pi / 5.0
			var px := fx + cos(pa) * petal_r * 1.2
			var py := fy + sin(pa) * petal_r * 1.2
			var petal := _make_circle_panel(
				Vector2(px - petal_r * 0.6, py - petal_r * 0.6), petal_r * 1.2, pc
			)
			root.add_child(petal)
		# Center
		var cc: Color = center_colors[randi() % center_colors.size()]
		var center := _make_circle_panel(
			Vector2(fx - petal_r * 0.4, fy - petal_r * 0.4), petal_r * 0.8, cc
		)
		root.add_child(center)
	_ysort.add_child(root)


func _add_lamp_post(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	# Shadow
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(0, 2 * _sy, 10 * _sx, 4 * _sy, 8)
	shad.color = Color(0, 0, 0, 0.15)
	root.add_child(shad)
	# Post
	var post := ColorRect.new()
	post.color = Color("#4A4A52")
	post.size = Vector2(4 * _sx, 50 * _sy)
	post.position = Vector2(-2 * _sx, -50 * _sy)
	root.add_child(post)
	# Base plate
	_add_rect_child(root, Vector2(-6 * _sx, -4 * _sy), Vector2(12 * _sx, 4 * _sy), Color("#3A3A42"))
	# Lamp head
	_add_rect_child(
		root, Vector2(-6 * _sx, -56 * _sy), Vector2(12 * _sx, 8 * _sy), Color("#6B6B73")
	)
	# Warm glow (large soft circle)
	var glow := _make_circle_panel(
		Vector2(-18 * _sx, -62 * _sy), 36 * _sx, Color(1.0, 0.85, 0.4, 0.12)
	)
	root.add_child(glow)
	# Lamp light (bright center)
	var light := _make_circle_panel(Vector2(-4 * _sx, -54 * _sy), 8 * _sx, Color("#FFE4A0"))
	root.add_child(light)
	_ysort.add_child(root)


func _add_fence_segment(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	var post_color := Color("#8B6914")
	var rail_color := Color("#A88A4A")
	# 3 fence posts
	for i in range(3):
		var px := float(i) * 18 * _sx - 18 * _sx
		_add_rect_child(root, Vector2(px, -24 * _sy), Vector2(4 * _sx, 24 * _sy), post_color)
		# Post cap
		_add_rect_child(
			root, Vector2(px - 1 * _sx, -26 * _sy), Vector2(6 * _sx, 3 * _sy), Color("#6B4B1A")
		)
	# 2 horizontal rails
	_add_rect_child(root, Vector2(-18 * _sx, -20 * _sy), Vector2(36 * _sx, 3 * _sy), rail_color)
	_add_rect_child(root, Vector2(-18 * _sx, -10 * _sy), Vector2(36 * _sx, 3 * _sy), rail_color)
	_ysort.add_child(root)


func _add_stepping_stones(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	var stone_offsets := [
		Vector2(-8 * _sx, -4 * _sy),
		Vector2(6 * _sx, -12 * _sy),
		Vector2(-4 * _sx, -20 * _sy),
		Vector2(8 * _sx, -28 * _sy),
	]
	for off in stone_offsets:
		var stone := Polygon2D.new()
		stone.polygon = _oval_pts(off.x, off.y, randf_range(5, 7) * _sx, randf_range(3, 5) * _sy, 8)
		stone.color = Color("#8E8E96") if randf() > 0.5 else Color("#6B6B73")
		stone.z_index = -1
		root.add_child(stone)
	_ysort.add_child(root)


func _add_wagon(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	# Shadow
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(8 * _sx, 6 * _sy, 30 * _sx, 10 * _sy, 10)
	shad.color = Color(0, 0, 0, 0.18)
	root.add_child(shad)
	# Wagon body
	_add_rect_child(
		root, Vector2(-20 * _sx, -22 * _sy), Vector2(44 * _sx, 18 * _sy), Color("#8B5E3C")
	)
	# Side plank detail
	_add_rect_child(
		root, Vector2(-20 * _sx, -22 * _sy), Vector2(44 * _sx, 2 * _sy), Color("#5C3D11")
	)
	_add_rect_child(
		root, Vector2(-20 * _sx, -12 * _sy), Vector2(44 * _sx, 2 * _sy), Color("#5C3D11")
	)
	# Wheels (×2)
	var wheel_col := Color("#3E2408")
	var wl := _make_circle_panel(Vector2(-22 * _sx, -8 * _sy), 12 * _sx, wheel_col)
	root.add_child(wl)
	var wr := _make_circle_panel(Vector2(16 * _sx, -8 * _sy), 12 * _sx, wheel_col)
	root.add_child(wr)
	# Wheel hub
	var wlh := _make_circle_panel(Vector2(-18 * _sx, -4 * _sy), 4 * _sx, Color("#8B6914"))
	root.add_child(wlh)
	var wrh := _make_circle_panel(Vector2(20 * _sx, -4 * _sy), 4 * _sx, Color("#8B6914"))
	root.add_child(wrh)
	# Handle/pole
	_add_rect_child(
		root, Vector2(24 * _sx, -14 * _sy), Vector2(16 * _sx, 3 * _sy), Color("#5C3D11")
	)
	# Hay in wagon
	var hay := _make_circle_panel(Vector2(-12 * _sx, -28 * _sy), 16 * _sx, Color("#DAC060"))
	root.add_child(hay)
	var hay2 := _make_circle_panel(Vector2(2 * _sx, -26 * _sy), 14 * _sx, Color("#C8A840"))
	root.add_child(hay2)
	_ysort.add_child(root)


func _add_water_shimmer(pos: Vector2) -> void:
	var water_size := 32.0 * _sx
	var water_rect := ColorRect.new()
	water_rect.size = Vector2(water_size * 1.0, water_size * 0.7)
	water_rect.position = pos + Vector2(-water_size * 0.5, -water_size * 0.35)
	water_rect.color = Color("#2D9BC4")
	water_rect.z_index = -2
	var water_mat := ShaderMaterial.new()
	water_mat.shader = load("res://shaders/water_shimmer.gdshader")
	water_rect.material = water_mat
	water_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(water_rect)


func _add_mailbox(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	# Post
	_add_rect_child(
		root, Vector2(-2 * _sx, -28 * _sy), Vector2(4 * _sx, 28 * _sy), Color("#5C3D11")
	)
	# Mailbox body
	_add_rect_child(
		root, Vector2(-8 * _sx, -38 * _sy), Vector2(16 * _sx, 12 * _sy), Color("#4A7ABF")
	)
	# Mailbox lid (slightly lighter)
	_add_rect_child(
		root, Vector2(-9 * _sx, -40 * _sy), Vector2(18 * _sx, 4 * _sy), Color("#5B8BD0")
	)
	# Flag
	_add_rect_child(root, Vector2(8 * _sx, -38 * _sy), Vector2(2 * _sx, 10 * _sy), Color("#8B6914"))
	_add_rect_child(root, Vector2(10 * _sx, -38 * _sy), Vector2(6 * _sx, 4 * _sy), Color("#E03E3E"))
	_ysort.add_child(root)


## Helper to add a ColorRect as child of a node.
func _add_rect_child(parent: Node, pos: Vector2, sz: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = color
	parent.add_child(r)


# ═════════════════════════════════════════════════════════════════════════════
# BUILDINGS — scattered positions, all in _ysort
# ═════════════════════════════════════════════════════════════════════════════
func _spawn_buildings() -> void:
	for d in BUILDING_DATA:
		var bc: BuildingController = load("res://scripts/BuildingController.gd").new()
		bc.name = d["id"]
		_ysort.add_child(bc)
		bc.setup(d["id"], d["label"], d["color"], GameManager.is_unlocked(d["id"]), _sx, _sy)
		bc.position = Vector2(_vp.x * float(d["x"]), _vp.y * float(d["y"]))
		bc.building_tapped.connect(_on_building_tapped)
		_building_controllers[d["id"]] = bc


# ═════════════════════════════════════════════════════════════════════════════
# UI — CanvasLayer + VirtualJoystick
# ═════════════════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	canvas.layer = 10
	add_child(canvas)

	_joystick = load("res://scripts/VirtualJoystick.gd").new()
	_joystick.name = "VirtualJoystick"
	_joystick.size = _vp  # full screen for touch detection
	_joystick.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.add_child(_joystick)

	# ── Village Progress Indicator (top center) ──
	var progress_panel := PanelContainer.new()
	progress_panel.name = "ProgressPanel"
	var pp_style := StyleBoxFlat.new()
	pp_style.bg_color = Color(0.15, 0.10, 0.03, 0.75)
	pp_style.corner_radius_top_left = int(8 * _sx)
	pp_style.corner_radius_top_right = int(8 * _sx)
	pp_style.corner_radius_bottom_left = int(8 * _sx)
	pp_style.corner_radius_bottom_right = int(8 * _sx)
	pp_style.content_margin_left = 12.0 * _sx
	pp_style.content_margin_right = 12.0 * _sx
	pp_style.content_margin_top = 6.0 * _sy
	pp_style.content_margin_bottom = 6.0 * _sy
	pp_style.border_width_left = int(max(1, 2 * _sx))
	pp_style.border_width_right = int(max(1, 2 * _sx))
	pp_style.border_width_top = int(max(1, 2 * _sy))
	pp_style.border_width_bottom = int(max(1, 2 * _sy))
	pp_style.border_color = Color("#8B6914")
	progress_panel.add_theme_stylebox_override("panel", pp_style)
	progress_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Title
	var title_label := Label.new()
	title_label.text = "Village Restoration"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", int(18.0 * _sy))
	title_label.add_theme_color_override("font_color", Color("#E8C547"))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_label)

	# Progress bar container
	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(260 * _sx, 15 * _sy)
	bar_bg.color = Color(0.2, 0.15, 0.05, 0.6)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bar_fill := ColorRect.new()
	bar_fill.name = "ProgressFill"
	bar_fill.color = Color("#E8C547")
	var progress := GameManager.get_progress_percent() / 100.0
	bar_fill.size = Vector2(180 * _sx * progress, 10 * _sy)
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.add_child(bar_fill)

	vbox.add_child(bar_bg)

	# Count label
	var count_label := Label.new()
	count_label.name = "ProgressCount"
	var unlocked_count := 0
	for b in BUILDING_DATA:
		if GameManager.is_unlocked(b["id"]):
			unlocked_count += 1
	count_label.text = "%d / %d buildings restored" % [unlocked_count, BUILDING_DATA.size()]
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", int(15.0 * _sy))
	count_label.add_theme_color_override("font_color", Color("#DEB887"))
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(count_label)

	progress_panel.add_child(vbox)
	progress_panel.position = Vector2(_vp.x * 0.5 - 120 * _sx, 12 * _sy)
	canvas.add_child(progress_panel)

	# ── Profile Button (top-left, hex avatar frame) ──
	var player_name: String = GameManager.current_student.get("name", "?")
	var player_level: int = GameManager.current_student.get("reading_level", 1)
	_profile_btn = load("res://scripts/ui/ProfileButton.gd").new()
	_profile_btn.name = "ProfileBtn"
	_profile_btn.setup(_sx, _sy, player_name, player_level)
	_profile_btn.position = Vector2(24 * _sx, 20 * _sy)
	_profile_btn.z_index = 100
	_profile_btn.connect("tapped", _on_profile_btn_pressed)
	canvas.add_child(_profile_btn)

	_profile_panel = load("res://scenes/ProfilePanel.tscn").instantiate()
	_profile_panel.setup(_sx, _sy)
	canvas.add_child(_profile_panel)

	# ── Quest UI components ──
	_quest_prompt = load("res://scripts/quest/QuestPrompt.gd").new()
	_quest_prompt.name = "QuestPrompt"
	_quest_prompt.setup(_sx, _sy)
	_quest_prompt.start_quest_pressed.connect(_on_quest_prompt_start)
	canvas.add_child(_quest_prompt)

	_quest_overlay = load("res://scripts/quest/QuestOverlay.gd").new()
	_quest_overlay.name = "QuestOverlay"
	_quest_overlay.setup(_sx, _sy)
	canvas.add_child(_quest_overlay)

	_dialogue_panel = load("res://scripts/story/DialoguePanel.gd").new()
	_dialogue_panel.name = "DialoguePanel"
	_dialogue_panel.setup(_sx, _sy)
	canvas.add_child(_dialogue_panel)


func _on_profile_btn_pressed() -> void:
	if is_instance_valid(_profile_panel):
		_profile_panel.show_profile()


# ═════════════════════════════════════════════════════════════════════════════
# PLAYER — CharacterBody2D built in code, added to _ysort
# ═════════════════════════════════════════════════════════════════════════════
func _spawn_player() -> void:
	var player: CharacterBody2D = load("res://scripts/Player.gd").new()
	player.name = "Player"

	# ── Visual: pixel-art Grade 7 student (origin = feet at y=0) ──
	# Contact shadow oval
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(0.0, -4.0 * _sy, 28.0 * _sx, 9.0 * _sy, 14)
	shad.color = Color(0.0, 0.0, 0.0, 0.30)
	player.add_child(shad)

	# Student sprite
	var spr := Sprite2D.new()
	var gender: String = GameManager.current_student.get("character_gender", "male")
	var sprite_path := (
		"res://assets/sprites/character/player_female.png"
		if gender == "female"
		else "res://assets/sprites/character/player.png"
	)
	spr.texture = load(sprite_path)
	spr.name = "Sprite"
	var ref_w := 48.0 * _sx
	var ref_h := 72.0 * _sy
	var ts := spr.texture.get_size()
	spr.scale = Vector2(ref_w / ts.x, ref_h / ts.y)
	spr.position = Vector2(0.0, -ref_h * 0.5)  # bottom-anchor at y=0 (feet)
	player.add_child(spr)

	# ── Collision shape ──
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0 * minf(_sx, _sy)
	col.shape = shape
	col.position = Vector2(0.0, -16.0 * _sy)
	player.add_child(col)

	# ── Camera (child of player → auto-follows) ──
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(_vp.x)
	cam.limit_bottom = int(_vp.y)
	player.add_child(cam)

	# ── Joystick reference ──
	player.set_meta("joystick_ref", _joystick)

	# ── Add to scene + set start position (on horizontal road, center) ──
	_ysort.add_child(player)
	player.position = Vector2(_vp.x * 0.50, _vp.y * 0.80)



# ═════════════════════════════════════════════════════════════════════════════
# TOWN LIVENER
# ═════════════════════════════════════════════════════════════════════════════
func _build_town_livener() -> void:
	var script = load("res://scripts/TownLivener.gd")
	if script == null:
		push_warning("[Main] TownLivener.gd not found — skipping progressive town visuals.")
		return
	_town_livener = script.new()
	_town_livener.name = "TownLivener"
	_ysort.add_child(_town_livener)
	_town_livener.setup(_vp, _sx, _sy, _building_controllers)


# ═════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═════════════════════════════════════════════════════════════════════════════
func _connect_signals() -> void:
	GameManager.building_unlocked.connect(_on_building_unlocked)
	GameManager.all_buildings_unlocked.connect(_on_all_buildings_unlocked)
	QuestManager.quest_started.connect(func(_bid: String) -> void: _set_joystick_active(false))
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_abandoned.connect(func(_bid: String) -> void: _set_joystick_active(true))
	_quest_overlay.overlay_closed.connect(_on_overlay_closed)


func _on_building_tapped(controller: BuildingController) -> void:
	if controller.is_unlocked:
		return
	if QuestManager.is_quest_active():
		return

	var player := _ysort.get_node_or_null("Player")
	if player == null:
		return

	# Proximity check
	if not controller.is_player_nearby(player.position):
		_show_walk_closer_hint()
		return

	# Sequential check
	var result := QuestManager.can_start_quest(controller.building_id)
	if result.get("can_start", false):
		# ── Story: prologue (first-ever building tap) ──
		if StoryManager.should_show_prologue():
			var prologue := StoryManager.get_prologue()
			var branches := {"prologue_lore": StoryManager.get_prologue_lore()}
			_dialogue_panel.show_sequence(prologue, branches)
			await _dialogue_panel.dialogue_sequence_finished
			StoryManager.mark_prologue_seen()
			if not is_instance_valid(controller) or controller.is_unlocked:
				return
			if QuestManager.is_quest_active():
				return

		# ── Story: building intro (first visit to this building) ──
		if StoryManager.should_show_intro(controller.building_id):
			var intro := StoryManager.get_intro(controller.building_id)
			var lore_branches := {"lore_1": StoryManager.get_lore(controller.building_id, "lore_1")}
			_dialogue_panel.show_sequence(intro, lore_branches)
			await _dialogue_panel.dialogue_sequence_finished
			StoryManager.mark_intro_seen(controller.building_id)
			if not is_instance_valid(controller) or controller.is_unlocked:
				return
			if QuestManager.is_quest_active():
				return

		var quest_meta: Dictionary = QuestData.BUILDING_QUEST_MAP.get(controller.building_id, {})
		_quest_prompt.show_quest_prompt(
			controller.building_id,
			controller.building_label,
			quest_meta.get("topic", ""),
			controller.building_color,
			controller.position,
			player
		)
	else:
		var reason: String = result.get("reason", "")
		if reason == "wrong_sequence":
			_quest_prompt.show_sequence_message(
				result.get("next_label", "the previous building"), controller.position, player
			)


func _set_joystick_active(active: bool) -> void:
	if is_instance_valid(_joystick):
		_joystick.visible = active
		_joystick.set_process_input(active)
		_joystick.set_process_unhandled_input(active)


func _on_quest_prompt_start(building_id: String, skip_tutorial: bool = false) -> void:
	QuestManager.start_quest(building_id, skip_tutorial)


func _on_quest_completed(building_id: String, passed: bool, _score: int) -> void:
	if passed and _building_controllers.has(building_id):
		_update_progress_bar()
	# Joystick re-enabled by _on_overlay_closed (on pass) or immediately (on fail)
	if not passed:
		_set_joystick_active(true)


func _on_overlay_closed(building_id: String, _passed: bool) -> void:
	if not _building_controllers.has(building_id):
		_set_joystick_active(true)
		return
	var bc: BuildingController = _building_controllers[building_id]
	var player := _ysort.get_node_or_null("Player")
	var camera: Camera2D = null
	if player:
		for child in player.get_children():
			if child is Camera2D:
				camera = child
				break
	if player and camera and is_instance_valid(_town_livener):
		_town_livener.cutscene_active = true
		var cutscene: Node = load("res://scripts/UnlockCutscene.gd").new()
		add_child(cutscene)
		cutscene.setup(_vp, _sx, _sy, bc, camera, player, _town_livener)
		cutscene.cutscene_finished.connect(func() -> void:
			_town_livener.cutscene_active = false
			_set_joystick_active(true)
		)
		cutscene.play()
	else:
		# Fallback: no camera/player
		bc.unlock()
		_update_progress_bar()
		_set_joystick_active(true)


func _on_building_unlocked(building_id: String) -> void:
	print(
		"[Main] Unlocked: ",
		building_id,
		"  |  Progress: %.0f%%" % GameManager.get_progress_percent()
	)
	# Sync the BuildingController's local flag so tapping it doesn't silently no-op.
	if _building_controllers.has(building_id):
		var bc: BuildingController = _building_controllers[building_id]
		if not bc.is_unlocked:
			bc.is_unlocked = true
	# SFX only when no cutscene is active (cutscene handles its own SFX)
	if not (is_instance_valid(_town_livener) and _town_livener.cutscene_active):
		AudioManager.play_sfx("building_unlock")
	_update_progress_bar()


func _on_all_buildings_unlocked() -> void:
	print("[Main] Village fully restored!")
	# Wait for any active unlock cutscene to finish first
	var active_cutscene := get_node_or_null("UnlockCutscene")
	if active_cutscene and active_cutscene.has_signal("cutscene_finished"):
		await active_cutscene.cutscene_finished
	# Wait for TownLivener's celebration finale before the story ending sequence.
	if is_instance_valid(_town_livener) and _town_livener.has_signal("celebration_finished"):
		await _town_livener.celebration_finished
	if StoryManager.should_show_ending():
		_play_ending_sequence()


func _play_ending_sequence() -> void:
	# ── Resolve camera + player references ──
	var player := _ysort.get_node_or_null("Player")
	var camera: Camera2D = null
	if player:
		for child in player.get_children():
			if child is Camera2D:
				camera = child
				break
	var original_cam_offset := camera.offset if camera else Vector2.ZERO
	var original_cam_smooth := camera.position_smoothing_speed if camera else 6.0
	var montage_skipped := false

	# ── 1. Dim the village slightly (keep it visible for camera tour) ──
	var tw := create_tween()
	(
		tw
		. tween_property(_ysort, "modulate", Color(0.5, 0.5, 0.5, 1.0), 1.0)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN_OUT)
	)
	await tw.finished

	# ── 2. Create banner overlay CanvasLayer (floating banner, NOT full-screen blocker) ──
	var banner_canvas := CanvasLayer.new()
	banner_canvas.name = "EndingBanner"
	banner_canvas.layer = 16
	add_child(banner_canvas)

	# Skip button (appears after building 2)
	var skip_btn := Button.new()
	skip_btn.text = "Skip >>"
	skip_btn.flat = true
	skip_btn.add_theme_font_size_override("font_size", int(16 * _sy))
	skip_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	skip_btn.size = Vector2(100 * _sx, 40 * _sy)
	skip_btn.position = Vector2(_vp.x * 0.82, _vp.y * 0.90)
	skip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	banner_canvas.add_child(skip_btn)
	skip_btn.modulate.a = 0.0
	skip_btn.pressed.connect(func() -> void: montage_skipped = true)

	# ── 3. Cinematic camera tour — pan to each building ──
	var montage_data := StoryManager.get_ending_montage()
	if camera:
		camera.position_smoothing_speed = 20.0

	var building_index := 0
	for entry in montage_data:
		if montage_skipped:
			break

		var building_id: String = entry.get("building", "")
		var building_label: String = entry.get("label", "")
		var keeper_line: String = entry.get("line", "")
		var building_color: Color = Color(entry.get("color", "#FFFFFF"))

		var bc: BuildingController = _building_controllers.get(building_id)
		if not is_instance_valid(bc):
			building_index += 1
			continue

		# Show skip button after building 2
		if building_index == 2 and is_instance_valid(skip_btn):
			UIAnimations.fade_in_up(self, skip_btn)

		# ── Pan camera to this building ──
		AudioManager.play_sfx("stage_advance")
		if camera and player:
			var building_world := bc.get_building_center_world_pos()
			var target_offset: Vector2 = building_world - (player as Node2D).global_position
			# Clamp within camera limits
			var half_vp := _vp * 0.5
			var min_pos := Vector2(camera.limit_left, camera.limit_top) + half_vp
			var max_pos := Vector2(camera.limit_right, camera.limit_bottom) - half_vp
			var final_pos: Vector2 = ((player as Node2D).global_position + target_offset).clamp(min_pos, max_pos)
			target_offset = final_pos - (player as Node2D).global_position

			var cam_tw := create_tween()
			cam_tw.tween_property(camera, "offset", target_offset, 1.0).set_trans(
				Tween.TRANS_CUBIC
			).set_ease(Tween.EASE_IN_OUT)
			await cam_tw.finished

		if montage_skipped:
			break

		# ── Building glow pulse ──
		var sprite := bc.get_building_sprite()
		if is_instance_valid(sprite) and sprite.material is ShaderMaterial:
			var mat := sprite.material as ShaderMaterial
			var glow_tw := create_tween()
			glow_tw.tween_method(
				func(v: float) -> void:
					if is_instance_valid(mat):
						mat.set_shader_parameter("glow_amount", v),
				0.0, 0.4, 1.2
			)
			glow_tw.tween_method(
				func(v: float) -> void:
					if is_instance_valid(mat):
						mat.set_shader_parameter("glow_amount", v),
				0.4, 0.0, 1.3
			)

		# ── NPC cheering ──
		if is_instance_valid(_town_livener):
			_town_livener.cheer_npcs_near(bc.get_building_center_world_pos(), 150.0 * _sx)

		# ── Show floating banner at bottom of screen ──
		var banner_bg := ColorRect.new()
		banner_bg.color = Color(0.04, 0.08, 0.15, 0.80)
		banner_bg.size = Vector2(_vp.x, _vp.y * 0.16)
		banner_bg.position = Vector2(0, _vp.y * 0.84)
		banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner_canvas.add_child(banner_bg)

		# Building name
		var name_label := Label.new()
		name_label.text = building_label
		name_label.add_theme_font_size_override("font_size", int(33 * _sy))
		name_label.add_theme_color_override("font_color", StyleFactory.GOLD)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.size = Vector2(_vp.x, 40 * _sy)
		name_label.position = Vector2(0, _vp.y * 0.845)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner_canvas.add_child(name_label)

		# Accent bar
		var accent_bar := ColorRect.new()
		accent_bar.color = building_color
		accent_bar.size = Vector2(160 * _sx, 4 * _sy)
		accent_bar.position = Vector2((_vp.x - 160 * _sx) * 0.5, _vp.y * 0.885)
		accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner_canvas.add_child(accent_bar)

		# Keeper quote
		var line_label := Label.new()
		line_label.text = keeper_line
		line_label.add_theme_font_size_override("font_size", int(22 * _sy))
		line_label.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
		line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line_label.size = Vector2(_vp.x * 0.8, 40 * _sy)
		line_label.position = Vector2(_vp.x * 0.1, _vp.y * 0.90)
		line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner_canvas.add_child(line_label)

		# Animate banner in
		UIAnimations.fade_in_up(self, banner_bg, 0.0)
		UIAnimations.fade_in_up(self, name_label, 0.1)
		UIAnimations.fade_in_up(self, accent_bar, 0.2)
		UIAnimations.fade_in_up(self, line_label, 0.3)

		# Hold on this building
		await get_tree().create_timer(3.0).timeout

		if montage_skipped:
			# Clean up banner elements before breaking
			for node in [banner_bg, name_label, accent_bar, line_label]:
				if is_instance_valid(node):
					node.queue_free()
			break

		# Fade banner out
		var fade_tw := create_tween().set_parallel(true)
		for node in [banner_bg, name_label, accent_bar, line_label]:
			fade_tw.tween_property(node, "modulate:a", 0.0, 0.4)
		await fade_tw.finished
		for node in [banner_bg, name_label, accent_bar, line_label]:
			if is_instance_valid(node):
				node.queue_free()

		await get_tree().create_timer(0.3).timeout
		building_index += 1

	# ── 4. Pan camera back to player ──
	if camera:
		var cam_back := create_tween()
		cam_back.tween_property(camera, "offset", Vector2.ZERO, 0.8).set_trans(
			Tween.TRANS_CUBIC
		).set_ease(Tween.EASE_IN_OUT)
		await cam_back.finished
		camera.position_smoothing_speed = original_cam_smooth

	# Remove skip button
	if is_instance_valid(skip_btn):
		skip_btn.queue_free()

	# ── 5. Restore village brightness ──
	var restore_dim := create_tween()
	(
		restore_dim
		. tween_property(_ysort, "modulate", Color.WHITE, 0.8)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	await restore_dim.finished

	# ── 6. Lumi farewell dialogue ──
	var farewell := StoryManager.get_ending_farewell()
	var farewell_branches := {"farewell_lore": StoryManager.get_farewell_lore()}
	_dialogue_panel.show_sequence(farewell, farewell_branches)
	await _dialogue_panel.dialogue_sequence_finished

	# ── 7. Cinematic title card ──
	var ending_canvas := CanvasLayer.new()
	ending_canvas.name = "EndingOverlay"
	ending_canvas.layer = 20
	add_child(ending_canvas)

	# Dark overlay background with animated shader
	var title_bg := ColorRect.new()
	title_bg.color = Color(StyleFactory.BG_DEEP.r, StyleFactory.BG_DEEP.g, StyleFactory.BG_DEEP.b, 0.92)
	title_bg.anchor_right = 1.0
	title_bg.anchor_bottom = 1.0
	title_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	ending_canvas.add_child(title_bg)
	title_bg.modulate.a = 0.0

	# Apply animated background shader if available
	var anim_bg_path := "res://assets/shaders/animated_background.gdshader"
	if ResourceLoader.exists(anim_bg_path):
		var bg_shader := ShaderMaterial.new()
		bg_shader.shader = load(anim_bg_path)
		bg_shader.set_shader_parameter("color_top", Color(0.02, 0.04, 0.10, 1.0))
		bg_shader.set_shader_parameter("color_mid", Color(0.04, 0.06, 0.14, 1.0))
		bg_shader.set_shader_parameter("color_bottom", Color(0.02, 0.05, 0.08, 1.0))
		bg_shader.set_shader_parameter("wave_speed", 0.02)
		bg_shader.set_shader_parameter("wave_amplitude", 0.04)
		title_bg.material = bg_shader

	# Bokeh particles on title card
	var bokeh_path := "res://assets/shaders/bokeh_particles.gdshader"
	if ResourceLoader.exists(bokeh_path):
		var bokeh_rect := ColorRect.new()
		bokeh_rect.anchor_right = 1.0
		bokeh_rect.anchor_bottom = 1.0
		bokeh_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bokeh_mat := ShaderMaterial.new()
		bokeh_mat.shader = load(bokeh_path)
		bokeh_mat.set_shader_parameter("particle_count", 10.0)
		bokeh_mat.set_shader_parameter("particle_size", 0.010)
		bokeh_mat.set_shader_parameter("speed", 0.015)
		bokeh_mat.set_shader_parameter("particle_color", Color(0.886, 0.725, 0.290, 0.08))
		bokeh_rect.material = bokeh_mat
		ending_canvas.add_child(bokeh_rect)

	# Fade in title background
	var tbg_tw := create_tween()
	tbg_tw.tween_property(title_bg, "modulate:a", 1.0, 0.6)
	await tbg_tw.finished

	# Gold accent line above title
	var accent_top := ColorRect.new()
	accent_top.color = StyleFactory.GOLD
	accent_top.size = Vector2(120 * _sx, 3 * _sy)
	accent_top.position = Vector2((_vp.x - 120 * _sx) * 0.5, _vp.y * 0.34)
	accent_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_canvas.add_child(accent_top)
	UIAnimations.expand_from_center(self, accent_top, 120 * _sx, 0.6)

	await get_tree().create_timer(0.3).timeout

	# Title text with typewriter reveal
	UIAnimations.flash_screen_on_layer(ending_canvas, _vp, Color(0.886, 0.725, 0.290, 0.08), 0.4)

	var title_rtl := RichTextLabel.new()
	title_rtl.text = "The End... for now."
	title_rtl.add_theme_font_size_override("normal_font_size", int(56 * _sy))
	title_rtl.add_theme_color_override("default_color", StyleFactory.GOLD)
	title_rtl.fit_content = true
	title_rtl.bbcode_enabled = false
	title_rtl.scroll_active = false
	title_rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_rtl.size = Vector2(_vp.x * 0.8, 80 * _sy)
	title_rtl.position = Vector2(_vp.x * 0.1, _vp.y * 0.37)
	title_rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Load Nunito font if available
	var nunito_path := "res://assets/fonts/Nunito-Variable.ttf"
	if ResourceLoader.exists(nunito_path):
		var nunito_font = load(nunito_path)
		title_rtl.add_theme_font_override("normal_font", nunito_font)
	ending_canvas.add_child(title_rtl)

	await UIAnimations.typewriter_reveal(self, title_rtl, 1.5)
	AudioManager.play_sfx("building_unlock")

	# Gold accent line below title
	var accent_bottom := ColorRect.new()
	accent_bottom.color = StyleFactory.GOLD
	accent_bottom.size = Vector2(120 * _sx, 3 * _sy)
	accent_bottom.position = Vector2((_vp.x - 120 * _sx) * 0.5, _vp.y * 0.45)
	accent_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_canvas.add_child(accent_bottom)
	UIAnimations.expand_from_center(self, accent_bottom, 120 * _sx, 0.6)

	await get_tree().create_timer(0.8).timeout

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Your reading journey continues..."
	subtitle.add_theme_font_size_override("font_size", int(23 * _sy))
	subtitle.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.anchor_left = 0.1
	subtitle.anchor_right = 0.9
	subtitle.anchor_top = 0.50
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_canvas.add_child(subtitle)
	UIAnimations.fade_in_up(self, subtitle, 0.0)

	await get_tree().create_timer(3.0).timeout

	# ── 8. Fade out and return to village ──
	for child in ending_canvas.get_children():
		if child is Control:
			var ftw := create_tween()
			ftw.tween_property(child, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(
				Tween.EASE_IN
			)

	await get_tree().create_timer(1.7).timeout
	ending_canvas.queue_free()
	if is_instance_valid(banner_canvas):
		banner_canvas.queue_free()

	AudioManager.play_sfx("building_unlock")
	StoryManager.mark_ending_seen()


func _update_progress_bar() -> void:
	var canvas := get_node_or_null("UI")
	if canvas == null:
		return
	var progress_panel := canvas.get_node_or_null("ProgressPanel")
	if progress_panel == null:
		return
	var fill := progress_panel.get_node_or_null("VBoxContainer/ColorRect/ProgressFill")
	if fill == null:
		# Try finding by name recursively
		fill = _find_node_by_name(progress_panel, "ProgressFill")
	if is_instance_valid(fill):
		var progress := GameManager.get_progress_percent() / 100.0
		var tw := create_tween()
		(
			tw
			. tween_property(fill, "size:x", 180.0 * _sx * progress, 0.5)
			. set_trans(Tween.TRANS_CUBIC)
			. set_ease(Tween.EASE_OUT)
		)
	var count := _find_node_by_name(progress_panel, "ProgressCount")
	if is_instance_valid(count) and count is Label:
		var unlocked_count := GameManager.unlocked_buildings.size()
		(count as Label).text = (
			"%d / %d buildings restored" % [unlocked_count, BUILDING_DATA.size()]
		)


func _find_node_by_name(parent: Node, node_name: String) -> Node:
	for child in parent.get_children():
		if child.name == node_name:
			return child
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _show_walk_closer_hint() -> void:
	var canvas := get_node_or_null("UI")
	if canvas == null:
		return
	var hint := Label.new()
	hint.text = "Walk closer!"
	hint.add_theme_font_size_override("font_size", int(27 * _sy))
	hint.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(_vp.x * 0.5 - 80 * _sx, _vp.y * 0.5 - 60 * _sy)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hint)
	var tw := create_tween()
	(
		tw
		. tween_property(hint, "modulate:a", 0.0, 1.5)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
		. set_delay(0.5)
	)
	tw.tween_callback(hint.queue_free)


# ═════════════════════════════════════════════════════════════════════════════
# QUEST TRACKER + TUTORIAL
# ═════════════════════════════════════════════════════════════════════════════


func _build_quest_tracker() -> void:
	var canvas := get_node_or_null("UI")
	if canvas == null:
		return
	var player := _ysort.get_node_or_null("Player")
	_quest_tracker = load("res://scripts/ui/QuestTrackerPanel.gd").new()
	_quest_tracker.name = "QuestTracker"
	_quest_tracker.setup(_sx, _sy, player)
	canvas.add_child(_quest_tracker)


func _check_tutorial() -> void:
	if GameManager.current_student.is_empty():
		return
	if not ApiClient.is_authenticated:
		return
	var no_buildings: bool = GameManager.unlocked_buildings.size() == 0
	var tutorial_done: bool = GameManager.current_student.get("tutorial_done", 0) == 1
	# If they have buildings unlocked but tutorial not marked done, just mark it
	# server-side. We don't block the player on this — it's a reconciliation
	# fix-up, not gameplay.
	if not tutorial_done and GameManager.unlocked_buildings.size() > 0:
		GameManager.current_student["tutorial_done"] = 1
		NetworkGate.run(
			func(cb: Callable) -> void: ApiClient.patch_me({"tutorialDone": true}, cb),
			func(_data: Dictionary) -> void: pass
		)
		return
	if no_buildings and not tutorial_done:
		_start_tutorial()


func _start_tutorial() -> void:
	var canvas := get_node_or_null("UI")
	if canvas == null:
		return
	var player := _ysort.get_node_or_null("Player")
	if player == null:
		return
	var town_hall_ctrl: Node2D = _building_controllers.get("town_hall")
	if town_hall_ctrl == null:
		return
	_tutorial_overlay = load("res://scripts/ui/TutorialOverlay.gd").new()
	_tutorial_overlay.name = "TutorialOverlay"
	_tutorial_overlay.setup(_sx, _sy, player, town_hall_ctrl, _joystick, _quest_tracker)
	_tutorial_overlay.tutorial_completed.connect(func() -> void: _tutorial_overlay = null)
	canvas.add_child(_tutorial_overlay)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if QuestManager.is_quest_active():
			QuestManager.abandon_quest()
		else:
			print("[Main] Back button — ignored in Phase 0.")


# ═════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════════════════════════


## Add a ColorRect directly to a node (not ysort).
func _add_rect_to(parent: Node, pos: Vector2, size: Vector2, color: Color, z: int) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.z_index = z
	parent.add_child(r)
	return r


## Add a textured path ColorRect with dirt shader.
func _add_path_rect(
	pos: Vector2, sz: Vector2, color: Color, shader: Shader, dark_hex: String, light_hex: String
) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = color
	r.z_index = -9
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("base_color", Color(dark_hex))
	mat.set_shader_parameter("dark_speck", Color(dark_hex).darkened(0.25))
	mat.set_shader_parameter("light_speck", Color(light_hex))
	r.material = mat
	add_child(r)


## Create a circle-shaped Panel (StyleBoxFlat corner_radius = half of diameter).
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


## Build an oval PackedVector2Array centered at (cx, cy).
func _oval_pts(cx: float, cy: float, rx: float, ry: float, steps: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * i / float(steps)
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return pts


## 7-vertex blade polygon for grass clusters. Thin, tapered blade shape.
func _blade_pts(cx: float, cy: float, rot_deg: float, sf: float) -> PackedVector2Array:
	var base := [
		Vector2(0, 0),
		Vector2(-2.5, -3),
		Vector2(-1.8, -8),
		Vector2(0, -14),
		Vector2(1.8, -8),
		Vector2(2.5, -3),
		Vector2(0, 0)
	]
	var pts := PackedVector2Array()
	var rad := deg_to_rad(rot_deg)
	var cr := cos(rad)
	var sr := sin(rad)
	for p in base:
		var bx: float = p.x * sf
		var by: float = p.y * sf
		pts.append(Vector2(bx * cr - by * sr + cx, bx * sr + by * cr + cy))
	return pts


## Grass fringe tabs along a vertical path edge.
## inward=true → tab points in +x (right, into path from left edge).
func _path_fringe_v(
	edge_x: float, y_start: float, y_len: float, inward: bool, color: Color
) -> void:
	var y := y_start + randf_range(0.0, 20.0) * _sy
	var end_y := y_start + y_len
	while y < end_y:
		var depth := randf_range(4.0, 9.0) * _sx
		var half := randf_range(5.0, 10.0) * _sy
		var dx := depth if inward else -depth
		var tab := Polygon2D.new()
		tab.polygon = PackedVector2Array(
			[
				Vector2(edge_x, y - half),
				Vector2(edge_x + dx, y),
				Vector2(edge_x, y + half),
			]
		)
		var tc := color
		tc.a = randf_range(0.50, 0.75)
		tab.color = tc
		tab.z_index = -9
		add_child(tab)
		y += randf_range(16.0, 26.0) * _sy


## Grass fringe tabs along a horizontal path edge.
## inward=true → tab points in +y (down, into path from top edge).
func _path_fringe_h(
	edge_y: float, x_start: float, x_len: float, inward: bool, color: Color
) -> void:
	var x := x_start + randf_range(0.0, 20.0) * _sx
	var end_x := x_start + x_len
	while x < end_x:
		var depth := randf_range(4.0, 9.0) * _sy
		var half := randf_range(5.0, 10.0) * _sx
		var dy := depth if inward else -depth
		var tab := Polygon2D.new()
		tab.polygon = PackedVector2Array(
			[
				Vector2(x - half, edge_y),
				Vector2(x, edge_y + dy),
				Vector2(x + half, edge_y),
			]
		)
		var tc := color
		tc.a = randf_range(0.50, 0.75)
		tab.color = tc
		tab.z_index = -9
		add_child(tab)
		x += randf_range(16.0, 26.0) * _sx


## Warm vignette — darkens corners to draw the eye to the village center.
func _build_vignette() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 8  # above world, below UI (UI=10)
	add_child(canvas)
	var vign := ColorRect.new()
	vign.size = _vp
	vign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(vign)
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
void fragment() {
	float d = length(UV - vec2(0.5));
	float v = smoothstep(0.35, 0.85, d);
	COLOR = vec4(0.08, 0.06, 0.02, v * 0.45);
}"""
	mat.shader = shader
	vign.material = mat
