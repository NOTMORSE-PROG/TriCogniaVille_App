extends Control
## ProfilePanel — Village Settings modal.
## Fully procedural layout. No @onready bindings — everything built in _build_layout().

signal dismissed

# ── Display Constants ─────────────────────────────────────────────────────────

const CATEGORY_ORDER: Array[String] = ["building", "quest", "xp", "streak", "level"]
const CATEGORY_LABELS: Dictionary = {
	"building": "Buildings",
	"quest":    "Quests",
	"xp":       "XP Milestones",
	"streak":   "Streaks",
	"level":    "Reading Levels",
}

const BUILDING_ORDER: Array[String] = [
	"town_hall", "school", "inn", "chapel", "library", "well", "market", "bakery"
]
const BUILDING_INFO: Dictionary = {
	"town_hall": {"name": "Town Hall", "icon": "🏛"},
	"school":    {"name": "School",    "icon": "🏫"},
	"inn":       {"name": "Inn",       "icon": "🏠"},
	"chapel":    {"name": "Chapel",    "icon": "⛪"},
	"library":   {"name": "Library",   "icon": "📚"},
	"well":      {"name": "Well",      "icon": "💧"},
	"market":    {"name": "Market",    "icon": "🛒"},
	"bakery":    {"name": "Bakery",    "icon": "🍞"},
}

# Reading tier display (read-only; maps reading level → tier index)
const TIER_LABELS: Array[String] = ["Beginner", "Intermediate", "Advanced"]
const TIER_COLORS: Array[Color]   = [
	Color(0.357, 0.851, 0.635),  # Beginner      → SUCCESS_GREEN
	Color(0.886, 0.725, 0.290),  # Intermediate  → GOLD
	Color(0.914, 0.388, 0.431),  # Advanced      → ACCENT_CORAL
]

const CREDITS: Array[Dictionary] = [
	{"role": "Project Lead",    "name": "Anjanette Masaño"},
	{"role": "Lead Developer",  "name": "Harrison Reyes"},
	{"role": "Researcher",      "name": "Cris Bapista"},
	{"role": "Researcher",      "name": "Maicela Salvador"},
	{"role": "Art & UI/UX",     "name": "Mark L."},
	{"role": "Sound Design",    "name": "Echo Studio"},
	{"role": "Graphic Design",  "name": "Bluepeak Creatives"},
]

# ── State ─────────────────────────────────────────────────────────────────────

var _sx: float = 1.0
var _sy: float = 1.0
var _transitioning: bool = false
var _can_dismiss: bool = false

var _avatar_color: Color = StyleFactory.AVATAR_COLORS[0]
var _frame_color:  Color = StyleFactory.FRAME_BRONZE
var _initials:     String = "?"
var _level_num:    int = 1

var _dot_timer: Timer
var _dot_count: int = 0

# ── Node References (all built procedurally) ──────────────────────────────────

var _blocker:          ColorRect
var _panel:            PanelContainer
var _loading_section:  CenterContainer
var _loading_lbl:      Label
var _settings_content: VBoxContainer

# Player card
var _avatar_ctrl: Control
var _name_lbl:    Label
var _level_pill:  PanelContainer
var _level_lbl:   Label

# Sound card
var _music_btn: Button
var _sfx_btn:   Button

# Learning card (read-only reading level display)
var _level_big_lbl: Label   # Large level number
var _tier_name_lbl: Label   # "Beginner" / "Intermediate" / "Advanced"

# Buildings section
var _buildings_grid: GridContainer

# Badges section
var _badges_count_lbl: Label
var _badges_box:       VBoxContainer

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_build_layout()


func setup(sx: float, sy: float) -> void:
	_sx = sx
	_sy = sy
	if is_node_ready():
		_apply_scale()


func _apply_scale() -> void:
	if not is_instance_valid(_panel):
		return
	var vp := get_viewport().get_visible_rect().size
	var card_w := vp.x * 0.92
	var card_h := vp.y * 0.90
	_panel.offset_left   = -card_w * 0.5
	_panel.offset_right  =  card_w * 0.5
	_panel.offset_top    = -card_h * 0.5
	_panel.offset_bottom =  card_h * 0.5


# =============================================================================
# LAYOUT BUILDER
# =============================================================================


func _build_layout() -> void:
	# ── Blocker (dim overlay) ──────────────────────────────────────────────────
	_blocker = ColorRect.new()
	_blocker.anchor_right  = 1.0
	_blocker.anchor_bottom = 1.0
	_blocker.color        = Color(0, 0, 0, 0.62)
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.gui_input.connect(_on_blocker_input)
	add_child(_blocker)

	# ── Card panel ─────────────────────────────────────────────────────────────
	_panel = PanelContainer.new()
	_panel.anchor_left   = 0.5
	_panel.anchor_top    = 0.5
	_panel.anchor_right  = 0.5
	_panel.anchor_bottom = 0.5
	_panel.mouse_filter  = Control.MOUSE_FILTER_PASS
	_panel.add_theme_stylebox_override("panel", _make_card_style())
	_apply_scale()
	add_child(_panel)

	# ── Outer vbox (no gap — title bar clips to card corners) ─────────────────
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 0)
	_panel.add_child(outer)

	# Title bar
	outer.add_child(_build_title_bar())

	# Content area (margin + scroll)
	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left",   int(22 * _sx))
	margin.add_theme_constant_override("margin_right",  int(22 * _sx))
	margin.add_theme_constant_override("margin_top",    int(18 * _sy))
	margin.add_theme_constant_override("margin_bottom", int(18 * _sy))
	outer.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter           = Control.MOUSE_FILTER_PASS
	margin.add_child(scroll)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", int(16 * _sy))
	content_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(content_vbox)

	# Loading section
	_loading_section = CenterContainer.new()
	_loading_section.custom_minimum_size = Vector2(0, int(220 * _sy))
	_loading_section.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(_loading_section)

	_loading_lbl = Label.new()
	_loading_lbl.text = "Loading profile..."
	_loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_lbl.add_theme_font_size_override("font_size", int(24 * _sy))
	_loading_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	_loading_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_section.add_child(_loading_lbl)

	# Settings content (visible only after data arrives)
	_settings_content = VBoxContainer.new()
	_settings_content.visible = false
	_settings_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_content.add_theme_constant_override("separation", int(14 * _sy))
	_settings_content.mouse_filter = Control.MOUSE_FILTER_PASS
	content_vbox.add_child(_settings_content)

	# ── Sections ───────────────────────────────────────────────────────────────
	_settings_content.add_child(_build_top_row())
	_settings_content.add_child(_build_buildings_section())
	_settings_content.add_child(_build_badges_section())
	_settings_content.add_child(_build_credits_section())
	_settings_content.add_child(_build_logout_row())

	# Bottom spacer
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, int(10 * _sy))
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_content.add_child(pad)


# ── Card panel style ──────────────────────────────────────────────────────────


func _make_card_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(StyleFactory.BG_CARD.r, StyleFactory.BG_CARD.g, StyleFactory.BG_CARD.b, 0.98)
	s.corner_radius_top_left     = 22
	s.corner_radius_top_right    = 22
	s.corner_radius_bottom_left  = 22
	s.corner_radius_bottom_right = 22
	s.border_width_top    = 2
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	s.border_color  = Color(StyleFactory.GOLD.r, StyleFactory.GOLD.g, StyleFactory.GOLD.b, 0.45)
	s.shadow_color  = Color(0, 0, 0, 0.55)
	s.shadow_size   = 28
	s.shadow_offset = Vector2(0, 10)
	s.content_margin_left   = 0.0
	s.content_margin_right  = 0.0
	s.content_margin_top    = 0.0
	s.content_margin_bottom = 0.0
	s.anti_aliasing = true
	return s


# =============================================================================
# TITLE BAR
# =============================================================================


func _build_title_bar() -> Control:
	var bar := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(
		StyleFactory.BG_DEEP.r * 0.85,
		StyleFactory.BG_DEEP.g * 0.85,
		StyleFactory.BG_DEEP.b * 0.95
	)
	bs.corner_radius_top_left  = 22
	bs.corner_radius_top_right = 22
	bs.border_width_bottom = 2
	bs.border_color        = Color(StyleFactory.GOLD.r, StyleFactory.GOLD.g, StyleFactory.GOLD.b, 0.55)
	bs.content_margin_left   = int(20 * _sx)
	bs.content_margin_right  = int(20 * _sx)
	bs.content_margin_top    = int(15 * _sy)
	bs.content_margin_bottom = int(15 * _sy)
	bar.add_theme_stylebox_override("panel", bs)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(10 * _sx))
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	bar.add_child(row)

	# Gear icon
	var gear := Label.new()
	gear.text = "⚙"
	gear.add_theme_font_size_override("font_size", int(24 * _sy))
	gear.add_theme_color_override("font_color", StyleFactory.GOLD)
	gear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gear)

	# Title text
	var title := Label.new()
	title.text = "VILLAGE SETTINGS"
	title.add_theme_font_size_override("font_size", int(24 * _sy))
	title.add_theme_color_override("font_color", StyleFactory.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title)

	# Close button
	var close_btn := CloseButton.new()
	close_btn.setup(int(50 * _sy))
	close_btn.pressed.connect(func() -> void: hide_profile())
	row.add_child(close_btn)

	return bar


# =============================================================================
# TOP ROW: Sound | Player | Learning
# =============================================================================


func _build_top_row() -> Control:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", int(12 * _sx))
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS

	hbox.add_child(_build_sound_card())
	hbox.add_child(_build_player_card())
	hbox.add_child(_build_learning_card())

	return hbox


# ── SOUND CARD ────────────────────────────────────────────────────────────────


