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

var cutscene_active: bool = false

# ─── Scale / viewport ────────────────────────────────────────────────────────
var _vp: Vector2
var _sx: float
var _sy: float
var _building_controllers: Dictionary  # id → BuildingController
var _ysort_ref: Node2D  # parent YSort layer — NPCs added here for correct depth

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
	# Grab parent YSort so NPCs can be added as direct children for proper depth
	_ysort_ref = get_parent() as Node2D

	# Connect to live unlock signals
	if not GameManager.building_unlocked.is_connected(_on_building_unlocked):
		GameManager.building_unlocked.connect(_on_building_unlocked)
	if not GameManager.all_buildings_unlocked.is_connected(_on_all_buildings_unlocked):
		GameManager.all_buildings_unlocked.connect(_on_all_buildings_unlocked)

	# Respect music toggle — mute/unmute ambient layers when music setting changes
	if not AudioManager.music_toggled.is_connected(_on_music_toggled):
		AudioManager.music_toggled.connect(_on_music_toggled)
	# Duck ambient layers during transient mutes (e.g. mic recording)
	if not AudioManager.music_ducked_changed.is_connected(_on_music_ducked_changed):
		AudioManager.music_ducked_changed.connect(_on_music_ducked_changed)

	# Idempotent catch-up: apply all tiers already unlocked (no animation)
	var already_unlocked := GameManager.unlocked_buildings.size()
	if already_unlocked > 0:
		_apply_up_to(already_unlocked, false)


func _safe_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


# ─────────────────────────────────────────────────────────────────────────────
func _on_building_unlocked(_building_id: String) -> void:
	if cutscene_active:
		return  # UnlockCutscene calls apply_tier_animated directly
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


