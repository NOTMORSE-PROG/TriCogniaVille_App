class_name StyleFactory
## StyleFactory — Static factory for production-quality StyleBoxFlat instances.
## Centralized card, button, and UI element styles for TriCognia Ville.

# ── Color Constants ───────────────────────────────────────────────────────────

const BG_DEEP := Color(0.039, 0.086, 0.157)  # #0A1628
const BG_CARD := Color(0.086, 0.125, 0.251)  # #162040
const BG_SURFACE := Color(0.102, 0.165, 0.290)  # #1A2A4A

const ACCENT_CORAL := Color(0.914, 0.388, 0.431)  # #E9636E
const ACCENT_CORAL_HOVER := Color(1.0, 0.482, 0.522)  # #FF7B85
const ACCENT_CORAL_PRESSED := Color(0.780, 0.290, 0.340)  # #C74A57
const SUCCESS_GREEN := Color(0.357, 0.851, 0.635)  # #5BD9A2
const GOLD := Color(0.886, 0.725, 0.290)  # #E2B94A
const SKY_BLUE := Color(0.392, 0.769, 0.910)  # #64C4E8

const TEXT_PRIMARY := Color.WHITE
const TEXT_SECONDARY := Color(0.659, 0.722, 0.816)  # #A8B8D0
const TEXT_MUTED := Color(0.420, 0.478, 0.553)  # #6B7A8D
const TEXT_ERROR := Color(1.0, 0.420, 0.420)  # #FF6B6B

const PIN_EMPTY := Color(0.227, 0.290, 0.369)  # #3A4A5E
const DISABLED := Color(0.165, 0.204, 0.282)  # #2A3448

# ── Avatar & Frame Colors ─────────────────────────────────────────────────────
const AVATAR_COLORS: Array[Color] = [
	Color(0.914, 0.388, 0.431),  # coral
	Color(0.357, 0.851, 0.635),  # seafoam
	Color(0.886, 0.725, 0.290),  # gold
	Color(0.392, 0.769, 0.910),  # sky blue
	Color(0.698, 0.533, 0.886),  # lavender
	Color(0.961, 0.588, 0.392),  # peach
]
const FRAME_BRONZE := Color(0.72, 0.53, 0.33)
const FRAME_SILVER := Color(0.75, 0.75, 0.80)

# ── Stage Theme Colors ────────────────────────────────────────────────────────
const STAGE_TUTORIAL_BG := Color(0.06, 0.12, 0.28)  # Deep blue tint
const STAGE_TUTORIAL_ACCENT := Color(0.392, 0.769, 0.910)  # SKY_BLUE
const STAGE_PRACTICE_BG := Color(0.16, 0.14, 0.06)  # Warm amber tint
const STAGE_PRACTICE_ACCENT := Color(0.886, 0.725, 0.290)  # GOLD
const STAGE_MISSION_BG := Color(0.22, 0.06, 0.08)  # Deep red tint
const STAGE_MISSION_ACCENT := Color(0.914, 0.388, 0.431)  # ACCENT_CORAL


static func get_stage_theme(stage: String) -> Dictionary:
	match stage:
		"tutorial":
			return {
				"bg": STAGE_TUTORIAL_BG,
				"accent": STAGE_TUTORIAL_ACCENT,
				"label": "TUTORIAL MODE",
				"icon": "LEARN",
				"desc": "Guided learning — no score",
			}
		"practice":
			return {
				"bg": STAGE_PRACTICE_BG,
				"accent": STAGE_PRACTICE_ACCENT,
				"label": "PRACTICE MODE",
				"icon": "PRACTICE",
				"desc": "Practice with hints — no score",
			}
		"mission":
			return {
				"bg": STAGE_MISSION_BG,
				"accent": STAGE_MISSION_ACCENT,
				"label": "MISSION MODE",
				"icon": "GRADED",
				"desc": "Scored assessment — 7/10 to pass",
			}
	return {
		"bg": BG_DEEP,
		"accent": TEXT_MUTED,
		"label": "",
		"icon": "",
		"desc": "",
	}


# ── Card Styles ───────────────────────────────────────────────────────────────


## Elevated card with shadow. elevation: 1=subtle, 2=medium, 3=high
static func make_elevated_card(
	bg: Color = BG_CARD, radius: int = 16, elevation: int = 2
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20

	match elevation:
		1:
			sb.shadow_color = Color(0, 0, 0, 0.2)
			sb.shadow_size = 4
			sb.shadow_offset = Vector2(0, 2)
		2:
			sb.shadow_color = Color(0, 0, 0, 0.3)
			sb.shadow_size = 8
			sb.shadow_offset = Vector2(0, 4)
		3:
			sb.shadow_color = Color(0, 0, 0, 0.4)
			sb.shadow_size = 16
			sb.shadow_offset = Vector2(0, 8)

	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.0
	return sb


## Faux glassmorphism card — semi-transparent with border glow
static func make_glass_card(radius: int = 20) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.20, 0.75)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.border_width_top = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(1, 1, 1, 0.08)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 6)
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	sb.anti_aliasing = true
	return sb