func _build_sound_card() -> Control:
	var card := _make_section_card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(12 * _sy))
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(vbox)

	vbox.add_child(_make_section_header("SOUND", "🔊"))
	vbox.add_child(_make_separator())

	# Music row
	var music_row := _build_toggle_row("🎵  Music")
	_music_btn = music_row.get_meta("btn") as Button
	_music_btn.button_pressed = AudioManager.music_enabled
	_music_btn.text = "ON" if AudioManager.music_enabled else "OFF"
	_style_toggle(_music_btn, AudioManager.music_enabled)
	_music_btn.toggled.connect(_on_music_toggled)
	vbox.add_child(music_row)

	# SFX row
	var sfx_row := _build_toggle_row("🔔  Sound FX")
	_sfx_btn = sfx_row.get_meta("btn") as Button
	_sfx_btn.button_pressed = AudioManager.sfx_enabled
	_sfx_btn.text = "ON" if AudioManager.sfx_enabled else "OFF"
	_style_toggle(_sfx_btn, AudioManager.sfx_enabled)
	_sfx_btn.toggled.connect(_on_sfx_toggled)
	vbox.add_child(sfx_row)

	return card


func _build_toggle_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(8 * _sx))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", int(18 * _sy))
	lbl.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)

	var btn := Button.new()
	btn.toggle_mode = true
	btn.text = "ON"
	btn.custom_minimum_size = Vector2(int(62 * _sx), int(36 * _sy))
	btn.add_theme_font_size_override("font_size", int(15 * _sy))
	btn.toggled.connect(func(on: bool) -> void:
		btn.text = "ON" if on else "OFF"
		_style_toggle(btn, on)
	)
	row.add_child(btn)
	row.set_meta("btn", btn)

	UIAnimations.make_interactive(btn)
	return row


func _style_toggle(btn: Button, on: bool) -> void:
	var accent := StyleFactory.SUCCESS_GREEN
	var n := StyleBoxFlat.new()
	n.bg_color    = Color(accent.r, accent.g, accent.b, 0.25) if on else Color(0.08, 0.12, 0.22, 1.0)
	n.set_corner_radius_all(8)
	n.border_width_top    = 2
	n.border_width_left   = 2
	n.border_width_right  = 2
	n.border_width_bottom = 2
	n.border_color = Color(accent.r, accent.g, accent.b, 0.8) if on else Color(0.28, 0.36, 0.50, 0.6)
	n.content_margin_top    = int(4 * _sy)
	n.content_margin_bottom = int(4 * _sy)
	n.anti_aliasing = true
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color    = Color(accent.r, accent.g, accent.b, 0.38) if on else Color(0.11, 0.17, 0.30, 1.0)
	h.border_color = Color(accent.r, accent.g, accent.b, 1.0)
	btn.add_theme_stylebox_override("normal",  n)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", n)
	btn.add_theme_color_override("font_color", Color.WHITE if on else StyleFactory.TEXT_MUTED)


# ── PLAYER CARD ───────────────────────────────────────────────────────────────


func _build_player_card() -> Control:
	var card := _make_section_card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(10 * _sy))
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(vbox)

	vbox.add_child(_make_section_header("PLAYER", "👤"))
	vbox.add_child(_make_separator())

	# Avatar
	var avatar_center := CenterContainer.new()
	avatar_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(avatar_center)

	_avatar_ctrl = Control.new()
	_avatar_ctrl.custom_minimum_size = Vector2(int(108 * _sx), int(108 * _sy))
	_avatar_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_ctrl.draw.connect(_draw_avatar)
	avatar_center.add_child(_avatar_ctrl)

	# Player name
	_name_lbl = Label.new()
	_name_lbl.text = GameManager.current_student.get("name", "Player")
	_name_lbl.add_theme_font_size_override("font_size", int(24 * _sy))
	_name_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_name_lbl)

	# Level pill
	var pill_center := CenterContainer.new()
	pill_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(pill_center)

	_level_pill = PanelContainer.new()
	_level_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill_s := StyleBoxFlat.new()
	pill_s.bg_color = StyleFactory.FRAME_BRONZE
	pill_s.set_corner_radius_all(12)
	pill_s.content_margin_left   = int(14 * _sx)
	pill_s.content_margin_right  = int(14 * _sx)
	pill_s.content_margin_top    = int(4 * _sy)
	pill_s.content_margin_bottom = int(4 * _sy)
	_level_pill.add_theme_stylebox_override("panel", pill_s)
	pill_center.add_child(_level_pill)

	_level_lbl = Label.new()
	_level_lbl.text = "Lv. 1"
	_level_lbl.add_theme_font_size_override("font_size", int(17 * _sy))
	_level_lbl.add_theme_color_override("font_color", StyleFactory.BG_DEEP)
	_level_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_pill.add_child(_level_lbl)

	return card


# ── LEARNING CARD (read-only reading level display) ───────────────────────────