## Called by UnlockCutscene to apply a tier with animation and get highlights.
func apply_tier_animated(tier: int) -> Array[Dictionary]:
	var highlights: Array[Dictionary] = []
	var root := Node2D.new()
	root.name = "Tier%d" % tier
	add_child(root)

	match tier:
		1: highlights = _build_tier_1(root)
		2: highlights = _build_tier_2(root)
		3: highlights = _build_tier_3(root)
		4: highlights = _build_tier_4(root)
		5: highlights = _build_tier_5(root)
		6: highlights = _build_tier_6(root)
		7: highlights = _build_tier_7(root)
		8: highlights = _build_tier_8(root)

	# Ambient audio layer
	if AMBIENT_LAYERS.has(tier):
		_start_ambient(tier, true)

	# Fade-in animation
	if is_instance_valid(root):
		root.modulate.a = 0.0
		var tw := root.create_tween()
		tw.tween_property(root, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(
			Tween.EASE_OUT
		)

	_current_tier = max(_current_tier, tier)
	return highlights


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
		8: _build_tier_8(root)

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
# TIER 1 — Town Hall: Government Arrives
# Flowers + birds + flagpole + cobblestone plaza + notice board + town crier +
# golden glow particles + hedge border
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_1(root: Node2D) -> Array[Dictionary]:
	# Flower clusters in 5 different areas (expanded from 3)
	_add_flowers(root, Vector2(_vp.x * 0.30, _vp.y * 0.70))
	_add_flowers(root, Vector2(_vp.x * 0.72, _vp.y * 0.65))
	_add_flowers(root, Vector2(_vp.x * 0.55, _vp.y * 0.78))
	_add_flowers(root, Vector2(_vp.x * 0.42, _vp.y * 0.72))
	_add_flowers(root, Vector2(_vp.x * 0.65, _vp.y * 0.75))

	# ── NEW: Waving flagpole near town hall ──
	var th_pos := Vector2(_vp.x * 0.50, _vp.y * 0.34)
	_add_flagpole(root, th_pos + Vector2(70 * _sx, 20 * _sy), Color("#E8C547"))

	# ── NEW: Cobblestone plaza in front of town hall ──
	_add_cobblestone_plaza(root, th_pos + Vector2(0, 70 * _sy))

	# ── NEW: Notice board ──
	_add_notice_board(root, th_pos + Vector2(-65 * _sx, 30 * _sy))

	# ── Town crier NPC (front) + villager (right) ──
	var crier_pos := th_pos + Vector2(0, 95 * _sy)
	_add_idle_npc(root, crier_pos, Color(1.0, 0.96, 0.75))
	_add_idle_npc(root, th_pos + Vector2(85 * _sx, 70 * _sy), Color(1, 1, 1), true)

	# ── NEW: Hedge border along town hall entrance path ──
	for i in range(6):
		var hx := th_pos.x - 40 * _sx + i * 16 * _sx
		var hy := th_pos.y + 55 * _sy
		root.add_child(_make_circle_panel(Vector2(hx - 6 * _sx, hy - 6 * _sy), 12 * _sx, Color("#2D6E1E")))

	return [
		{"pos": th_pos + Vector2(70 * _sx, 20 * _sy), "label": "A new flag flies!"},
		{"pos": crier_pos, "label": "The first villager!"},
	]


# ═════════════════════════════════════════════════════════════════════════════
# TIER 2 — School: Children Come
# Child NPCs + butterflies + swing set + seesaw + chalk drawings + hopscotch +
# rainbow bunting + book cart + bush clusters
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_2(root: Node2D) -> Array[Dictionary]:
	# Additional flower clusters
	_add_flowers(root, Vector2(_vp.x * 0.20, _vp.y * 0.52))
	_add_flowers(root, Vector2(_vp.x * 0.10, _vp.y * 0.64))

	# School position
	var school_pos := Vector2(_vp.x * 0.15, _vp.y * 0.44)

	# 2 child NPCs — left and right of school
	_add_idle_npc(root, school_pos + Vector2(-70 * _sx, 70 * _sy), Color(0.82, 0.88, 1.0))
	_add_idle_npc(root, school_pos + Vector2(70 * _sx, 65 * _sy), Color(1, 1, 1), true)

	# ── NEW: Swing set ──
	var swing_pos := school_pos + Vector2(100 * _sx, 45 * _sy)
	_add_swing_set(root, swing_pos)

	# ── NEW: Seesaw ──
	var seesaw_pos := school_pos + Vector2(120 * _sx, 60 * _sy)
	_add_seesaw(root, seesaw_pos)

	# ── NEW: Chalk drawings on ground ──
	_add_chalk_drawings(root, school_pos + Vector2(10 * _sx, 60 * _sy))

	# ── NEW: Hopscotch pattern ──
	_add_hopscotch(root, school_pos + Vector2(-30 * _sx, 70 * _sy))

	# ── NEW: Rainbow bunting between posts ──
	_add_bunting(root, school_pos + Vector2(-30 * _sx, -40 * _sy), school_pos + Vector2(90 * _sx, -40 * _sy))

	# ── NEW: Book cart near school entrance ──
	_add_book_cart(root, school_pos + Vector2(-55 * _sx, 25 * _sy))

	# ── NEW: Bush clusters ──
	for i in range(3):
		var bx := school_pos.x + (i - 1) * 50 * _sx + randf_range(-10, 10) * _sx
		var by := school_pos.y + 70 * _sy + randf_range(-5, 5) * _sy
		var bush_r := randf_range(8, 14) * _sx
		root.add_child(_make_circle_panel(Vector2(bx - bush_r, by - bush_r), bush_r * 2, Color("#2D8B20").darkened(randf_range(0, 0.2))))

	return [
		{"pos": swing_pos, "label": "A playground appears!"},
		{"pos": school_pos + Vector2(30 * _sx, 40 * _sy), "label": "Children have arrived!"},
	]


# ═════════════════════════════════════════════════════════════════════════════
# TIER 3 — Inn: Travelers Arrive
# Lamp glows + barrels + wagon + hanging sign + horse +
# crates + traveler NPC + campfire + outdoor table + hitching post + more lamps
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_3(root: Node2D) -> Array[Dictionary]:
	# Inn position
	var inn_pos := Vector2(_vp.x * 0.34, _vp.y * 0.50)

	# Barrel cluster near inn
	_add_barrel_cluster(root, Vector2(_vp.x * 0.26, _vp.y * 0.58))

	# Wagon near market area
	var wagon_pos := Vector2(_vp.x * 0.22, _vp.y * 0.74)
	_add_small_wagon(root, wagon_pos)

	# ── NEW: Hanging inn sign ──
	_add_hanging_sign(root, inn_pos + Vector2(-40 * _sx, -50 * _sy), Color("#C07B3A"))

	# ── NEW: Horse silhouette near wagon ──
	var horse_pos := wagon_pos + Vector2(-35 * _sx, -5 * _sy)
	_add_horse(root, horse_pos)

	# ── NEW: Stacked crates ──
	_add_crate_stack(root, Vector2(_vp.x * 0.28, _vp.y * 0.56))

	# ── Traveler NPC (front-right of inn) ──
	var traveler_pos := inn_pos + Vector2(65 * _sx, 70 * _sy)
	_add_idle_npc(root, traveler_pos, Color(1.0, 0.82, 0.78))

	# ── NEW: Outdoor dining table ──
	_add_outdoor_table(root, inn_pos + Vector2(30 * _sx, 50 * _sy))

	# ── NEW: Hitching post ──
	_add_hitching_post(root, wagon_pos + Vector2(35 * _sx, -10 * _sy))

	return [
		{"pos": horse_pos, "label": "Travelers have arrived!"},
		{"pos": traveler_pos, "label": "A weary traveler rests."},
	]


# ═════════════════════════════════════════════════════════════════════════════
# TIER 4 — Chapel: Spiritual Peace
# Bell + benches + walking NPCs + gardens + stone pathway + stained glass glow +
# praying NPC + doves + rose garden + candle glow + memorial stones + vines + more NPCs
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_4(root: Node2D) -> Array[Dictionary]:
	# Chapel bell one-shot SFX (only on live unlock, not catch-up)
	AudioManager.play_sfx("chapel_bell")

	var chapel_pos := Vector2(_vp.x * 0.64, _vp.y * 0.50)

	# Benches
	_add_bench(root, Vector2(_vp.x * 0.40, _vp.y * 0.63))
	_add_bench(root, Vector2(_vp.x * 0.68, _vp.y * 0.59))

	# Walking NPCs
	var wa := Vector2(_vp.x * 0.48, _vp.y * 0.57)
	var wb := Vector2(_vp.x * 0.60, _vp.y * 0.57)
	var npc_a := _add_walking_npc(root, wa, Color(0.82, 0.88, 1.0))
	var npc_b := _add_walking_npc(root, wb, Color(1, 1, 1), true)
	_start_npc_walk(npc_a, wa, wb, 5.0)
	_start_npc_walk(npc_b, wb, wa, 6.0)

	# Garden patches
	_add_garden(root, Vector2(_vp.x * 0.64, _vp.y * 0.57))
	_add_garden(root, Vector2(_vp.x * 0.52, _vp.y * 0.40))

	# ── NEW: Stone pathway to chapel ──
	var path_start := Vector2(_vp.x * 0.55, _vp.y * 0.55)
	_add_stepping_stones(root, path_start, chapel_pos + Vector2(0, 30 * _sy), 6)

	# ── 2 sprite NPCs around chapel ──
	var pray_pos := chapel_pos + Vector2(0, 85 * _sy)
	_add_idle_npc(root, pray_pos, Color(1, 1, 1), true)
	_add_idle_npc(root, chapel_pos + Vector2(-70 * _sx, 65 * _sy), Color(0.82, 0.88, 1.0))

	# ── NEW: Rose garden ──
	_add_rose_garden(root, chapel_pos + Vector2(-50 * _sx, 35 * _sy))

	# ── NEW: Memorial stones ──
	for i in range(3):
		_add_memorial_stone(root, chapel_pos + Vector2((40 + i * 18) * _sx, 40 * _sy))

	# ── NEW: Decorative vine ──
	_add_vine(root, chapel_pos + Vector2(-35 * _sx, -20 * _sy), 8)

	return [
		{"pos": chapel_pos + Vector2(-50 * _sx, 35 * _sy), "label": "A beautiful rose garden."},
		{"pos": pray_pos, "label": "A moment of peace."},
	]


# ═════════════════════════════════════════════════════════════════════════════
# TIER 5 — Library: Culture Blossoms
# Pennants + reading NPC + lamps + outdoor bookshelf + string lights +
# storytelling circle + strolling book NPC + potted plants + sleeping cat + scrolls
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_5(root: Node2D) -> Array[Dictionary]:
	var lib_pos := Vector2(_vp.x * 0.80, _vp.y * 0.40)

	# Pennant flags on poles (5 total, up from 3)
	_add_pennant(root, Vector2(_vp.x * 0.50, _vp.y * 0.25), Color("#E8C547"))
	_add_pennant(root, Vector2(_vp.x * 0.15, _vp.y * 0.35), Color("#5B9BD5"))
	_add_pennant(root, Vector2(_vp.x * 0.82, _vp.y * 0.32), Color("#8B5CF6"))
	_add_pennant(root, Vector2(_vp.x * 0.35, _vp.y * 0.28), Color("#EB6B1F"))
	_add_pennant(root, Vector2(_vp.x * 0.68, _vp.y * 0.30), Color("#3E8948"))

	# ── Library NPC (front-right) ──
	_add_idle_npc(root, lib_pos + Vector2(60 * _sx, 80 * _sy), Color(1, 1, 1))

	# ── NEW: Outdoor bookshelf ──
	var shelf_pos := lib_pos + Vector2(-50 * _sx, 30 * _sy)
	_add_outdoor_bookshelf(root, shelf_pos)

	# ── NEW: Storytelling circle ──
	var story_pos := lib_pos + Vector2(-80 * _sx, 55 * _sy)
	_add_storytelling_circle(root, story_pos)

	# ── Strolling NPC near library ──
	var walk_a := lib_pos + Vector2(30 * _sx, 50 * _sy)
	var walk_b := Vector2(_vp.x * 0.65, _vp.y * 0.45)
	var book_npc := _add_walking_npc(root, walk_a, Color(1.0, 0.96, 0.75))
	_start_npc_walk(book_npc, walk_a, walk_b, 8.0)

	# ── NEW: Potted plants ──
	for i in range(3):
		_add_potted_plant(root, lib_pos + Vector2((-40 + i * 30) * _sx, 25 * _sy))

	# ── NEW: Sleeping cat ──
	var cat_pos := lib_pos + Vector2(55 * _sx, 55 * _sy)
	_add_sleeping_cat(root, cat_pos)

	# ── NEW: Scroll decorations ──
	_add_scroll_prop(root, Vector2(_vp.x * 0.72, _vp.y * 0.48))
	_add_scroll_prop(root, Vector2(_vp.x * 0.58, _vp.y * 0.38))

	return [
		{"pos": shelf_pos, "label": "An outdoor library!"},
		{"pos": story_pos, "label": "Stories being told!"},
		{"pos": cat_pos, "label": "A sleepy cat."},
	]


# ═════════════════════════════════════════════════════════════════════════════
# TIER 6 — Well: Water of Life
# Well sparkles + fountain + pebbles + lush grass + lily pads + stepping stones +
# dragonflies + bucket + moss + bridge + frog + irrigation channels
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_6(root: Node2D) -> Array[Dictionary]:
	var well_pos := Vector2(_vp.x * 0.50, _vp.y * 0.58)

	# Path pebbles
	for i in range(7):
		var px := _vp.x * (0.30 + i * 0.06)
		var py := _vp.y * 0.61 + randf_range(-6, 6) * _sy
		var pebble := Polygon2D.new()
		pebble.polygon = _oval_pts(px, py, randf_range(3, 5) * _sx, randf_range(2, 4) * _sy, 8)
		pebble.color = Color("#8E8E96") if i % 2 == 0 else Color("#6B6B73")
		pebble.z_index = -1
		root.add_child(pebble)

	# ── NEW: Lush grass burst radiating from well ──
	for i in range(6):
		var angle := TAU * i / 6.0
		var dist := randf_range(50, 90) * _sx
		var gpos := well_pos + Vector2(cos(angle) * dist, sin(angle) * dist * 0.6)
		var grass_r := randf_range(12, 22) * _sx
		root.add_child(_make_circle_panel(
			Vector2(gpos.x - grass_r, gpos.y - grass_r),
			grass_r * 2,
			Color("#3DBF2E").lightened(randf_range(0.0, 0.15))
		))

	# ── NEW: Water lily pads ──
	var fountain_area := Vector2(_vp.x * 0.50, _vp.y * 0.65)
	_add_lily_pads(root, fountain_area, 4)

	# ── NEW: Stepping stone path to well ──
	_add_stepping_stones(root, Vector2(_vp.x * 0.45, _vp.y * 0.62), well_pos + Vector2(0, 20 * _sy), 5)

	# ── NEW: Bucket and rope ──
	_add_bucket_rope(root, well_pos + Vector2(18 * _sx, -10 * _sy))

	# ── NEW: Moss patches ──
	for i in range(3):
		var mpos := well_pos + Vector2(randf_range(-80, 80) * _sx, randf_range(30, 70) * _sy)
		var mr := randf_range(6, 12) * _sx
		root.add_child(_make_circle_panel(Vector2(mpos.x - mr, mpos.y - mr), mr * 2, Color("#1A5C10").lightened(0.1)))

	# ── NEW: Small wooden bridge ──
	var bridge_pos := fountain_area + Vector2(-30 * _sx, 10 * _sy)
	_add_small_bridge(root, bridge_pos)

	# ── NEW: Frog NPC ──
	var frog_pos := fountain_area + Vector2(35 * _sx, 15 * _sy)
	_add_frog(root, frog_pos)

	# ── NEW: Irrigation channels ──
	_add_irrigation_channel(root, well_pos + Vector2(30 * _sx, 20 * _sy), Vector2(_vp.x * 0.64, _vp.y * 0.57))
	_add_irrigation_channel(root, well_pos + Vector2(-30 * _sx, 20 * _sy), Vector2(_vp.x * 0.40, _vp.y * 0.62))

	return [
		{"pos": fountain_area, "label": "Water flows again!"},
		{"pos": bridge_pos, "label": "A new bridge!"},
		{"pos": frog_pos, "label": "A friendly frog!"},
	]


# ═════════════════════════════════════════════════════════════════════════════
# TIER 7 — Market: Commerce Thrives
# Stalls + NPCs + lanterns + signpost + produce cart + rugs + musician +
# more NPCs + baskets + bunting + hanging goods + torches
# ═════════════════════════════════════════════════════════════════════════════
func _build_tier_7(root: Node2D) -> Array[Dictionary]:
	var market_pos := Vector2(_vp.x * 0.18, _vp.y * 0.68)

	# 4 Market stalls (up from 2)
	_add_market_stall(root, Vector2(_vp.x * 0.12, _vp.y * 0.73), Color("#EB6B1F"))
	_add_market_stall(root, Vector2(_vp.x * 0.24, _vp.y * 0.76), Color("#E8C547"))
	_add_market_stall(root, Vector2(_vp.x * 0.08, _vp.y * 0.80), Color("#3E8948"))
	_add_market_stall(root, Vector2(_vp.x * 0.20, _vp.y * 0.82), Color("#E94560"))

	# 2 market NPCs — left and right
	_add_idle_npc(root, market_pos + Vector2(-75 * _sx, 60 * _sy), Color(1.0, 0.82, 0.78))
	_add_idle_npc(root, market_pos + Vector2(75 * _sx, 55 * _sy), Color(1, 1, 1), true)

	# 1 walking shopper
	var mw1a := market_pos + Vector2(-30 * _sx, 65 * _sy)
	var mw1b := market_pos + Vector2(50 * _sx, 60 * _sy)
	var mnpc1 := _add_walking_npc(root, mw1a, Color(0.82, 0.88, 1.0))
	_start_npc_walk(mnpc1, mw1a, mw1b, 5.0)

	# Hanging lanterns (3 positions)
	_add_hanging_lantern(root, Vector2(_vp.x * 0.14, _vp.y * 0.60))
	_add_hanging_lantern(root, Vector2(_vp.x * 0.50, _vp.y * 0.53))
	_add_hanging_lantern(root, Vector2(_vp.x * 0.78, _vp.y * 0.62))

	# ── NEW: Directional signpost ──
	var signpost_pos := Vector2(_vp.x * 0.30, _vp.y * 0.65)
	_add_signpost(root, signpost_pos)

	# ── NEW: Produce cart ──
	_add_produce_cart(root, market_pos + Vector2(-50 * _sx, 60 * _sy))

	# ── NEW: Colorful ground rugs ──
	_add_ground_rug(root, Vector2(_vp.x * 0.13, _vp.y * 0.77), Color("#E8C547"), Color("#EB6B1F"))
	_add_ground_rug(root, Vector2(_vp.x * 0.21, _vp.y * 0.84), Color("#8B5CF6"), Color("#E94560"))

	# ── NEW: Musician NPC with music note particles ──
	var musician_pos := market_pos + Vector2(100 * _sx, 50 * _sy)
	_add_musician_npc(root, musician_pos)

	# ── NEW: Basket props ──
	_add_basket_prop(root, Vector2(_vp.x * 0.10, _vp.y * 0.76))
	_add_basket_prop(root, Vector2(_vp.x * 0.22, _vp.y * 0.79))
	_add_basket_prop(root, Vector2(_vp.x * 0.16, _vp.y * 0.85))

	# ── NEW: Bunting garlands between stalls ──
	_add_bunting(root, Vector2(_vp.x * 0.10, _vp.y * 0.70), Vector2(_vp.x * 0.26, _vp.y * 0.72))


	return [
		{"pos": signpost_pos, "label": "Signs for every building!"},
		{"pos": musician_pos, "label": "Music fills the air!"},
		{"pos": market_pos + Vector2(0, 50 * _sy), "label": "The market is bustling!"},
	]


func _build_tier_8(root: Node2D) -> Array[Dictionary]:
	# Village fully restored — a few final flourishes near the bakery
	_add_flowers(root, Vector2(_vp.x * 0.72, _vp.y * 0.42))
	_add_flowers(root, Vector2(_vp.x * 0.18, _vp.y * 0.66))
	_add_idle_npc(root, Vector2(_vp.x * 0.70, _vp.y * 0.55), Color(1.0, 0.9, 0.75))
	_add_idle_npc(root, Vector2(_vp.x * 0.20, _vp.y * 0.60), Color(0.75, 0.9, 1.0))
	# Tour highlights deferred to TownCelebration
	return []


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

	# If music is currently disabled, silence immediately — player stays loaded
	if not AudioManager.music_enabled:
		player.volume_db = -80.0
	elif fade_in:
		var tw := create_tween()
		tw.tween_property(player, "volume_db", target_db, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(
			Tween.EASE_OUT
		)
	else:
		player.volume_db = target_db

	_ambient_players[tier] = player


## Called when AudioManager.music_toggled fires.
func _on_music_toggled(enabled: bool) -> void:
	for tier in _ambient_players:
		var player: AudioStreamPlayer = _ambient_players[tier]
		if not is_instance_valid(player):
			continue
		var target_db: float = AMBIENT_LAYERS[tier]["db"]
		if enabled:
			# Fade ambient layers back in
			var tw := create_tween()
			tw.tween_property(player, "volume_db", target_db, 1.5).set_trans(
				Tween.TRANS_QUAD
			).set_ease(Tween.EASE_OUT)
		else:
			# Silence immediately
			player.volume_db = -80.0


## Called when AudioManager.music_ducked_changed fires (transient duck, e.g. mic recording).
## Skip while music_enabled is false so we don't fight the toggle.
func _on_music_ducked_changed(ducked: bool) -> void:
	if not AudioManager.music_enabled:
		return
	for tier in _ambient_players:
		var player: AudioStreamPlayer = _ambient_players[tier]
		if not is_instance_valid(player):
			continue
		var target_db: float = -80.0 if ducked else AMBIENT_LAYERS[tier]["db"]
		var tw := create_tween()
		tw.tween_property(player, "volume_db", target_db, 0.25).set_trans(
			Tween.TRANS_QUAD
		).set_ease(Tween.EASE_OUT)


# ═════════════════════════════════════════════════════════════════════════════
# NPC CHEERING — triggered during ending camera tour
# ═════════════════════════════════════════════════════════════════════════════


## Make nearby NPCs "cheer" by hopping and spawning sparkles.
## Called by Main._play_ending_sequence() during the camera tour.
func cheer_npcs_near(building_pos: Vector2, radius: float) -> void:
	var npcs_found: Array[Node2D] = []

	# Scan all tier roots for Node2D groups near the building
	for child in get_children():
		if not child is Node2D:
			continue
		# Each tier root (Tier1, Tier2, ...) contains prop groups
		for prop in child.get_children():
			if not prop is Node2D:
				continue
			var dist: float = prop.global_position.distance_to(building_pos)
			if dist < radius:
				# Heuristic: NPC groups have a circle Panel child (the head)
				var has_head := false
				for sub in prop.get_children():
					if sub is Panel:
						has_head = true
						break
				if has_head:
					npcs_found.append(prop)

	# Animate each NPC with staggered timing
	var delay := 0.0
	for npc in npcs_found:
		_cheer_single_npc(npc, delay)
		delay += randf_range(0.1, 0.3)


func _cheer_single_npc(npc: Node2D, start_delay: float) -> void:
	if not is_instance_valid(npc):
		return
	var orig_pos := npc.position
	var orig_scale := npc.scale

	get_tree().create_timer(start_delay).timeout.connect(func() -> void:
		if not is_instance_valid(npc):
			return

		# Bouncy hops (3 hops, decreasing height)
		var tw := npc.create_tween()
		for i in 3:
			var hop_height := (12.0 - float(i) * 3.0) * _sy
			tw.tween_property(npc, "position:y", orig_pos.y - hop_height, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(npc, "position:y", orig_pos.y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		# Stretch up (arms raised) + return
		var scale_tw := npc.create_tween()
		scale_tw.tween_interval(start_delay * 0.3)
		scale_tw.tween_property(npc, "scale", Vector2(1.0, 1.18), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tw.tween_property(npc, "scale", orig_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	)


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
## Small barrel cluster
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
	_add_rect(group, Vector2(-18 * _sx, -18 * _sy), Vector2(38 * _sx, 2 * _sy), Color("#5C3D11"))
	group.add_child(_make_circle_panel(Vector2(-20 * _sx, -6 * _sy), 10 * _sx, Color("#3E2408")))
	group.add_child(_make_circle_panel(Vector2(14 * _sx, -6 * _sy), 10 * _sx, Color("#3E2408")))
	root.add_child(group)


## Bench
func _add_bench(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	var shad := Polygon2D.new()
	shad.polygon = _oval_pts(4 * _sx, 4 * _sy, 28 * _sx, 8 * _sy, 10)
	shad.color = Color(0, 0, 0, 0.16)
	shad.z_index = -1
	group.add_child(shad)
	_add_rect(group, Vector2(-26 * _sx, -22 * _sy), Vector2(52 * _sx, 6 * _sy), Color("#4A2E0C"))
	for i in range(3):
		_add_rect(
			group,
			Vector2(-26 * _sx, -16 * _sy + i * 4 * _sy),
			Vector2(52 * _sx, 4 * _sy),
			Color("#5C3D11") if i % 2 == 0 else Color("#7A5522")
		)
	for ax in [-26.0 * _sx, 22.0 * _sx]:
		_add_rect(group, Vector2(ax, -22 * _sy), Vector2(6 * _sx, 8 * _sy), Color("#4A2E0C"))
	for lx in [-20.0 * _sx, 14.0 * _sx]:
		_add_rect(group, Vector2(lx, -4 * _sy), Vector2(4 * _sx, 10 * _sy), Color("#3E2408"))
	root.add_child(group)


## Garden patch with small dot "vegetables"
func _add_garden(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	_add_rect(group, Vector2(-18 * _sx, -14 * _sy), Vector2(36 * _sx, 14 * _sy), Color("#4A3018"))
	for row in range(2):
		_add_rect(
			group,
			Vector2(-18 * _sx, -12 * _sy + row * 6 * _sy),
			Vector2(36 * _sx, 1 * _sy),
			Color("#3A2210")
		)
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
	_add_rect(group, Vector2(-2 * _sx, -60 * _sy), Vector2(4 * _sx, 60 * _sy), Color("#5C3D11"))
	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([
		Vector2(2 * _sx, -58 * _sy),
		Vector2(24 * _sx, -50 * _sy),
		Vector2(2 * _sx, -42 * _sy),
	])
	flag.color = flag_color
	group.add_child(flag)
	_add_rect(group, Vector2(-4 * _sx, -2 * _sy), Vector2(8 * _sx, 4 * _sy), Color("#3E2408"))
	# Gentle flag sway
	var tw := flag.create_tween().set_loops()
	tw.tween_property(flag, "rotation_degrees", 3.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(flag, "rotation_degrees", -3.0, 1.2).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Reading NPC seated with a book
func _add_reading_npc(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 0), 18 * _sx, 5 * _sy))
	_add_rect(group, Vector2(-6 * _sx, -26 * _sy), Vector2(12 * _sx, 16 * _sy), Color("#8B5CF6"))
	group.add_child(_make_circle_panel(Vector2(-7 * _sx, -38 * _sy), 14 * _sx, Color("#F5CBA7")))
	_add_rect(group, Vector2(-9 * _sx, -14 * _sy), Vector2(18 * _sx, 12 * _sy), Color("#FFEEDD"))
	_add_rect(group, Vector2(-1 * _sx, -14 * _sy), Vector2(2 * _sx, 12 * _sy), Color("#CCA870"))
	var tw := group.create_tween().set_loops()
	tw.tween_property(group, "position:y", group.position.y - 2 * _sy, 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(group, "position:y", group.position.y, 2.0).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Market stall: table + triangular awning
func _add_market_stall(root: Node2D, pos: Vector2, color: Color) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 0), 32 * _sx, 8 * _sy))
	for lx in [-22.0 * _sx, 16.0 * _sx]:
		_add_rect(group, Vector2(lx, -24 * _sy), Vector2(4 * _sx, 24 * _sy), Color("#5C3D11"))
	_add_rect(group, Vector2(-26 * _sx, -28 * _sy), Vector2(52 * _sx, 5 * _sy), Color("#8B5E3C"))
	for ii in range(3):
		var ix := -18 * _sx + ii * 14 * _sx
		_add_rect(group, Vector2(ix, -36 * _sy), Vector2(10 * _sx, 8 * _sy), color.lightened(0.3))
	var awning := Polygon2D.new()
	awning.polygon = PackedVector2Array([
		Vector2(-32 * _sx, -30 * _sy),
		Vector2(32 * _sx, -30 * _sy),
		Vector2(24 * _sx, -52 * _sy),
		Vector2(-24 * _sx, -52 * _sy),
	])
	awning.color = color
	group.add_child(awning)
	var fringe := ColorRect.new()
	fringe.color = color.darkened(0.2)
	fringe.size = Vector2(64 * _sx, 4 * _sy)
	fringe.position = Vector2(-32 * _sx, -34 * _sy)
	fringe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(fringe)
	root.add_child(group)


## Hanging lantern
func _add_hanging_lantern(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	_add_rect(group, Vector2(-1 * _sx, -22 * _sy), Vector2(2 * _sx, 14 * _sy), Color("#5C3D11"))
	group.add_child(_make_circle_panel(Vector2(-6 * _sx, -18 * _sy), 12 * _sx, Color("#E8A030")))
	var tw := group.create_tween().set_loops()
	tw.tween_property(group, "rotation_degrees", 4.0, 1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(group, "rotation_degrees", -4.0, 1.8).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


# ═════════════════════════════════════════════════════════════════════════════
# NEW PROP BUILDERS — Tier 1-7 additions
# ═════════════════════════════════════════════════════════════════════════════

## Flagpole with waving flag
func _add_flagpole(root: Node2D, pos: Vector2, flag_color: Color) -> void:
	var group := Node2D.new()
	group.position = pos
	# Pole
	_add_rect(group, Vector2(-2 * _sx, -80 * _sy), Vector2(4 * _sx, 80 * _sy), Color("#6B6B73"))
	# Pole top ball
	group.add_child(_make_circle_panel(Vector2(-4 * _sx, -84 * _sy), 8 * _sx, Color("#E8C547")))
	# Flag (larger than pennant)
	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([
		Vector2(3 * _sx, -78 * _sy),
		Vector2(40 * _sx, -72 * _sy),
		Vector2(38 * _sx, -60 * _sy),
		Vector2(3 * _sx, -58 * _sy),
	])
	flag.color = flag_color
	group.add_child(flag)
	# Flag wave animation
	var tw := flag.create_tween().set_loops()
	tw.tween_property(flag, "rotation_degrees", 6.0, 1.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(flag, "rotation_degrees", -2.0, 1.5).set_trans(Tween.TRANS_SINE)
	# Ground base
	_add_rect(group, Vector2(-6 * _sx, -3 * _sy), Vector2(12 * _sx, 6 * _sy), Color("#5C3D11"))
	root.add_child(group)


## Cobblestone plaza — circular arrangement of stones
func _add_cobblestone_plaza(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.z_index = -2
	seed(42)
	var stone_colors := [Color("#7A7A82"), Color("#8E8E96"), Color("#6B6B73"), Color("#9A9AA2")]
	for ring in range(3):
		var count := 6 + ring * 4
		var radius := (14.0 + ring * 14.0) * _sx
		for i in range(count):
			var angle := TAU * i / float(count) + ring * 0.3
			var sx_off := cos(angle) * radius
			var sy_off := sin(angle) * radius * 0.6  # Perspective squish
			var stone_r := randf_range(5, 9) * _sx
			var sc: Color = stone_colors[randi() % stone_colors.size()]
			group.add_child(_make_circle_panel(Vector2(sx_off - stone_r, sy_off - stone_r), stone_r * 2, sc))
	root.add_child(group)


## Notice board prop
func _add_notice_board(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Posts
	_add_rect(group, Vector2(-16 * _sx, -40 * _sy), Vector2(4 * _sx, 42 * _sy), Color("#5C3D11"))
	_add_rect(group, Vector2(12 * _sx, -40 * _sy), Vector2(4 * _sx, 42 * _sy), Color("#5C3D11"))
	# Board
	_add_rect(group, Vector2(-18 * _sx, -38 * _sy), Vector2(36 * _sx, 26 * _sy), Color("#8B5E3C"))
	_add_rect(group, Vector2(-18 * _sx, -38 * _sy), Vector2(36 * _sx, 3 * _sy), Color("#4A2E0C"))
	# Notices (small colored rects)
	var notice_colors := [Color("#FFEEDD"), Color("#FFE066"), Color("#D6F5D6"), Color("#FFD6D6")]
	for i in range(4):
		var nx := -14 * _sx + (i % 2) * 16 * _sx
		var ny := -34 * _sy + (i / 2) * 12 * _sy
		_add_rect(group, Vector2(nx, ny), Vector2(12 * _sx, 10 * _sy), notice_colors[i])
	root.add_child(group)


## Swing set
func _add_swing_set(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 24 * _sx, 6 * _sy))
	# Frame — A-frame poles
	_add_rect(group, Vector2(-20 * _sx, -50 * _sy), Vector2(3 * _sx, 52 * _sy), Color("#5C3D11"))
	_add_rect(group, Vector2(17 * _sx, -50 * _sy), Vector2(3 * _sx, 52 * _sy), Color("#5C3D11"))
	# Crossbar
	_add_rect(group, Vector2(-22 * _sx, -52 * _sy), Vector2(44 * _sx, 4 * _sy), Color("#4A2E0C"))
	# Swing seat + rope (left)
	var seat_l := Node2D.new()
	_add_rect(seat_l, Vector2(-10 * _sx, -22 * _sy), Vector2(1 * _sx, 30 * _sy), Color("#8B8B8B"))
	_add_rect(seat_l, Vector2(-14 * _sx, -22 * _sy + 28 * _sy), Vector2(10 * _sx, 3 * _sy), Color("#3E2408"))
	group.add_child(seat_l)
	# Swing seat + rope (right)
	var seat_r := Node2D.new()
	_add_rect(seat_r, Vector2(8 * _sx, -22 * _sy), Vector2(1 * _sx, 30 * _sy), Color("#8B8B8B"))
	_add_rect(seat_r, Vector2(4 * _sx, -22 * _sy + 28 * _sy), Vector2(10 * _sx, 3 * _sy), Color("#3E2408"))
	group.add_child(seat_r)
	# Pendulum swing animation — rotate around crossbar attachment point.
	# Node2D rotates around its own position, so shift each seat so its origin
	# is at the attachment point (top of rope = crossbar y).
	seat_l.position = Vector2(-10 * _sx, -52 * _sy)
	var tw_l := seat_l.create_tween().set_loops()
	tw_l.tween_property(seat_l, "rotation_degrees", 8.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw_l.tween_property(seat_l, "rotation_degrees", -8.0, 1.2).set_trans(Tween.TRANS_SINE)
	seat_r.position = Vector2(8 * _sx, -52 * _sy)
	var tw_r := seat_r.create_tween().set_loops().set_speed_scale(0.85)
	tw_r.tween_property(seat_r, "rotation_degrees", -6.0, 1.4).set_trans(Tween.TRANS_SINE)
	tw_r.tween_property(seat_r, "rotation_degrees", 6.0, 1.4).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Seesaw
func _add_seesaw(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 20 * _sx, 5 * _sy))
	# Pivot triangle
	var pivot := Polygon2D.new()
	pivot.polygon = PackedVector2Array([
		Vector2(0, -8 * _sy),
		Vector2(-6 * _sx, 2 * _sy),
		Vector2(6 * _sx, 2 * _sy),
	])
	pivot.color = Color("#5C3D11")
	group.add_child(pivot)
	# Plank
	var plank := ColorRect.new()
	plank.color = Color("#8B5E3C")
	plank.size = Vector2(40 * _sx, 4 * _sy)
	plank.position = Vector2(-20 * _sx, -10 * _sy)
	plank.pivot_offset = Vector2(20 * _sx, 2 * _sy)
	plank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(plank)
	# Tilt animation
	var tw := plank.create_tween().set_loops()
	tw.tween_property(plank, "rotation_degrees", 8.0, 1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(plank, "rotation_degrees", -8.0, 1.8).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Chalk drawings on ground
func _add_chalk_drawings(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.z_index = -1
	var chalk_colors := [Color(1, 0.4, 0.4, 0.5), Color(0.3, 0.7, 1, 0.5), Color(1, 0.9, 0.3, 0.5), Color(0.6, 1, 0.4, 0.5)]
	for i in range(3):
		var cx := randf_range(-20, 20) * _sx
		var cy := randf_range(-10, 10) * _sy
		var cr := randf_range(8, 14) * _sx
		group.add_child(_make_circle_panel(Vector2(cx - cr, cy - cr), cr * 2, chalk_colors[i]))
	# Star shape
	var star := Polygon2D.new()
	var star_pts := PackedVector2Array()
	for i in range(10):
		var angle := TAU * i / 10.0 - PI / 2.0
		var r := (10.0 if i % 2 == 0 else 5.0) * _sx
		star_pts.append(Vector2(cos(angle) * r + 25 * _sx, sin(angle) * r))
	star.polygon = star_pts
	star.color = Color(1, 0.8, 0.2, 0.45)
	group.add_child(star)
	root.add_child(group)


## Hopscotch pattern
func _add_hopscotch(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.z_index = -1
	var hop_colors := [Color(1, 0.5, 0.5, 0.4), Color(0.5, 0.8, 1, 0.4), Color(1, 0.9, 0.4, 0.4), Color(0.5, 1, 0.6, 0.4)]
	for i in range(5):
		var hy := -i * 14 * _sy
		var hx := 0.0
		if i == 1 or i == 3:  # Side by side
			_add_rect(group, Vector2(-14 * _sx, hy), Vector2(12 * _sx, 12 * _sy), hop_colors[i % 4])
			_add_rect(group, Vector2(2 * _sx, hy), Vector2(12 * _sx, 12 * _sy), hop_colors[(i + 1) % 4])
		else:
			_add_rect(group, Vector2(-6 * _sx, hy), Vector2(12 * _sx, 12 * _sy), hop_colors[i % 4])
	root.add_child(group)


## Rainbow bunting between two points
func _add_bunting(root: Node2D, from: Vector2, to: Vector2) -> void:
	var group := Node2D.new()
	var colors := [Color("#FF6B6B"), Color("#FFD93D"), Color("#7BCFED"), Color("#B088F9"), Color("#4DB82A"), Color("#FF8E53")]
	var count := 8
	for i in range(count):
		var t := float(i) / float(count - 1)
		var px: float = lerp(from.x, to.x, t)
		var sag := sin(t * PI) * 15 * _sy  # Droopy curve
		var py: float = lerp(from.y, to.y, t) + sag
		var flag := Polygon2D.new()
		var fw := 6 * _sx
		var fh := 10 * _sy
		flag.polygon = PackedVector2Array([
			Vector2(px - fw, py),
			Vector2(px + fw, py),
			Vector2(px, py + fh),
		])
		flag.color = colors[i % colors.size()]
		group.add_child(flag)
	# Rope line
	for i in range(count - 1):
		var t1 := float(i) / float(count - 1)
		var t2 := float(i + 1) / float(count - 1)
		var x1: float = lerp(from.x, to.x, t1)
		var y1: float = lerp(from.y, to.y, t1) + sin(t1 * PI) * 15 * _sy
		var x2: float = lerp(from.x, to.x, t2)
		var y2: float = lerp(from.y, to.y, t2) + sin(t2 * PI) * 15 * _sy
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(x1, y1), Vector2(x2, y2)])
		line.width = 2 * _sx
		line.default_color = Color("#5C3D11")
		group.add_child(line)
	root.add_child(group)


## Book cart
func _add_book_cart(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 16 * _sx, 4 * _sy))
	_add_rect(group, Vector2(-14 * _sx, -20 * _sy), Vector2(28 * _sx, 16 * _sy), Color("#8B5E3C"))
	# Wheels
	group.add_child(_make_circle_panel(Vector2(-16 * _sx, -6 * _sy), 8 * _sx, Color("#3E2408")))
	group.add_child(_make_circle_panel(Vector2(8 * _sx, -6 * _sy), 8 * _sx, Color("#3E2408")))
	# Books (colorful vertical rects)
	var book_colors := [Color("#E94560"), Color("#5B9BD5"), Color("#3E8948"), Color("#8B5CF6"), Color("#E8C547")]
	for i in range(5):
		var bx := -12 * _sx + i * 5 * _sx
		_add_rect(group, Vector2(bx, -28 * _sy), Vector2(4 * _sx, 10 * _sy), book_colors[i])
	root.add_child(group)


## Hanging sign
func _add_hanging_sign(root: Node2D, pos: Vector2, color: Color) -> void:
	var group := Node2D.new()
	group.position = pos
	# Bracket
	_add_rect(group, Vector2(-2 * _sx, -30 * _sy), Vector2(4 * _sx, 14 * _sy), Color("#5C3D11"))
	# Chain lines
	_add_rect(group, Vector2(-12 * _sx, -18 * _sy), Vector2(1 * _sx, 8 * _sy), Color("#8B8B8B"))
	_add_rect(group, Vector2(11 * _sx, -18 * _sy), Vector2(1 * _sx, 8 * _sy), Color("#8B8B8B"))
	# Sign board
	var sign_board := ColorRect.new()
	sign_board.color = color.darkened(0.1)
	sign_board.size = Vector2(26 * _sx, 14 * _sy)
	sign_board.position = Vector2(-13 * _sx, -12 * _sy)
	sign_board.pivot_offset = Vector2(13 * _sx, 0)
	sign_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(sign_board)
	# Sway
	var tw := sign_board.create_tween().set_loops()
	tw.tween_property(sign_board, "rotation_degrees", 5.0, 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sign_board, "rotation_degrees", -5.0, 2.0).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Horse silhouette
func _add_horse(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 4 * _sy), 20 * _sx, 6 * _sy))
	# Body (ellipse-ish)
	group.add_child(_make_circle_panel(Vector2(-14 * _sx, -24 * _sy), 28 * _sx, Color("#4A2E0C")))
	# Head
	group.add_child(_make_circle_panel(Vector2(-24 * _sx, -36 * _sy), 14 * _sx, Color("#3E2408")))
	# Legs (4 thin rects)
	for lx in [-10.0, -4.0, 6.0, 12.0]:
		_add_rect(group, Vector2(lx * _sx, -10 * _sy), Vector2(3 * _sx, 14 * _sy), Color("#3E2408"))
	# Tail
	_add_rect(group, Vector2(12 * _sx, -22 * _sy), Vector2(3 * _sx, 12 * _sy), Color("#2A1A08"))
	# Gentle idle bob
	var tw := group.create_tween().set_loops()
	tw.tween_property(group, "position:y", pos.y - 1.5 * _sy, 2.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(group, "position:y", pos.y, 2.5).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Stacked crates
func _add_crate_stack(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 18 * _sx, 5 * _sy))
	var crate_colors := [Color("#5C3D11"), Color("#7A5522"), Color("#8B5E3C")]
	for i in range(3):
		var cx := (i - 1) * 10 * _sx
		var cy := -i * 12 * _sy - 10 * _sy
		_add_rect(group, Vector2(cx - 8 * _sx, cy), Vector2(16 * _sx, 12 * _sy), crate_colors[i])
		# Cross brace
		_add_rect(group, Vector2(cx - 8 * _sx, cy + 5 * _sy), Vector2(16 * _sx, 2 * _sy), crate_colors[i].darkened(0.2))
	root.add_child(group)


## Campfire (fire pit + stones, no particles)
func _add_campfire(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Fire pit base
	group.add_child(_make_circle_panel(Vector2(-12 * _sx, -6 * _sy), 24 * _sx, Color("#2A1A08")))
	# Stones around pit
	for i in range(6):
		var angle := TAU * i / 6.0
		var sr := 14 * _sx
		var sx_off := cos(angle) * sr
		var sy_off := sin(angle) * sr * 0.6
		group.add_child(_make_circle_panel(Vector2(sx_off - 4 * _sx, sy_off - 4 * _sy), 8 * _sx, Color("#6B6B73")))
	root.add_child(group)


## Outdoor dining table
func _add_outdoor_table(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 20 * _sx, 5 * _sy))
	# Table legs
	for lx in [-14.0, 10.0]:
		_add_rect(group, Vector2(lx * _sx, -16 * _sy), Vector2(3 * _sx, 18 * _sy), Color("#5C3D11"))
	# Table top
	_add_rect(group, Vector2(-18 * _sx, -20 * _sy), Vector2(36 * _sx, 4 * _sy), Color("#8B5E3C"))
	# Plates (small circles)
	group.add_child(_make_circle_panel(Vector2(-12 * _sx, -26 * _sy), 8 * _sx, Color("#FFEEDD")))
	group.add_child(_make_circle_panel(Vector2(4 * _sx, -26 * _sy), 8 * _sx, Color("#FFEEDD")))
	# Cups
	_add_rect(group, Vector2(-8 * _sx, -30 * _sy), Vector2(4 * _sx, 6 * _sy), Color("#9AA8BF"))
	_add_rect(group, Vector2(10 * _sx, -30 * _sy), Vector2(4 * _sx, 6 * _sy), Color("#9AA8BF"))
	root.add_child(group)


## Hitching post
func _add_hitching_post(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Two vertical posts
	_add_rect(group, Vector2(-18 * _sx, -30 * _sy), Vector2(4 * _sx, 32 * _sy), Color("#5C3D11"))
	_add_rect(group, Vector2(14 * _sx, -30 * _sy), Vector2(4 * _sx, 32 * _sy), Color("#5C3D11"))
	# Horizontal bar
	_add_rect(group, Vector2(-18 * _sx, -28 * _sy), Vector2(36 * _sx, 4 * _sy), Color("#4A2E0C"))
	root.add_child(group)


## Stepping stones between two points
func _add_stepping_stones(root: Node2D, from: Vector2, to: Vector2, count: int) -> void:
	for i in range(count):
		var t := float(i) / float(count - 1) if count > 1 else 0.5
		var sx_off: float = lerp(from.x, to.x, t) + randf_range(-4, 4) * _sx
		var sy_off: float = lerp(from.y, to.y, t) + randf_range(-3, 3) * _sy
		var stone_r := randf_range(5, 8) * _sx
		var stone := _make_circle_panel(Vector2(sx_off - stone_r, sy_off - stone_r), stone_r * 2, Color("#7A7A82").darkened(randf_range(0, 0.15)))
		stone.z_index = -1
		root.add_child(stone)


## Praying/kneeling NPC
func _add_praying_npc(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 10 * _sx, 3 * _sy))
	# Lower body (kneeling)
	_add_rect(group, Vector2(-5 * _sx, -12 * _sy), Vector2(10 * _sx, 10 * _sy), Color("#9AA8BF"))
	# Head (slightly tilted via offset)
	group.add_child(_make_circle_panel(Vector2(-6 * _sx, -24 * _sy), 10 * _sx, Color("#F5CBA7")))
	# Gentle sway
	var tw := group.create_tween().set_loops()
	tw.tween_property(group, "position:y", pos.y - 1 * _sy, 3.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(group, "position:y", pos.y, 3.0).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Rose garden — red/pink/white only
func _add_rose_garden(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	seed(int(pos.x * 2.1 + pos.y * 4.7))
	var rose_colors := [Color("#FF3B3B"), Color("#FF6B8A"), Color("#FFB3C6"), Color("#FFFFFF"), Color("#CC0033")]
	for _fi in range(randi_range(5, 7)):
		var fx := randf_range(-22, 22) * _sx
		var fy := randf_range(-10, 6) * _sy
		var pr := randf_range(3.0, 5.5) * _sx
		var pc: Color = rose_colors[randi() % rose_colors.size()]
		# Stem
		var stem := ColorRect.new()
		stem.color = Color("#2D6E1E")
		stem.size = Vector2(2 * _sx, randf_range(8, 14) * _sy)
		stem.position = Vector2(fx - 1 * _sx, fy)
		stem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		group.add_child(stem)
		# Rose bloom
		for pi in range(6):
			var pa := TAU * pi / 6.0
			group.add_child(_make_circle_panel(
				Vector2(fx + cos(pa) * pr * 0.8 - pr * 0.5, fy + sin(pa) * pr * 0.8 - pr * 0.5),
				pr, pc
			))
		group.add_child(_make_circle_panel(Vector2(fx - pr * 0.3, fy - pr * 0.3), pr * 0.6, pc.lightened(0.3)))
	root.add_child(group)


## Candle glow
## Memorial stone
func _add_memorial_stone(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	_add_rect(group, Vector2(-5 * _sx, -14 * _sy), Vector2(10 * _sx, 14 * _sy), Color("#7A7A82"))
	# "Inscription" lines
	for i in range(3):
		_add_rect(group, Vector2(-3 * _sx, (-11 + i * 4) * _sy), Vector2(6 * _sx, 1 * _sy), Color("#6B6B73"))
	root.add_child(group)


## Decorative vine
func _add_vine(root: Node2D, pos: Vector2, length: int) -> void:
	var group := Node2D.new()
	group.position = pos
	for i in range(length):
		var vx := randf_range(-3, 3) * _sx
		var vy := -i * 6 * _sy
		var vr := randf_range(3, 5) * _sx
		group.add_child(_make_circle_panel(Vector2(vx - vr, vy - vr), vr * 2, Color("#2D6E1E").lightened(randf_range(0, 0.15))))
	root.add_child(group)


## Outdoor bookshelf
func _add_outdoor_bookshelf(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 22 * _sx, 5 * _sy))
	# Frame
	_add_rect(group, Vector2(-20 * _sx, -48 * _sy), Vector2(4 * _sx, 50 * _sy), Color("#4A2E0C"))
	_add_rect(group, Vector2(16 * _sx, -48 * _sy), Vector2(4 * _sx, 50 * _sy), Color("#4A2E0C"))
	# Shelves
	for sy_off in [-46, -30, -14]:
		_add_rect(group, Vector2(-20 * _sx, sy_off * _sy), Vector2(40 * _sx, 3 * _sy), Color("#5C3D11"))
	# Books (colorful spines)
	var book_colors := [Color("#E94560"), Color("#5B9BD5"), Color("#E8C547"), Color("#3E8948"),
		Color("#8B5CF6"), Color("#EB6B1F"), Color("#C07B3A"), Color("#FF6B6B"),
		Color("#7BCFED"), Color("#FFD93D"), Color("#B088F9"), Color("#4DB82A")]
	for shelf in range(3):
		var base_y := (-44 + shelf * 16) * _sy
		for i in range(4):
			var bx := (-16 + i * 8) * _sx
			var bh := randf_range(10, 14) * _sy
			_add_rect(group, Vector2(bx, base_y), Vector2(6 * _sx, bh), book_colors[(shelf * 4 + i) % book_colors.size()])
	root.add_child(group)


## Storytelling circle
func _add_storytelling_circle(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# 4 small chairs in semicircle
	for i in range(4):
		var angle := PI * 0.3 + PI * 0.4 * i / 3.0
		var cx := cos(angle) * 28 * _sx
		var cy := sin(angle) * 16 * _sy
		_add_rect(group, Vector2(cx - 4 * _sx, cy - 8 * _sy), Vector2(8 * _sx, 8 * _sy), Color("#5C3D11"))
	# Storyteller NPC in center
	var st := Node2D.new()
	st.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 10 * _sx, 3 * _sy))
	_add_rect(st, Vector2(-5 * _sx, -22 * _sy), Vector2(10 * _sx, 16 * _sy), Color("#8B5CF6"))
	st.add_child(_make_circle_panel(Vector2(-5 * _sx, -32 * _sy), 10 * _sx, Color("#F5CBA7")))
	group.add_child(st)
	# Gesturing animation
	var tw := st.create_tween().set_loops()
	tw.tween_property(st, "position:x", 3 * _sx, 1.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(st, "position:x", -3 * _sx, 1.5).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Potted plant
func _add_potted_plant(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Pot
	group.add_child(_make_circle_panel(Vector2(-6 * _sx, -6 * _sy), 12 * _sx, Color("#8B4513")))
	# Plant
	group.add_child(_make_circle_panel(Vector2(-8 * _sx, -18 * _sy), 16 * _sx, Color("#2D8B20")))
	group.add_child(_make_circle_panel(Vector2(-5 * _sx, -24 * _sy), 10 * _sx, Color("#3DBF2E")))
	root.add_child(group)


## Sleeping cat
func _add_sleeping_cat(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 10 * _sx, 3 * _sy))
	# Body (oval)
	group.add_child(_make_circle_panel(Vector2(-8 * _sx, -8 * _sy), 16 * _sx, Color("#E8A030")))
	# Head
	group.add_child(_make_circle_panel(Vector2(-12 * _sx, -12 * _sy), 10 * _sx, Color("#D4901A")))
	# Ears (triangles)
	var ear_l := Polygon2D.new()
	ear_l.polygon = PackedVector2Array([
		Vector2(-12 * _sx, -14 * _sy),
		Vector2(-8 * _sx, -20 * _sy),
		Vector2(-6 * _sx, -14 * _sy),
	])
	ear_l.color = Color("#D4901A")
	group.add_child(ear_l)
	var ear_r := Polygon2D.new()
	ear_r.polygon = PackedVector2Array([
		Vector2(-6 * _sx, -14 * _sy),
		Vector2(-2 * _sx, -20 * _sy),
		Vector2(0, -14 * _sy),
	])
	ear_r.color = Color("#D4901A")
	group.add_child(ear_r)
	# Tail
	group.add_child(_make_circle_panel(Vector2(6 * _sx, -6 * _sy), 8 * _sx, Color("#D4901A")))
	# Breathing tween
	var tw := group.create_tween().set_loops()
	tw.tween_property(group, "scale", Vector2(1.03, 1.03), 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(group, "scale", Vector2(1.0, 1.0), 2.0).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Scroll prop
func _add_scroll_prop(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Roll body
	_add_rect(group, Vector2(-10 * _sx, -5 * _sy), Vector2(20 * _sx, 10 * _sy), Color("#FFEEDD"))
	# Roll ends
	group.add_child(_make_circle_panel(Vector2(-12 * _sx, -4 * _sy), 6 * _sx, Color("#CCA870")))
	group.add_child(_make_circle_panel(Vector2(8 * _sx, -4 * _sy), 6 * _sx, Color("#CCA870")))
	root.add_child(group)


## Lily pads
func _add_lily_pads(root: Node2D, pos: Vector2, count: int) -> void:
	for i in range(count):
		var lx := pos.x + randf_range(-30, 30) * _sx
		var ly := pos.y + randf_range(-15, 15) * _sy
		var lr := randf_range(5, 8) * _sx
		# Pad
		root.add_child(_make_circle_panel(Vector2(lx - lr, ly - lr), lr * 2, Color("#2D8B20").lightened(0.1)))
		# Flower dot
		if randf() > 0.5:
			var fr := lr * 0.35
			var fc := Color("#FF8EAD") if randf() > 0.5 else Color("#FFFFFF")
			root.add_child(_make_circle_panel(Vector2(lx - fr, ly - fr), fr * 2, fc))


## Bucket and rope
func _add_bucket_rope(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Bucket
	_add_rect(group, Vector2(-6 * _sx, -12 * _sy), Vector2(12 * _sx, 12 * _sy), Color("#5C3D11"))
	_add_rect(group, Vector2(-6 * _sx, -12 * _sy), Vector2(12 * _sx, 2 * _sy), Color("#8B8B8B"))
	# Rope going up
	_add_rect(group, Vector2(-1 * _sx, -30 * _sy), Vector2(2 * _sx, 20 * _sy), Color("#8B7355"))
	root.add_child(group)


## Small wooden bridge
func _add_small_bridge(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Support posts
	_add_rect(group, Vector2(-24 * _sx, -8 * _sy), Vector2(4 * _sx, 12 * _sy), Color("#4A2E0C"))
	_add_rect(group, Vector2(20 * _sx, -8 * _sy), Vector2(4 * _sx, 12 * _sy), Color("#4A2E0C"))
	# Planks
	for i in range(5):
		var px := -20 * _sx + i * 10 * _sx
		var shade := Color("#8B5E3C") if i % 2 == 0 else Color("#7A5522")
		_add_rect(group, Vector2(px, -6 * _sy), Vector2(9 * _sx, 4 * _sy), shade)
	# Railings
	_add_rect(group, Vector2(-24 * _sx, -14 * _sy), Vector2(48 * _sx, 2 * _sy), Color("#5C3D11"))
	root.add_child(group)


## Frog NPC
func _add_frog(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Body
	group.add_child(_make_circle_panel(Vector2(-5 * _sx, -5 * _sy), 10 * _sx, Color("#3E8948")))
	# Eyes
	group.add_child(_make_circle_panel(Vector2(-5 * _sx, -9 * _sy), 4 * _sx, Color("#FFFFFF")))
	group.add_child(_make_circle_panel(Vector2(2 * _sx, -9 * _sy), 4 * _sx, Color("#FFFFFF")))
	group.add_child(_make_circle_panel(Vector2(-4 * _sx, -8 * _sy), 2 * _sx, Color("#1A1A1A")))
	group.add_child(_make_circle_panel(Vector2(3 * _sx, -8 * _sy), 2 * _sx, Color("#1A1A1A")))
	# Hop animation (every 4s)
	var tw := group.create_tween().set_loops()
	tw.tween_interval(3.5)
	tw.tween_property(group, "position:y", pos.y - 12 * _sy, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(group, "position:y", pos.y, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	root.add_child(group)


## Irrigation channel (thin blue line)
func _add_irrigation_channel(root: Node2D, from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.width = 3 * _sx
	line.default_color = Color(0.4, 0.7, 0.9, 0.35)
	line.z_index = -1
	root.add_child(line)


## Directional signpost
func _add_signpost(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Main pole
	_add_rect(group, Vector2(-3 * _sx, -65 * _sy), Vector2(6 * _sx, 67 * _sy), Color("#5C3D11"))
	# Direction signs (arrows)
	var sign_data := [
		{"y": -58, "dir": 1, "color": Color("#E8C547"), "label": "Town Hall"},
		{"y": -48, "dir": -1, "color": Color("#5B9BD5"), "label": "School"},
		{"y": -38, "dir": 1, "color": Color("#8B5CF6"), "label": "Library"},
		{"y": -28, "dir": -1, "color": Color("#EB6B1F"), "label": "Market"},
	]
	for sd in sign_data:
		var sy_off: float = sd["y"] * _sy
		var dir: int = sd["dir"]
		var sc: Color = sd["color"]
		var arrow := Polygon2D.new()
		if dir > 0:
			arrow.polygon = PackedVector2Array([
				Vector2(4 * _sx, sy_off),
				Vector2(34 * _sx, sy_off),
				Vector2(38 * _sx, sy_off + 4 * _sy),
				Vector2(34 * _sx, sy_off + 8 * _sy),
				Vector2(4 * _sx, sy_off + 8 * _sy),
			])
		else:
			arrow.polygon = PackedVector2Array([
				Vector2(-4 * _sx, sy_off),
				Vector2(-34 * _sx, sy_off),
				Vector2(-38 * _sx, sy_off + 4 * _sy),
				Vector2(-34 * _sx, sy_off + 8 * _sy),
				Vector2(-4 * _sx, sy_off + 8 * _sy),
			])
		arrow.color = sc
		group.add_child(arrow)
	root.add_child(group)


## Produce cart
func _add_produce_cart(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 18 * _sx, 5 * _sy))
	# Cart body
	_add_rect(group, Vector2(-16 * _sx, -18 * _sy), Vector2(32 * _sx, 14 * _sy), Color("#8B5E3C"))
	# Wheels
	group.add_child(_make_circle_panel(Vector2(-18 * _sx, -6 * _sy), 8 * _sx, Color("#3E2408")))
	group.add_child(_make_circle_panel(Vector2(10 * _sx, -6 * _sy), 8 * _sx, Color("#3E2408")))
	# Produce (colorful circles)
	var produce_colors := [Color("#E94560"), Color("#3E8948"), Color("#EB6B1F"), Color("#E8C547"), Color("#FF6B6B")]
	for i in range(5):
		var px := -12 * _sx + i * 6 * _sx
		group.add_child(_make_circle_panel(Vector2(px, -24 * _sy), 5 * _sx, produce_colors[i]))
	root.add_child(group)


## Colorful ground rug
func _add_ground_rug(root: Node2D, pos: Vector2, color1: Color, color2: Color) -> void:
	var group := Node2D.new()
	group.position = pos
	group.z_index = -1
	# Base
	_add_rect(group, Vector2(-18 * _sx, -10 * _sy), Vector2(36 * _sx, 20 * _sy), color1.lightened(0.2))
	# Stripes
	for i in range(4):
		var sy_off := -8 * _sy + i * 5 * _sy
		var sc := color2 if i % 2 == 0 else color1
		_add_rect(group, Vector2(-16 * _sx, sy_off), Vector2(32 * _sx, 3 * _sy), sc.lightened(0.1))
	# Fringe
	_add_rect(group, Vector2(-20 * _sx, -10 * _sy), Vector2(40 * _sx, 2 * _sy), color2.darkened(0.1))
	_add_rect(group, Vector2(-20 * _sx, 8 * _sy), Vector2(40 * _sx, 2 * _sy), color2.darkened(0.1))
	root.add_child(group)


## Musician NPC with music note particles
func _add_musician_npc(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 2 * _sy), 10 * _sx, 3 * _sy))
	# Body
	_add_rect(group, Vector2(-5 * _sx, -22 * _sy), Vector2(10 * _sx, 16 * _sy), Color("#C07B3A"))
	# Head
	group.add_child(_make_circle_panel(Vector2(-5 * _sx, -32 * _sy), 10 * _sx, Color("#F5CBA7")))
	# Instrument (lute shape)
	group.add_child(_make_circle_panel(Vector2(4 * _sx, -18 * _sy), 10 * _sx, Color("#8B5E3C")))
	_add_rect(group, Vector2(12 * _sx, -24 * _sy), Vector2(3 * _sx, 14 * _sy), Color("#4A2E0C"))
	# Sway animation
	var tw := group.create_tween().set_loops()
	tw.tween_property(group, "position:x", pos.x + 3 * _sx, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(group, "position:x", pos.x - 3 * _sx, 1.0).set_trans(Tween.TRANS_SINE)
	root.add_child(group)


## Basket prop
func _add_basket_prop(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Basket body
	group.add_child(_make_circle_panel(Vector2(-8 * _sx, -8 * _sy), 16 * _sx, Color("#8B7355")))
	# Cross-hatch lines
	_add_rect(group, Vector2(-6 * _sx, -4 * _sy), Vector2(12 * _sx, 1 * _sy), Color("#6B5335"))
	_add_rect(group, Vector2(-6 * _sx, 0), Vector2(12 * _sx, 1 * _sy), Color("#6B5335"))
	# Contents (dots)
	var item_colors := [Color("#E94560"), Color("#3E8948"), Color("#E8C547")]
	for i in range(3):
		group.add_child(_make_circle_panel(Vector2((-5 + i * 4) * _sx, -10 * _sy), 4 * _sx, item_colors[i]))
	root.add_child(group)


## Torch post (post + cup, no fire particles)
func _add_torch_post(root: Node2D, pos: Vector2) -> void:
	var group := Node2D.new()
	group.position = pos
	# Post
	_add_rect(group, Vector2(-2 * _sx, -40 * _sy), Vector2(4 * _sx, 42 * _sy), Color("#5C3D11"))
	# Torch cup
	_add_rect(group, Vector2(-5 * _sx, -44 * _sy), Vector2(10 * _sx, 6 * _sy), Color("#4A2E0C"))
	root.add_child(group)


# ═════════════════════════════════════════════════════════════════════════════
# NPC HELPERS
# ═════════════════════════════════════════════════════════════════════════════

## Idle NPC — uses player sprite, slightly smaller, with tint for variety
func _add_idle_npc(_root: Node2D, pos: Vector2, tint: Color = Color(1, 1, 1), use_female: bool = false) -> void:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 1 * _sy), 9 * _sx, 3 * _sy))
	var spr := Sprite2D.new()
	var tex_path := "res://assets/sprites/character/player_female.png" if use_female \
					else "res://assets/sprites/character/player.png"
	if ResourceLoader.exists(tex_path):
		spr.texture = load(tex_path)
		var ts := spr.texture.get_size()
		spr.scale = Vector2(36.0 * _sx / ts.x, 54.0 * _sy / ts.y)
	spr.position = Vector2(0, -27 * _sy)
	spr.modulate = tint
	group.add_child(spr)
	var tw := group.create_tween().set_loops()
	tw.tween_property(group, "position:y", pos.y - 2 * _sy, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(group, "position:y", pos.y, 1.4).set_trans(Tween.TRANS_SINE)
	var parent := _ysort_ref if is_instance_valid(_ysort_ref) else _root
	parent.add_child(group)


## Walking NPC — sprite-based, caller drives movement with _start_npc_walk
func _add_walking_npc(_root: Node2D, pos: Vector2, tint: Color = Color(1, 1, 1), use_female: bool = false) -> Node2D:
	var group := Node2D.new()
	group.position = pos
	group.add_child(_make_oval_shadow(Vector2(0, 1 * _sy), 9 * _sx, 3 * _sy))
	var spr := Sprite2D.new()
	var tex_path := "res://assets/sprites/character/player_female.png" if use_female \
					else "res://assets/sprites/character/player.png"
	if ResourceLoader.exists(tex_path):
		spr.texture = load(tex_path)
		var ts := spr.texture.get_size()
		spr.scale = Vector2(36.0 * _sx / ts.x, 54.0 * _sy / ts.y)
	spr.position = Vector2(0, -27 * _sy)
	spr.modulate = tint
	group.add_child(spr)
	var parent := _ysort_ref if is_instance_valid(_ysort_ref) else _root
	parent.add_child(group)
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
# SHARED PRIMITIVE HELPERS
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