# ── Button Styles ─────────────────────────────────────────────────────────────


## Primary CTA button (coral accent)
static func make_primary_button_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ACCENT_CORAL
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0.914, 0.388, 0.431, 0.3)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	sb.anti_aliasing = true
	return sb


static func make_primary_button_hover() -> StyleBoxFlat:
	var sb := make_primary_button_normal()
	sb.bg_color = ACCENT_CORAL_HOVER
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	return sb


static func make_primary_button_pressed() -> StyleBoxFlat:
	var sb := make_primary_button_normal()
	sb.bg_color = ACCENT_CORAL_PRESSED
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 1)
	return sb


## Secondary button (outlined / ghost)
static func make_secondary_button_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.border_width_top = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1, 1, 1, 0.25)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.anti_aliasing = true
	return sb


static func make_secondary_button_hover() -> StyleBoxFlat:
	var sb := make_secondary_button_normal()
	sb.bg_color = Color(1, 1, 1, 0.06)
	sb.border_color = Color(1, 1, 1, 0.4)
	return sb


static func make_secondary_button_pressed() -> StyleBoxFlat:
	var sb := make_secondary_button_normal()
	sb.bg_color = Color(1, 1, 1, 0.03)
	sb.border_color = Color(1, 1, 1, 0.15)
	return sb


## Numpad key button
static func make_numpad_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_SURFACE
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 2)
	sb.anti_aliasing = true
	return sb


static func make_numpad_hover() -> StyleBoxFlat:
	var sb := make_numpad_normal()
	sb.bg_color = Color(0.14, 0.21, 0.36)
	sb.shadow_size = 5
	return sb


static func make_numpad_pressed() -> StyleBoxFlat:
	var sb := make_numpad_normal()
	sb.bg_color = Color(0.07, 0.11, 0.20)
	sb.shadow_size = 1
	return sb


## Disabled button
static func make_disabled_button() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = DISABLED
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.anti_aliasing = true
	return sb


# ── Student List Card ─────────────────────────────────────────────────────────


static func make_student_card_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_CARD
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.15)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 2)
	sb.anti_aliasing = true
	return sb


static func make_student_card_hover() -> StyleBoxFlat:
	var sb := make_student_card_normal()
	sb.bg_color = Color(0.10, 0.15, 0.28)
	sb.border_width_left = 3
	sb.border_color = ACCENT_CORAL
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	return sb


static func make_student_card_pressed() -> StyleBoxFlat:
	var sb := make_student_card_normal()
	sb.bg_color = Color(0.06, 0.09, 0.18)
	sb.shadow_size = 1
	return sb


# ── Input Styles ──────────────────────────────────────────────────────────────


static func make_line_edit_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.055, 0.082, 0.165)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.border_width_bottom = 2
	sb.border_color = Color(1, 1, 1, 0.1)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.anti_aliasing = true
	return sb


static func make_line_edit_focus() -> StyleBoxFlat:
	var sb := make_line_edit_normal()
	sb.border_width_bottom = 2
	sb.border_width_top = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_color = SKY_BLUE
	return sb


# ── PIN Dot ───────────────────────────────────────────────────────────────────


static func make_pin_dot(filled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ACCENT_CORAL if filled else PIN_EMPTY
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_left = 20
	sb.corner_radius_bottom_right = 20
	sb.anti_aliasing = true
	return sb


# ── Progress Bar ──────────────────────────────────────────────────────────────


static func make_progress_bg() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.22)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	return sb


static func make_progress_fill() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ACCENT_CORAL
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	return sb


# ── Feedback Panel ────────────────────────────────────────────────────────────


static func make_feedback_panel(correct: bool) -> StyleBoxFlat:
	var sb := make_elevated_card(BG_CARD, 16, 2)
	sb.border_width_top = 3
	sb.border_color = SUCCESS_GREEN if correct else TEXT_ERROR
	return sb


# ── Profile Hex Helpers ──────────────────────────────────────────────────────

## Returns frame color based on player level tier.
static func get_level_frame_color(level: int) -> Color:
	if level >= 5:
		return GOLD
	if level >= 3:
		return FRAME_SILVER
	return FRAME_BRONZE


## Returns PackedVector2Array of 6 hexagon vertices (flat-top orientation).
static func hex_points(center: Vector2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var angle := deg_to_rad(60.0 * i - 30.0)
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts
