extends Control
## ProfilePanel — Scene-first profile modal.
## Layout lives in scenes/ProfilePanel.tscn.
## This script only binds data to pre-placed nodes and handles animations.

signal dismissed

const CATEGORY_ORDER: Array[String] = ["building", "quest", "xp", "streak", "level"]
const CATEGORY_LABELS: Dictionary = {
	"building": "Buildings",
	"quest": "Quests",
	"xp": "XP Milestones",
	"streak": "Streaks",
	"level": "Reading Levels",
}

var _sx: float = 1.0
var _sy: float = 1.0
var _transitioning: bool = false
var _can_dismiss: bool = false

# Avatar draw state (updated in _populate_header, used in _draw_avatar)
var _avatar_color: Color = StyleFactory.AVATAR_COLORS[0]
var _frame_color: Color = StyleFactory.FRAME_BRONZE
var _initials: String = "?"
var _level_num: int = 1

# Loading dots
var _dot_timer: Timer
var _dot_count: int = 0

# ── Structural nodes ──────────────────────────────────────────────────────────
@onready var _blocker: ColorRect = $Blocker
@onready var _panel: PanelContainer = $Panel
@warning_ignore("unused_private_class_variable")
@onready var _scroll: ScrollContainer = $Panel/OuterVBox/Scroll
@onready var _content: VBoxContainer = $Panel/OuterVBox/Scroll/Content
@onready var _close_btn: Button = $Panel/OuterVBox/CloseRow/CloseBtn
@onready var _title_lbl: Label = $Panel/OuterVBox/CloseRow/Title
@onready var _loading_section: CenterContainer = $Panel/OuterVBox/Scroll/Content/LoadingSection
@onready var _loading_lbl: Label = $Panel/OuterVBox/Scroll/Content/LoadingSection/LoadingLabel
@onready var _profile_content: VBoxContainer = $Panel/OuterVBox/Scroll/Content/ProfileContent

# Header
@onready var _header_banner: PanelContainer = $Panel/OuterVBox/Scroll/Content/ProfileContent/HeaderBanner
@onready
var _avatar_ctrl: Control = $Panel/OuterVBox/Scroll/Content/ProfileContent/HeaderBanner/HeaderVBox/AvatarCenter/AvatarControl
@onready
var _name_lbl: Label = $Panel/OuterVBox/Scroll/Content/ProfileContent/HeaderBanner/HeaderVBox/NameLabel
@onready
var _level_pill: PanelContainer = $Panel/OuterVBox/Scroll/Content/ProfileContent/HeaderBanner/HeaderVBox/SubRow/LevelPill
@onready
var _level_lbl: Label = $Panel/OuterVBox/Scroll/Content/ProfileContent/HeaderBanner/HeaderVBox/SubRow/LevelPill/LevelLabel
@onready
var _username_lbl: Label = $Panel/OuterVBox/Scroll/Content/ProfileContent/HeaderBanner/HeaderVBox/SubRow/UsernameLabel
@onready var _rl_lbl: Label = $Panel/OuterVBox/Scroll/Content/ProfileContent/HeaderBanner/HeaderVBox/RLLabel

# Stats
@onready var _stats_card: PanelContainer = $Panel/OuterVBox/Scroll/Content/ProfileContent/StatsCard
@onready
var _quest_val: Label = $Panel/OuterVBox/Scroll/Content/ProfileContent/StatsCard/StatsCol/QuestRow/QuestValue
@onready
var _building_val: Label = $Panel/OuterVBox/Scroll/Content/ProfileContent/StatsCard/StatsCol/BuildingRow/BuildingValue
@onready
var _streak_val: Label = $Panel/OuterVBox/Scroll/Content/ProfileContent/StatsCard/StatsCol/StreakRow/StreakValue

# XP
@onready var _xp_total_lbl: Label = $Panel/OuterVBox/Scroll/Content/ProfileContent/XPSection/XPTitleRow/XPTotal
@onready var _xp_bar_bg: Panel = $Panel/OuterVBox/Scroll/Content/ProfileContent/XPSection/XPBarBg
@onready var _xp_fill: ColorRect = $Panel/OuterVBox/Scroll/Content/ProfileContent/XPSection/XPBarBg/XPFill
@onready var _xp_sub_lbl: Label = $Panel/OuterVBox/Scroll/Content/ProfileContent/XPSection/XPSubLabel

# Badges
@onready
var _badges_count: Label = $Panel/OuterVBox/Scroll/Content/ProfileContent/BadgesSection/BadgesTitleRow/BadgesCount
@onready
var _badges_box: VBoxContainer = $Panel/OuterVBox/Scroll/Content/ProfileContent/BadgesSection/BadgesContainer

# Logout
@onready var _logout_btn: Button = $Panel/OuterVBox/Scroll/Content/ProfileContent/LogoutSection/LogoutBtn

# =============================================================================
# SETUP
# =============================================================================


func _ready() -> void:
	_close_btn.pressed.connect(func(): hide_profile())
	_blocker.gui_input.connect(_on_blocker_input)
	_logout_btn.pressed.connect(_on_logout_pressed)
	_avatar_ctrl.draw.connect(_draw_avatar)
	_style_nodes()


func _style_nodes() -> void:
	# Glass card panel
	var card_style := StyleFactory.make_glass_card(16)
	card_style.content_margin_left = 18.0
	card_style.content_margin_right = 18.0
	card_style.content_margin_top = 14.0
	card_style.content_margin_bottom = 18.0
	_panel.add_theme_stylebox_override("panel", card_style)

	# Close button
	_title_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	var cb := StyleBoxFlat.new()
	cb.bg_color = Color(1, 1, 1, 0.08)
	cb.set_corner_radius_all(8)
	cb.border_width_top = 1
	cb.border_width_bottom = 1
	cb.border_width_left = 1
	cb.border_width_right = 1
	cb.border_color = Color(1, 1, 1, 0.2)
	var cb_h := cb.duplicate() as StyleBoxFlat
	cb_h.bg_color = Color(1, 1, 1, 0.18)
	cb_h.border_color = StyleFactory.GOLD
	var cb_p := cb.duplicate() as StyleBoxFlat
	cb_p.bg_color = StyleFactory.TEXT_ERROR.darkened(0.3)
	cb_p.border_color = StyleFactory.TEXT_ERROR
	_close_btn.add_theme_stylebox_override("normal", cb)
	_close_btn.add_theme_stylebox_override("hover", cb_h)
	_close_btn.add_theme_stylebox_override("pressed", cb_p)
	_close_btn.add_theme_color_override("font_color", StyleFactory.GOLD)
	_close_btn.mouse_filter = Control.MOUSE_FILTER_STOP

	# Header banner dark background
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = StyleFactory.BG_DEEP.darkened(0.3)
	banner_style.set_corner_radius_all(12)
	banner_style.content_margin_top = 16.0
	banner_style.content_margin_bottom = 14.0
	banner_style.content_margin_left = 12.0
	banner_style.content_margin_right = 12.0
	_header_banner.add_theme_stylebox_override("panel", banner_style)

	# Stats card
	var stats_style := StyleFactory.make_elevated_card(StyleFactory.BG_SURFACE, 12, 1)
	stats_style.content_margin_left = 14.0
	stats_style.content_margin_right = 14.0
	stats_style.content_margin_top = 10.0
	stats_style.content_margin_bottom = 10.0
	_stats_card.add_theme_stylebox_override("panel", stats_style)

	# Stat value accent colors
	_quest_val.add_theme_color_override("font_color", StyleFactory.ACCENT_CORAL)
	_building_val.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
	_streak_val.add_theme_color_override("font_color", StyleFactory.SKY_BLUE)

	# XP labels
	_xp_total_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_xp_sub_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_xp_bar_bg.add_theme_stylebox_override("panel", StyleFactory.make_progress_bg())

	# Logout button (red-tinted secondary style)
	_logout_btn.add_theme_color_override("font_color", StyleFactory.TEXT_ERROR)
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
	_logout_btn.add_theme_stylebox_override("normal", n)
	_logout_btn.add_theme_stylebox_override("hover", h)
	_logout_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	UIAnimations.make_interactive(_logout_btn)


func setup(sx: float, sy: float) -> void:
	_sx = sx
	_sy = sy
	if is_node_ready():
		_apply_scale()


func _apply_scale() -> void:
	var vp := get_viewport().get_visible_rect().size
	# Centered modal — 88% wide, 86% tall
	var card_w: float = vp.x * 0.88
	var card_h: float = vp.y * 0.86
	_panel.offset_left = -card_w * 0.5
	_panel.offset_right = card_w * 0.5
	_panel.offset_top = -card_h * 0.5
	_panel.offset_bottom = card_h * 0.5
	_close_btn.custom_minimum_size = Vector2(56.0 * _sx, 56.0 * _sy)
	_logout_btn.custom_minimum_size = Vector2(200.0 * _sx, 66.0 * _sy)
	_avatar_ctrl.custom_minimum_size = Vector2(140.0 * _sx, 140.0 * _sy)
	_xp_bar_bg.custom_minimum_size.x = vp.x * 0.82

	_title_lbl.add_theme_font_size_override("font_size", int(22 * _sy))
	_close_btn.add_theme_font_size_override("font_size", int(26 * _sy))
	_logout_btn.add_theme_font_size_override("font_size", int(22 * _sy))
	_name_lbl.add_theme_font_size_override("font_size", int(34 * _sy))
	_rl_lbl.add_theme_font_size_override("font_size", int(22 * _sy))
	_level_lbl.add_theme_font_size_override("font_size", int(18 * _sy))
	_username_lbl.add_theme_font_size_override("font_size", int(20 * _sy))
	_xp_total_lbl.add_theme_font_size_override("font_size", int(20 * _sy))
	_xp_sub_lbl.add_theme_font_size_override("font_size", int(18 * _sy))
	_badges_count.add_theme_font_size_override("font_size", int(20 * _sy))

	_content.add_theme_constant_override("separation", int(20 * _sy))
	var card_style := _panel.get_theme_stylebox("panel") as StyleBoxFlat
	if card_style:
		# Remove corner rounding for a flat box look
		card_style.corner_radius_top_left = 0
		card_style.corner_radius_top_right = 0
		card_style.corner_radius_bottom_left = 0
		card_style.corner_radius_bottom_right = 0
		card_style.content_margin_left = 28.0 * _sx
		card_style.content_margin_right = 28.0 * _sx
		card_style.content_margin_top = 24.0 * _sy
		card_style.content_margin_bottom = 28.0 * _sy


# =============================================================================
# SHOW / HIDE
# =============================================================================


