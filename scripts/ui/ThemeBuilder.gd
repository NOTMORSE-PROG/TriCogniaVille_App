class_name ThemeBuilder
## ThemeBuilder — Generates the unified TriCognia Ville Theme resource.
## Apply the returned Theme to root Control nodes of each scene.


static func build() -> Theme:
	var theme := Theme.new()

	# ── Fonts ─────────────────────────────────────────────────────────────────
	# Try to load custom fonts (variable fonts contain all weights)
	var font_nunito: Font = load_font("res://assets/fonts/Nunito-Variable.ttf")
	var font_inter: Font = load_font("res://assets/fonts/Inter-Variable.ttf")

	# Assign fonts — Nunito for headings, Inter for body/UI
	var body_font: Font = font_inter if font_inter else font_nunito
	var ui_font: Font = font_inter if font_inter else font_nunito

	if body_font:
		theme.set_font("font", "Label", body_font)
		theme.set_font("font", "RichTextLabel", body_font)
		theme.set_font("normal_font", "RichTextLabel", body_font)
	if ui_font:
		theme.set_font("font", "Button", ui_font)
		theme.set_font("font", "LineEdit", ui_font)

	# ── Font Sizes ────────────────────────────────────────────────────────────
	theme.set_font_size("font_size", "Label", 24)
	theme.set_font_size("font_size", "Button", 26)
	theme.set_font_size("font_size", "LineEdit", 26)
	theme.set_font_size("normal_font_size", "RichTextLabel", 26)

	# ── Colors ────────────────────────────────────────────────────────────────
	theme.set_color("font_color", "Label", StyleFactory.TEXT_PRIMARY)
	theme.set_color("font_color", "Button", StyleFactory.TEXT_PRIMARY)
	theme.set_color("font_disabled_color", "Button", StyleFactory.TEXT_MUTED)
	theme.set_color("font_color", "LineEdit", StyleFactory.TEXT_PRIMARY)
	theme.set_color("font_placeholder_color", "LineEdit", StyleFactory.TEXT_MUTED)
	theme.set_color("default_color", "RichTextLabel", StyleFactory.TEXT_PRIMARY)

	# ── Button (default — card-style) ─────────────────────────────────────────
	theme.set_stylebox("normal", "Button", StyleFactory.make_numpad_normal())
	theme.set_stylebox("hover", "Button", StyleFactory.make_numpad_hover())
	theme.set_stylebox("pressed", "Button", StyleFactory.make_numpad_pressed())
	theme.set_stylebox("disabled", "Button", StyleFactory.make_disabled_button())

	# ── LineEdit ──────────────────────────────────────────────────────────────
	theme.set_stylebox("normal", "LineEdit", StyleFactory.make_line_edit_normal())
	theme.set_stylebox("focus", "LineEdit", StyleFactory.make_line_edit_focus())

	# ── Panel (default — elevated card) ───────────────────────────────────────
	theme.set_stylebox("panel", "Panel", StyleFactory.make_elevated_card())

	# ── ProgressBar ───────────────────────────────────────────────────────────
	theme.set_stylebox("background", "ProgressBar", StyleFactory.make_progress_bg())
	theme.set_stylebox("fill", "ProgressBar", StyleFactory.make_progress_fill())

	return theme


static func load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path) as Font
	return null
