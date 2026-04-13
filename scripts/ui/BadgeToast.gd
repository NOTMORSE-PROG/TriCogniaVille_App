class_name BadgeToast
extends Control
## BadgeToast — Top-right slide-in notification shown when a badge is earned.
## Call popup() once, then this node removes itself automatically.

# Badge id → { name, icon } — mirrors badge-definitions.ts
const BADGE_INFO: Dictionary = {
	"building_town_hall":  { "name": "Town Mayor",       "icon": "🏛️" },
	"building_school":     { "name": "Scholar",          "icon": "🏫" },
	"building_inn":        { "name": "Innkeeper",        "icon": "🏠" },
	"building_chapel":     { "name": "Priest",           "icon": "⛪" },
	"building_library":    { "name": "Bookworm",         "icon": "📚" },
	"building_well":       { "name": "Water Bearer",     "icon": "🪣" },
	"building_market":     { "name": "Merchant",         "icon": "🏪" },
	"building_bakery":     { "name": "Baker",            "icon": "🥖" },
	"streak_3":            { "name": "Getting Started",  "icon": "🔥" },
	"streak_7":            { "name": "Week Warrior",     "icon": "⚡" },
	"streak_14":           { "name": "Fortnight Force",  "icon": "💫" },
	"streak_30":           { "name": "Monthly Master",   "icon": "🌟" },
	"xp_100":              { "name": "First Steps",      "icon": "✨" },
	"xp_500":              { "name": "XP Hunter",        "icon": "💎" },
	"xp_1000":             { "name": "XP Champion",      "icon": "👑" },
	"xp_2500":             { "name": "Legendary",        "icon": "🏆" },
	"quest_first_pass":    { "name": "First Victory",    "icon": "🎯" },
	"quest_10_passed":     { "name": "Quest Tracker",    "icon": "📜" },
	"quest_25_passed":     { "name": "Quest Master",     "icon": "⚔️" },
	"quest_perfect_first": { "name": "Perfectionist",    "icon": "💯" },
	"level_2":             { "name": "Rising Reader",    "icon": "📖" },
	"level_3":             { "name": "Developing Reader","icon": "📗" },
	"level_4":             { "name": "Fluent Reader",    "icon": "🎓" },
}

const SLIDE_T := 0.30
const HOLD_T  := 3.0


func popup(badge_id: String, vp_size: Vector2, stack_index: int,
		sx: float = 1.0, sy: float = 1.0) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var info: Dictionary = BADGE_INFO.get(badge_id, {
		"name": badge_id.replace("_", " ").capitalize(),
		"icon": "🏅",
	})

	# ── Scaled dimensions ────────────────────────────────────────────────────────
	var toast_w    := int(340 * sx)
	var toast_h    := int(90 * sy)
	var margin_r   := int(18 * sx)
	var margin_top := int(24 * sy)
	var stack_gap  := int(12 * sy)

	# ── Card panel ──────────────────────────────────────────────────────────────
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(toast_w, toast_h)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.09, 0.17, 0.96)
	s.set_corner_radius_all(int(8 * minf(sx, sy)))
	s.border_width_top    = int(maxf(2, 2 * sy))
	s.border_width_left   = int(maxf(2, 2 * sx))
	s.border_width_right  = int(maxf(2, 2 * sx))
	s.border_width_bottom = int(maxf(2, 2 * sy))
	s.border_color  = Color(StyleFactory.GOLD.r, StyleFactory.GOLD.g, StyleFactory.GOLD.b, 0.7)
	s.shadow_color  = Color(0, 0, 0, 0.55)
	s.shadow_size   = int(10 * sy)
	s.shadow_offset = Vector2(0, int(3 * sy))
	s.content_margin_left   = 16.0 * sx
	s.content_margin_right  = 16.0 * sx
	s.content_margin_top    = 10.0 * sy
	s.content_margin_bottom = 10.0 * sy
	s.anti_aliasing = true
	card.add_theme_stylebox_override("panel", s)
	add_child(card)

	# ── Inner row: icon  |  text column ─────────────────────────────────────────
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(14 * sx))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var icon_lbl := Label.new()
	icon_lbl.text = info["icon"]
	icon_lbl.add_theme_font_size_override("font_size", int(42 * sy))
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_lbl)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(2 * sy))
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)

	var header := Label.new()
	header.text = "Badge Unlocked!"
	header.add_theme_font_size_override("font_size", int(18 * sy))
	header.add_theme_color_override("font_color", StyleFactory.GOLD)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(header)

	var name_lbl := Label.new()
	name_lbl.text = info["name"]
	name_lbl.add_theme_font_size_override("font_size", int(24 * sy))
	name_lbl.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(name_lbl)

	# ── Position & animate ───────────────────────────────────────────────────────
	card.size = Vector2(toast_w, toast_h)

	var y_pos := margin_top + stack_index * (toast_h + stack_gap)
	var x_on  := vp_size.x - toast_w - margin_r
	var x_off := vp_size.x + 10.0

	position = Vector2(x_off, y_pos)
	size     = Vector2(toast_w, toast_h)

	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "position:x", x_on, SLIDE_T)
	tw.tween_interval(HOLD_T)
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position:x", x_off, SLIDE_T * 0.8)
	tw.tween_callback(queue_free)