func show_profile() -> void:
	if _transitioning or visible:
		return
	_can_dismiss = false
	_apply_scale()
	_reset_content()
	modulate.a = 0.0
	visible = true
	var tw := create_tween()
	(
		tw
		. tween_property(self, "modulate:a", 1.0, 0.3)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
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
	tw.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	await tw.finished
	visible = false
	modulate.a = 1.0
	_transitioning = false
	dismissed.emit()


func _reset_content() -> void:
	_loading_section.visible = true
	_profile_content.visible = false
	for child in _badges_box.get_children():
		child.queue_free()
	_quest_val.text = "-"
	_building_val.text = "-"
	_streak_val.text = "-"
	_xp_fill.offset_right = 4.0


# =============================================================================
# LOADING DOTS
# =============================================================================


func _start_loading_dots() -> void:
	_dot_count = 0
	_loading_lbl.text = "Loading profile..."
	_dot_timer = Timer.new()
	_dot_timer.wait_time = 0.4
	_dot_timer.timeout.connect(
		func():
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
# DATA CALLBACK
# =============================================================================


func _on_profile_loaded(success: bool, data: Dictionary) -> void:
	_stop_loading_dots()
	if not visible:
		return

	if not success:
		_show_error_state()
		return

	_populate_header(data)
	_populate_stats(data.get("stats", {}), data.get("streakDays", 0))
	_populate_xp(data.get("level", {}), data.get("xp", GameManager.current_student.get("xp", 0)))
	_populate_badges(data.get("badges", []))

	_loading_section.visible = false
	_profile_content.visible = true

	await get_tree().process_frame
	if is_instance_valid(_profile_content):
		UIAnimations.stagger_children(self, _profile_content, 0.05)


# =============================================================================
# DATA BINDING — each function sets .text / .value on pre-placed nodes
# =============================================================================


func _populate_header(data: Dictionary) -> void:
	var player_name: String = data.get("name", GameManager.current_student.get("name", "?"))
	var level_data: Dictionary = data.get("level", {})
	_level_num = level_data.get(
		"level", data.get("readingLevel", GameManager.current_student.get("reading_level", 1))
	)
	_avatar_color = _get_avatar_color(player_name)
	_frame_color = StyleFactory.get_level_frame_color(_level_num)
	_initials = _get_initials(player_name)

	# Trigger avatar redraw with new colors
	_avatar_ctrl.queue_redraw()

	# Brief scale pulse
	_avatar_ctrl.pivot_offset = _avatar_ctrl.size * 0.5
	var tw := _avatar_ctrl.create_tween()
	(
		tw
		. tween_property(_avatar_ctrl, "scale", Vector2(1.06, 1.06), 0.15)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	(
		tw
		. tween_property(_avatar_ctrl, "scale", Vector2(1.0, 1.0), 0.15)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)

	# Level pill style (color matches frame)
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = _frame_color
	pill_style.set_corner_radius_all(10)
	pill_style.content_margin_left = 10.0 * _sx
	pill_style.content_margin_right = 10.0 * _sx
	pill_style.content_margin_top = 2.0 * _sy
	pill_style.content_margin_bottom = 2.0 * _sy
	_level_pill.add_theme_stylebox_override("panel", pill_style)

	_name_lbl.text = player_name
	_level_lbl.text = "Lv. %d" % _level_num
	_level_lbl.add_theme_color_override("font_color", StyleFactory.BG_DEEP)
	_rl_lbl.text = "📖  Reading Level %d" % _level_num
	_rl_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)

	var username_raw: Variant = data.get("username", GameManager.current_student.get("username", ""))
	var username: String = str(username_raw) if username_raw != null else ""
	_username_lbl.text = ("@%s" % username) if not username.is_empty() else ""
	_username_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)


func _populate_stats(stats: Dictionary, streak_days: int) -> void:
	_quest_val.text = str(stats.get("questsPassed", 0))
	_building_val.text = "%d / %d" % [stats.get("buildingsUnlocked", 0), GameManager.TOTAL_BUILDINGS]
	_streak_val.text = "%dd" % streak_days


func _populate_xp(level_data: Dictionary, total_xp: int) -> void:
	var level_num: int = level_data.get("level", 1)
	var progress_xp: int = level_data.get("progressXp", 0)
	var current_lvl_xp: int = level_data.get("currentLevelXp", 0)
	var next_lvl_xp: int = level_data.get("nextLevelXp", 100)
	var progress_pct: int = level_data.get("progressPct", 0)
	var range_xp: int = next_lvl_xp - current_lvl_xp

	_xp_total_lbl.text = "%s XP total" % _format_number(total_xp)
	_xp_sub_lbl.text = (
		"%s / %s to Level %d"
		% [_format_number(progress_xp), _format_number(range_xp), level_num + 1]
	)

	# Defer so the bar container has its final rendered size before we measure it.
	var pct := clampf(float(progress_pct) / 100.0, 0.0, 1.0)
	_xp_fill.offset_right = 4.0  # reset so old fill doesn't show
	await get_tree().process_frame
	await get_tree().process_frame
	var bar_width := _xp_bar_bg.size.x
	if bar_width <= 0.0:
		bar_width = _xp_bar_bg.custom_minimum_size.x
	var fill_target: float = maxf(bar_width * pct, 4.0)
	(
		_xp_fill
		. create_tween()
		. tween_property(_xp_fill, "offset_right", fill_target, 0.6)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_OUT)
		. set_delay(0.1)
	)


func _populate_badges(badges: Array) -> void:
	var earned := badges.filter(func(b): return b.get("earned", false)).size()
	_badges_count.text = "%d / %d earned" % [earned, badges.size()]
	_badges_count.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)

	# Group badges by category
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
		cat_lbl.add_theme_font_size_override("font_size", int(20 * _sy))
		cat_lbl.add_theme_color_override("font_color", _get_category_color(cat))
		cat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cat_vbox.add_child(cat_lbl)

		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", int(8 * _sx))
		grid.add_theme_constant_override("v_separation", int(8 * _sy))
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cat_vbox.add_child(grid)

		for badge in cat_badges:
			grid.add_child(_make_badge_tile(badge, cat))


func _make_badge_tile(badge: Dictionary, category: String) -> PanelContainer:
	var is_earned: bool = badge.get("earned", false)
	var tile_w := int(120 * _sx)
	var tile_h := int(136 * _sy)

	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(tile_w, tile_h)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ts := StyleBoxFlat.new()
	ts.set_corner_radius_all(10)
	ts.content_margin_left = 4.0 * _sx
	ts.content_margin_right = 4.0 * _sx
	ts.content_margin_top = 6.0 * _sy
	ts.content_margin_bottom = 4.0 * _sy
	ts.anti_aliasing = true

	if is_earned:
		ts.bg_color = Color(
			StyleFactory.BG_SURFACE.r, StyleFactory.BG_SURFACE.g, StyleFactory.BG_SURFACE.b, 0.9
		)
		var accent := _get_category_color(category)
		ts.set_border_width_all(2)
		ts.border_color = accent.lerp(Color.WHITE, 0.15)
		ts.border_color.a = 0.6
		ts.shadow_color = Color(accent.r, accent.g, accent.b, 0.2)
		ts.shadow_size = 4
		ts.shadow_offset = Vector2(0, 2)
	else:
		ts.bg_color = Color(0.06, 0.08, 0.14, 0.6)
		tile.modulate = Color(1, 1, 1, 0.4)

	tile.add_theme_stylebox_override("panel", ts)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(3 * _sy))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(col)

	var icon_lbl := Label.new()
	icon_lbl.text = badge.get("icon", "?") if is_earned else "🔒"
	icon_lbl.add_theme_font_size_override("font_size", int(38 * _sy))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = badge.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", int(16 * _sy))
	name_lbl.add_theme_color_override(
		"font_color", StyleFactory.TEXT_SECONDARY if is_earned else StyleFactory.TEXT_MUTED
	)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size.x = tile_w - int(8 * _sx)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(name_lbl)

	return tile


# =============================================================================
# ERROR STATE
# =============================================================================


func _show_error_state() -> void:
	# Show whatever local data we have
	var student := GameManager.current_student
	if not student.is_empty():
		_populate_header(
			{
				"name": student.get("name", "Student"),
				"readingLevel": student.get("reading_level", 1),
				"level": {"level": student.get("reading_level", 1)},
			}
		)

	# Add error message + retry into the badges area
	var err_vbox := VBoxContainer.new()
	err_vbox.add_theme_constant_override("separation", int(10 * _sy))
	err_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badges_box.add_child(err_vbox)

	var err_lbl := Label.new()
	err_lbl.text = "Could not load full profile"
	err_lbl.add_theme_font_size_override("font_size", int(22 * _sy))
	err_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_ERROR)
	err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	err_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	err_vbox.add_child(err_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = "Badges require an internet connection"
	hint_lbl.add_theme_font_size_override("font_size", int(20 * _sy))
	hint_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	err_vbox.add_child(hint_lbl)

	var retry_center := CenterContainer.new()
	err_vbox.add_child(retry_center)

	var retry_btn := Button.new()
	retry_btn.text = "Retry"
	retry_btn.custom_minimum_size = Vector2(100 * _sx, 40 * _sy)
	retry_btn.add_theme_font_size_override("font_size", int(22 * _sy))
	retry_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	retry_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	retry_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	retry_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	retry_btn.pressed.connect(
		func():
			_reset_content()
			_start_loading_dots()
			ApiClient.get_profile(_on_profile_loaded)
	)
	UIAnimations.make_interactive(retry_btn)
	retry_center.add_child(retry_btn)

	_loading_section.visible = false
	_profile_content.visible = true


# =============================================================================
# AVATAR DRAW  (connected to AvatarControl.draw signal in _ready)
# =============================================================================


func _draw_avatar() -> void:
	var c := _avatar_ctrl.size * 0.5
	var hex_r := _avatar_ctrl.size.x * 0.48
	var inner_r := _avatar_ctrl.size.x * 0.36

	var glow_c := _frame_color
	glow_c.a = 0.25
	_avatar_ctrl.draw_polygon(StyleFactory.hex_points(c, hex_r + 3.0 * _sx), [glow_c])
	_avatar_ctrl.draw_polygon(StyleFactory.hex_points(c, hex_r), [_frame_color])
	_avatar_ctrl.draw_circle(c, inner_r, _avatar_color)

	var font := ThemeDB.fallback_font
	var fs := int(26 * _sy)
	var ts := font.get_string_size(_initials, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	_avatar_ctrl.draw_string(
		font,
		c - ts * 0.5 + Vector2(0, ts.y * 0.35),
		_initials,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		fs,
		Color.WHITE
	)

	var br := 13.0 * _sx
	var bc := Vector2(_avatar_ctrl.size.x - br * 0.5, _avatar_ctrl.size.y - br * 0.5)
	_avatar_ctrl.draw_circle(bc, br + 2.0 * _sx, StyleFactory.BG_DEEP)
	_avatar_ctrl.draw_circle(bc, br, StyleFactory.BG_CARD)
	_avatar_ctrl.draw_arc(bc, br, 0, TAU, 32, _frame_color, 1.5 * _sx, true)
	var lvl_t := str(_level_num)
	var lvl_fs := int(12 * _sy)
	var lvl_ts := font.get_string_size(lvl_t, HORIZONTAL_ALIGNMENT_CENTER, -1, lvl_fs)
	_avatar_ctrl.draw_string(
		font,
		bc - lvl_ts * 0.5 + Vector2(0, lvl_ts.y * 0.35),
		lvl_t,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		lvl_fs,
		_frame_color
	)


# =============================================================================
# INPUT / LOGOUT
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


# =============================================================================
# HELPERS
# =============================================================================


func _get_category_color(cat: String) -> Color:
	match cat:
		"building":
			return StyleFactory.GOLD
		"quest":
			return StyleFactory.ACCENT_CORAL
		"xp":
			return StyleFactory.SKY_BLUE
		"streak":
			return StyleFactory.SUCCESS_GREEN
		"level":
			return Color(0.698, 0.533, 0.886)
	return StyleFactory.TEXT_MUTED


func _get_avatar_color(player_name: String) -> Color:
	if player_name.is_empty():
		return StyleFactory.AVATAR_COLORS[0]
	return StyleFactory.AVATAR_COLORS[absi(player_name.hash()) % StyleFactory.AVATAR_COLORS.size()]


func _get_initials(player_name: String) -> String:
	if player_name.is_empty():
		return "?"
	var parts := player_name.strip_edges().split(" ", false)
	return (parts[0][0] + parts[1][0]).to_upper() if parts.size() >= 2 else parts[0][0].to_upper()


func _format_number(n: int) -> String:
	var s := str(n)
	if n < 1000:
		return s
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