func _build_learning_card() -> Control:
	var card := _make_section_card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(10 * _sy))
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	vbox.add_child(_make_section_header("LEARNING", "🎓"))
	vbox.add_child(_make_separator())

	var sub := Label.new()
	sub.text = "Reading Level"
	sub.add_theme_font_size_override("font_size", int(16 * _sy))
	sub.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub)

	# Big level number badge
	var badge_center := CenterContainer.new()
	badge_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(badge_center)

	var badge_panel := PanelContainer.new()
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bp_s := StyleBoxFlat.new()
	bp_s.bg_color = Color(StyleFactory.BG_DEEP.r, StyleFactory.BG_DEEP.g, StyleFactory.BG_DEEP.b, 0.8)
	bp_s.set_corner_radius_all(16)
	bp_s.border_width_top    = 2
	bp_s.border_width_left   = 2
	bp_s.border_width_right  = 2
	bp_s.border_width_bottom = 2
	bp_s.border_color  = Color(StyleFactory.GOLD.r, StyleFactory.GOLD.g, StyleFactory.GOLD.b, 0.5)
	bp_s.content_margin_left   = int(18 * _sx)
	bp_s.content_margin_right  = int(18 * _sx)
	bp_s.content_margin_top    = int(10 * _sy)
	bp_s.content_margin_bottom = int(10 * _sy)
	bp_s.anti_aliasing = true
	badge_panel.add_theme_stylebox_override("panel", bp_s)
	badge_center.add_child(badge_panel)

	var badge_col := VBoxContainer.new()
	badge_col.add_theme_constant_override("separation", int(2 * _sy))
	badge_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_panel.add_child(badge_col)

	_level_big_lbl = Label.new()
	_level_big_lbl.text = "—"
	_level_big_lbl.add_theme_font_size_override("font_size", int(38 * _sy))
	_level_big_lbl.add_theme_color_override("font_color", StyleFactory.GOLD)
	_level_big_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_big_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_col.add_child(_level_big_lbl)

	_tier_name_lbl = Label.new()
	_tier_name_lbl.text = ""
	_tier_name_lbl.add_theme_font_size_override("font_size", int(15 * _sy))
	_tier_name_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	_tier_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tier_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_col.add_child(_tier_name_lbl)

	return card


# =============================================================================
# BUILDINGS UNLOCKED SECTION
# =============================================================================


func _build_buildings_section() -> Control:
	var card := _make_section_card()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(14 * _sy))
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(vbox)

	# Header row: title + live count
	var hrow := HBoxContainer.new()
	hrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hrow)

	hrow.add_child(_make_section_header("BUILDINGS UNLOCKED", "🏘"))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hrow.add_child(spacer)

	var unlocked: Array = _get_unlocked()
	var count_lbl := Label.new()
	count_lbl.text = "%d / %d" % [unlocked.size(), BUILDING_ORDER.size()]
	count_lbl.add_theme_font_size_override("font_size", int(18 * _sy))
	count_lbl.add_theme_color_override(
		"font_color",
		StyleFactory.SUCCESS_GREEN if unlocked.size() == BUILDING_ORDER.size() else StyleFactory.GOLD
	)
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hrow.add_child(count_lbl)

	vbox.add_child(_make_separator())

	# 4-column building grid
	_buildings_grid = GridContainer.new()
	_buildings_grid.columns = 4
	_buildings_grid.add_theme_constant_override("h_separation", int(10 * _sx))
	_buildings_grid.add_theme_constant_override("v_separation", int(10 * _sy))
	_buildings_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buildings_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_buildings_grid)

	_populate_buildings()

	return card


func _populate_buildings() -> void:
	if not is_instance_valid(_buildings_grid):
		return
	for c in _buildings_grid.get_children():
		c.queue_free()

	var unlocked := _get_unlocked()
	for bid in BUILDING_ORDER:
		var info: Dictionary = BUILDING_INFO.get(bid, {"name": bid.capitalize(), "icon": "🏠"})
		_buildings_grid.add_child(_make_building_tile(info, unlocked.has(bid)))


func _make_building_tile(info: Dictionary, is_unlocked: bool) -> Control:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(0, int(88 * _sy))
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ts := StyleBoxFlat.new()
	ts.set_corner_radius_all(10)
	ts.content_margin_left   = int(4 * _sx)
	ts.content_margin_right  = int(4 * _sx)
	ts.content_margin_top    = int(8 * _sy)
	ts.content_margin_bottom = int(6 * _sy)
	ts.anti_aliasing = true

	if is_unlocked:
		ts.bg_color     = Color(0.10, 0.19, 0.34, 0.92)
		ts.border_width_top    = 2
		ts.border_width_left   = 2
		ts.border_width_right  = 2
		ts.border_width_bottom = 2
		ts.border_color  = Color(
			StyleFactory.SUCCESS_GREEN.r, StyleFactory.SUCCESS_GREEN.g,
			StyleFactory.SUCCESS_GREEN.b, 0.55
		)
		ts.shadow_color  = Color(
			StyleFactory.SUCCESS_GREEN.r, StyleFactory.SUCCESS_GREEN.g,
			StyleFactory.SUCCESS_GREEN.b, 0.15
		)
		ts.shadow_size   = 5
		ts.shadow_offset = Vector2(0, 2)
	else:
		ts.bg_color  = Color(0.06, 0.08, 0.14, 0.55)
		tile.modulate = Color(1, 1, 1, 0.42)

	tile.add_theme_stylebox_override("panel", ts)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", int(3 * _sy))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(col)

	var icon_lbl := Label.new()
	icon_lbl.text = info.get("icon", "?") if is_unlocked else "🔒"
	icon_lbl.add_theme_font_size_override("font_size", int(30 * _sy))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = info.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", int(13 * _sy))
	name_lbl.add_theme_color_override(
		"font_color",
		StyleFactory.TEXT_SECONDARY if is_unlocked else StyleFactory.TEXT_MUTED
	)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(name_lbl)

	if is_unlocked:
		var check := Label.new()
		check.text = "✓"
		check.add_theme_font_size_override("font_size", int(13 * _sy))
		check.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
		check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(check)

	return tile


# =============================================================================
# BADGES SECTION
# =============================================================================


func _build_badges_section() -> Control:
	var card := _make_section_card()

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", int(12 * _sy))
	outer_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(outer_vbox)

	# Header row: title + count
	var hrow := HBoxContainer.new()
	hrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_vbox.add_child(hrow)

	hrow.add_child(_make_section_header("BADGE COLLECTION", "🏆"))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hrow.add_child(spacer)

	_badges_count_lbl = Label.new()
	_badges_count_lbl.text = "—"
	_badges_count_lbl.add_theme_font_size_override("font_size", int(18 * _sy))
	_badges_count_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_badges_count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hrow.add_child(_badges_count_lbl)

	outer_vbox.add_child(_make_separator())

	_badges_box = VBoxContainer.new()
	_badges_box.add_theme_constant_override("separation", int(10 * _sy))
	_badges_box.mouse_filter = Control.MOUSE_FILTER_PASS
	outer_vbox.add_child(_badges_box)

	return card


func _populate_badges(badges: Array) -> void:
	for child in _badges_box.get_children():
		child.queue_free()

	var earned := badges.filter(func(b): return b.get("earned", false)).size()
	_badges_count_lbl.text = "%d / %d earned" % [earned, badges.size()]
	_badges_count_lbl.add_theme_color_override(
		"font_color",
		StyleFactory.GOLD if earned > 0 else StyleFactory.TEXT_MUTED
	)

	var groups: Dictionary = {}
	for cat in CATEGORY_ORDER:
		groups[cat] = []
	for b in badges:
		var cat: String = b.get("category", "other")
		if groups.has(cat):
			groups[cat].append(b)

	for cat in CATEGORY_ORDER:
		var cat_badges: Array = groups.get(cat, [])
		if cat_badges.is_empty():
			continue

		var cat_vbox := VBoxContainer.new()
		cat_vbox.add_theme_constant_override("separation", int(6 * _sy))
		cat_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_badges_box.add_child(cat_vbox)

		var cat_lbl := Label.new()
		cat_lbl.text = CATEGORY_LABELS.get(cat, cat.capitalize())
		cat_lbl.add_theme_font_size_override("font_size", int(18 * _sy))
		cat_lbl.add_theme_color_override("font_color", _get_category_color(cat))
		cat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cat_vbox.add_child(cat_lbl)

		var grid := GridContainer.new()
		grid.columns = 5
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", int(10 * _sx))
		grid.add_theme_constant_override("v_separation", int(10 * _sy))
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cat_vbox.add_child(grid)

		for badge in cat_badges:
			grid.add_child(_make_badge_tile(badge, cat))


func _make_badge_tile(badge: Dictionary, category: String) -> PanelContainer:
	var is_earned: bool = badge.get("earned", false)
	var tile_h := int(118 * _sy)

	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(0, tile_h)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ts := StyleBoxFlat.new()
	ts.set_corner_radius_all(10)
	ts.content_margin_left   = int(4 * _sx)
	ts.content_margin_right  = int(4 * _sx)
	ts.content_margin_top    = int(6 * _sy)
	ts.content_margin_bottom = int(4 * _sy)
	ts.anti_aliasing = true

	if is_earned:
		ts.bg_color = Color(
			StyleFactory.BG_SURFACE.r, StyleFactory.BG_SURFACE.g, StyleFactory.BG_SURFACE.b, 0.9
		)
		var accent := _get_category_color(category)
		ts.border_width_top    = 2
		ts.border_width_left   = 2
		ts.border_width_right  = 2
		ts.border_width_bottom = 2
		ts.border_color  = Color(accent.r, accent.g, accent.b, 0.6)
		ts.shadow_color  = Color(accent.r, accent.g, accent.b, 0.2)
		ts.shadow_size   = 4
		ts.shadow_offset = Vector2(0, 2)
	else:
		ts.bg_color   = Color(0.06, 0.08, 0.14, 0.6)
		tile.modulate = Color(1, 1, 1, 0.40)

	tile.add_theme_stylebox_override("panel", ts)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(3 * _sy))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(col)

	var icon_lbl := Label.new()
	icon_lbl.text = badge.get("icon", "?") if is_earned else "🔒"
	icon_lbl.add_theme_font_size_override("font_size", int(34 * _sy))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = badge.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", int(14 * _sy))
	name_lbl.add_theme_color_override(
		"font_color",
		StyleFactory.TEXT_SECONDARY if is_earned else StyleFactory.TEXT_MUTED
	)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(name_lbl)

	return tile


# =============================================================================
# CREDITS SECTION
# =============================================================================


func _build_credits_section() -> Control:
	var card := _make_section_card()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(14 * _sy))
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(vbox)

	vbox.add_child(_make_section_header("CREDITS", "✨"))
	vbox.add_child(_make_separator())

	# 4-column grid of credit tiles (fills panel width)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", int(10 * _sx))
	grid.add_theme_constant_override("v_separation", int(10 * _sy))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(grid)

	for credit in CREDITS:
		grid.add_child(_make_credit_tile(credit.get("role", ""), credit.get("name", "")))

	return card


func _make_credit_tile(role: String, person_name: String) -> Control:
	var tile := PanelContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0.07, 0.10, 0.20, 0.88)
	ts.set_corner_radius_all(10)
	ts.border_width_top    = 1
	ts.border_width_left   = 1
	ts.border_width_right  = 1
	ts.border_width_bottom = 1
	ts.border_color = Color(StyleFactory.GOLD.r, StyleFactory.GOLD.g, StyleFactory.GOLD.b, 0.30)
	ts.content_margin_left   = int(14 * _sx)
	ts.content_margin_right  = int(14 * _sx)
	ts.content_margin_top    = int(10 * _sy)
	ts.content_margin_bottom = int(10 * _sy)
	ts.anti_aliasing = true
	tile.add_theme_stylebox_override("panel", ts)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(2 * _sy))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(col)

	var role_lbl := Label.new()
	role_lbl.text = role
	role_lbl.add_theme_font_size_override("font_size", int(13 * _sy))
	role_lbl.add_theme_color_override("font_color", StyleFactory.GOLD)
	role_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(role_lbl)

	var name_lbl := Label.new()
	name_lbl.text = person_name
	name_lbl.add_theme_font_size_override("font_size", int(17 * _sy))
	name_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(name_lbl)

	return tile


# =============================================================================
# LOGOUT ROW
# =============================================================================


func _build_logout_row() -> Control:
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_PASS

	var btn := Button.new()
	btn.text = "Sign Out"
	btn.custom_minimum_size = Vector2(int(220 * _sx), int(60 * _sy))
	btn.add_theme_font_size_override("font_size", int(20 * _sy))
	btn.add_theme_color_override("font_color", StyleFactory.TEXT_ERROR)

	var n := StyleFactory.make_secondary_button_normal()
	var h := StyleFactory.make_secondary_button_hover()
	n.border_color = Color(
		StyleFactory.TEXT_ERROR.r, StyleFactory.TEXT_ERROR.g, StyleFactory.TEXT_ERROR.b, 0.4
	)
	h.border_color = Color(
		StyleFactory.TEXT_ERROR.r, StyleFactory.TEXT_ERROR.g, StyleFactory.TEXT_ERROR.b, 0.7
	)
	h.bg_color = Color(
		StyleFactory.TEXT_ERROR.r, StyleFactory.TEXT_ERROR.g, StyleFactory.TEXT_ERROR.b, 0.06
	)
	btn.add_theme_stylebox_override("normal",  n)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	btn.pressed.connect(_on_logout_pressed)
	UIAnimations.make_interactive(btn)
	center.add_child(btn)

	return center


# =============================================================================
# SHARED HELPERS
# =============================================================================


func _make_section_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var s := StyleBoxFlat.new()
	s.bg_color = Color(
		StyleFactory.BG_SURFACE.r, StyleFactory.BG_SURFACE.g, StyleFactory.BG_SURFACE.b, 0.82
	)
	s.set_corner_radius_all(14)
	s.border_width_left = 3
	s.border_color = Color(StyleFactory.GOLD.r, StyleFactory.GOLD.g, StyleFactory.GOLD.b, 0.45)
	s.shadow_color  = Color(0, 0, 0, 0.20)
	s.shadow_size   = 6
	s.shadow_offset = Vector2(0, 3)
	s.content_margin_left   = int(16 * _sx)
	s.content_margin_right  = int(16 * _sx)
	s.content_margin_top    = int(14 * _sy)
	s.content_margin_bottom = int(14 * _sy)
	s.anti_aliasing = true
	card.add_theme_stylebox_override("panel", s)
	return card


func _make_section_header(title_text: String, icon: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(8 * _sx))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", int(18 * _sy))
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_lbl)

	var t := Label.new()
	t.text = title_text
	t.add_theme_font_size_override("font_size", int(19 * _sy))
	t.add_theme_color_override("font_color", StyleFactory.GOLD)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(t)

	return row


func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ss := StyleBoxFlat.new()
	ss.bg_color           = Color(StyleFactory.GOLD.r, StyleFactory.GOLD.g, StyleFactory.GOLD.b, 0.22)
	ss.content_margin_top    = 0.0
	ss.content_margin_bottom = 0.0
	sep.add_theme_stylebox_override("separator", ss)
	return sep


func _get_unlocked() -> Array:
	var raw = GameManager.get("unlocked_buildings")
	return raw if raw is Array else []


# =============================================================================
# SHOW / HIDE
# =============================================================================


func show_profile() -> void:
	if _transitioning or visible:
		return
	_can_dismiss = false
	_apply_scale()
	_reset_content()
	_populate_buildings()  # Refresh — buildings may have changed since last open
	modulate.a = 0.0
	visible = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	tw.finished.connect(func() -> void: _can_dismiss = true)
	_start_loading_dots()
	ApiClient.get_profile(_on_profile_loaded)


func hide_profile() -> void:
	if not visible or _transitioning:
		return
	_transitioning = true
	_stop_loading_dots()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	await tw.finished
	visible = false
	modulate.a = 1.0
	_transitioning = false
	dismissed.emit()


func _reset_content() -> void:
	_loading_section.visible = true
	_settings_content.visible = false
	if is_instance_valid(_badges_box):
		for child in _badges_box.get_children():
			child.queue_free()
	if is_instance_valid(_badges_count_lbl):
		_badges_count_lbl.text = "—"


# =============================================================================
# LOADING DOTS
# =============================================================================


func _start_loading_dots() -> void:
	_dot_count = 0
	_loading_lbl.text = "Loading profile..."
	_dot_timer = Timer.new()
	_dot_timer.wait_time = 0.4
	_dot_timer.timeout.connect(
		func() -> void:
			_dot_count = (_dot_count + 1) % 4
			_loading_lbl.text = "Loading profile" + ".".repeat(_dot_count)
	)
	add_child(_dot_timer)
	_dot_timer.start()


func _stop_loading_dots() -> void:
	if is_instance_valid(_dot_timer):
		_dot_timer.stop()
		_dot_timer.queue_free()
		_dot_timer = null


# =============================================================================
# DATA CALLBACKS
# =============================================================================


func _on_profile_loaded(success: bool, data: Dictionary) -> void:
	_stop_loading_dots()
	if not visible:
		return

	if not success:
		_show_error_state()
		return

	_populate_header(data)
	_populate_badges(data.get("badges", []))

	_loading_section.visible = false
	_settings_content.visible = true

	await get_tree().process_frame
	if is_instance_valid(_settings_content):
		UIAnimations.stagger_children(self, _settings_content, 0.04)


func _populate_header(data: Dictionary) -> void:
	var player_name: String = data.get("name", GameManager.current_student.get("name", "Player"))
	var level_data: Dictionary = data.get("level", {})
	_level_num = level_data.get(
		"level",
		data.get("readingLevel", GameManager.current_student.get("reading_level", 1))
	)

	_avatar_color = StyleFactory.AVATAR_COLORS[absi(player_name.hash()) % StyleFactory.AVATAR_COLORS.size()]
	_frame_color  = StyleFactory.get_level_frame_color(_level_num)
	_initials     = _get_initials(player_name)

	# Refresh avatar
	_avatar_ctrl.queue_redraw()
	_avatar_ctrl.pivot_offset = _avatar_ctrl.size * 0.5
	var tw := _avatar_ctrl.create_tween()
	tw.tween_property(_avatar_ctrl, "scale", Vector2(1.06, 1.06), 0.14).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	tw.tween_property(_avatar_ctrl, "scale", Vector2.ONE, 0.14).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN)

	# Level pill tint
	var pill_s := _level_pill.get_theme_stylebox("panel") as StyleBoxFlat
	if pill_s:
		pill_s.bg_color = _frame_color
		_level_pill.add_theme_stylebox_override("panel", pill_s)

	_name_lbl.text = player_name
	_level_lbl.text = "Lv. %d" % _level_num
	_level_lbl.add_theme_color_override("font_color", StyleFactory.BG_DEEP)

	# Update reading level display in the Learning card
	_update_reading_level_display()


func _update_reading_level_display() -> void:
	if not is_instance_valid(_level_big_lbl):
		return
	# Map reading level → tier index (0=Beginner, 1=Intermediate, 2=Advanced)
	var tier: int = 0
	if _level_num >= 5:
		tier = 2
	elif _level_num >= 3:
		tier = 1
	else:
		tier = 0

	_level_big_lbl.text = str(_level_num)
	_level_big_lbl.add_theme_color_override("font_color", TIER_COLORS[tier])
	_tier_name_lbl.text = TIER_LABELS[tier]
	_tier_name_lbl.add_theme_color_override("font_color", TIER_COLORS[tier])



# =============================================================================
# ERROR STATE
# =============================================================================


func _show_error_state() -> void:
	var student := GameManager.current_student
	if not student.is_empty():
		_populate_header({
			"name": student.get("name", "Student"),
			"readingLevel": student.get("reading_level", 1),
			"level": {"level": student.get("reading_level", 1)},
		})

	if is_instance_valid(_badges_box):
		var err_vbox := VBoxContainer.new()
		err_vbox.add_theme_constant_override("separation", int(10 * _sy))
		err_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_badges_box.add_child(err_vbox)

		var err_lbl := Label.new()
		err_lbl.text = "Could not load full profile"
		err_lbl.add_theme_font_size_override("font_size", int(20 * _sy))
		err_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_ERROR)
		err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		err_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		err_vbox.add_child(err_lbl)

		var hint_lbl := Label.new()
		hint_lbl.text = "Badges require an internet connection"
		hint_lbl.add_theme_font_size_override("font_size", int(18 * _sy))
		hint_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		err_vbox.add_child(hint_lbl)

		var retry_center := CenterContainer.new()
		err_vbox.add_child(retry_center)

		var retry_btn := Button.new()
		retry_btn.text = "Retry"
		retry_btn.custom_minimum_size = Vector2(int(100 * _sx), int(42 * _sy))
		retry_btn.add_theme_font_size_override("font_size", int(20 * _sy))
		retry_btn.add_theme_stylebox_override("normal",  StyleFactory.make_secondary_button_normal())
		retry_btn.add_theme_stylebox_override("hover",   StyleFactory.make_secondary_button_hover())
		retry_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
		retry_btn.pressed.connect(
			func() -> void:
				_reset_content()
				_start_loading_dots()
				ApiClient.get_profile(_on_profile_loaded)
		)
		UIAnimations.make_interactive(retry_btn)
		retry_center.add_child(retry_btn)

	_loading_section.visible = false
	_settings_content.visible = true


# =============================================================================
# AVATAR DRAW
# =============================================================================


func _draw_avatar() -> void:
	var c      := _avatar_ctrl.size * 0.5
	var hex_r  := _avatar_ctrl.size.x * 0.48
	var inner_r := _avatar_ctrl.size.x * 0.36

	# Glow ring
	var glow_c := _frame_color
	glow_c.a   = 0.22
	_avatar_ctrl.draw_polygon(StyleFactory.hex_points(c, hex_r + 3.0 * _sx), [glow_c])

	# Frame hex + fill circle
	_avatar_ctrl.draw_polygon(StyleFactory.hex_points(c, hex_r),  [_frame_color])
	_avatar_ctrl.draw_circle(c, inner_r, _avatar_color)

	# Initials
	var font := ThemeDB.fallback_font
	var fs   := int(_avatar_ctrl.size.x * 0.21)
	var ts   := font.get_string_size(_initials, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	_avatar_ctrl.draw_string(
		font,
		c - ts * 0.5 + Vector2(0, ts.y * 0.35),
		_initials, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color.WHITE
	)

	# Level badge dot (bottom-right)
	var br := 13.0 * _sx
	var bc := Vector2(_avatar_ctrl.size.x - br * 0.5, _avatar_ctrl.size.y - br * 0.5)
	_avatar_ctrl.draw_circle(bc, br + 2.0 * _sx, StyleFactory.BG_DEEP)
	_avatar_ctrl.draw_circle(bc, br, StyleFactory.BG_CARD)
	_avatar_ctrl.draw_arc(bc, br, 0, TAU, 32, _frame_color, 1.5 * _sx, true)

	var lvl_t  := str(_level_num)
	var lvl_fs := int(12 * _sy)
	var lvl_ts := font.get_string_size(lvl_t, HORIZONTAL_ALIGNMENT_CENTER, -1, lvl_fs)
	_avatar_ctrl.draw_string(
		font,
		bc - lvl_ts * 0.5 + Vector2(0, lvl_ts.y * 0.35),
		lvl_t, HORIZONTAL_ALIGNMENT_CENTER, -1, lvl_fs, _frame_color
	)


# =============================================================================
# INPUT / ACTIONS
# =============================================================================


func _on_blocker_input(event: InputEvent) -> void:
	if not _can_dismiss:
		return
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		hide_profile()


func _on_logout_pressed() -> void:
	ApiClient.logout()
	GameManager.clear_current_student()
	get_tree().change_scene_to_file("res://scenes/AuthScreen.tscn")


func _on_music_toggled(on: bool) -> void:
	AudioManager.set_music_enabled(on)


func _on_sfx_toggled(on: bool) -> void:
	AudioManager.set_sfx_enabled(on)


# =============================================================================
# HELPERS
# =============================================================================


func _get_category_color(cat: String) -> Color:
	match cat:
		"building": return StyleFactory.GOLD
		"quest":    return StyleFactory.ACCENT_CORAL
		"xp":       return StyleFactory.SKY_BLUE
		"streak":   return StyleFactory.SUCCESS_GREEN
		"level":    return Color(0.698, 0.533, 0.886)
	return StyleFactory.TEXT_MUTED


func _get_initials(player_name: String) -> String:
	if player_name.is_empty():
		return "?"
	var parts := player_name.strip_edges().split(" ", false)
	return (parts[0][0] + parts[1][0]).to_upper() if parts.size() >= 2 else parts[0][0].to_upper()
