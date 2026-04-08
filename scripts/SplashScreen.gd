extends Control
## SplashScreen — First scene loaded on app start.
## Shows the logo + animated loading dots while ApiClient verifies the
## stored JWT token asynchronously. Once auth is resolved (or timed out),
## navigates to the appropriate scene without any login-screen flash.

const MIN_SHOW_TIME := 0.8  # seconds — prevents instant flash for already-authed users
const AUTH_TIMEOUT := 6.0  # seconds — give up waiting if server is unreachable

var _elapsed: float = 0.0
var _dot_elapsed: float = 0.0
var _dot_count: int = 1

var _auth_resolved: bool = false
var _auth_result: bool = false
var _min_time_passed: bool = false
var _navigating: bool = false

var _dots_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

	# If ApiClient already resolved auth before this scene loaded (edge case),
	# mark it immediately and just wait for MIN_SHOW_TIME.
	if ApiClient.is_authenticated:
		_auth_resolved = true
		_auth_result = true
	else:
		ApiClient.auth_state_changed.connect(_on_auth_state_changed, CONNECT_ONE_SHOT)

	set_process(true)


func _build_ui() -> void:
	# ── Dark background ────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0.039, 0.086, 0.157)  # StyleFactory.BG_DEEP
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Centered column ────────────────────────────────────────────────────────
	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(col)

	# ── Logo ───────────────────────────────────────────────────────────────────
	var logo_texture := load("res://logo.png") as Texture2D
	var logo := TextureRect.new()
	logo.texture = logo_texture
	logo.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(420, 225)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(logo)

	# ── Loading dots ───────────────────────────────────────────────────────────
	_dots_label = Label.new()
	_dots_label.text = "."
	_dots_label.add_theme_font_size_override("font_size", 42)
	_dots_label.add_theme_color_override("font_color", Color(0.392, 0.769, 0.910))  # SKY_BLUE
	_dots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dots_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_dots_label)


# ── Process ────────────────────────────────────────────────────────────────────


func _process(delta: float) -> void:
	_elapsed += delta
	_dot_elapsed += delta

	# Animate dots
	if _dot_elapsed >= 0.4:
		_dot_elapsed = 0.0
		_dot_count = (_dot_count % 3) + 1
		_dots_label.text = ".".repeat(_dot_count)

	# Check minimum display time
	if not _min_time_passed and _elapsed >= MIN_SHOW_TIME:
		_min_time_passed = true
		_try_navigate()

	# Auth timeout — treat as not logged in and proceed to AuthScreen
	if not _auth_resolved and _elapsed >= AUTH_TIMEOUT:
		_auth_resolved = true
		_auth_result = false
		_try_navigate()


# ── Auth Callback ──────────────────────────────────────────────────────────────


func _on_auth_state_changed(logged_in: bool) -> void:
	_auth_resolved = true
	_auth_result = logged_in
	_try_navigate()


# ── Navigation ─────────────────────────────────────────────────────────────────


func _try_navigate() -> void:
	if _navigating or not _min_time_passed or not _auth_resolved:
		return
	_navigating = true
	set_process(false)

	# Fade out before switching scenes
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	tw.tween_callback(func() -> void: _change_scene(_auth_result))


func _change_scene(logged_in: bool) -> void:
	if not logged_in:
		get_tree().change_scene_to_file("res://scenes/AuthScreen.tscn")
		return

	# Hydrate full profile (student + unlocked buildings + story progress)
	# from the backend in one round trip. NetworkGate blocks the modal
	# until the call succeeds, so we never enter Main with stale state.
	NetworkGate.run(
		func(cb: Callable) -> void: ApiClient.fetch_profile(cb),
		func(data: Dictionary) -> void:
			if data.has("error"):
				get_tree().change_scene_to_file("res://scenes/AuthScreen.tscn")
				return
			GameManager.hydrate_from_profile(data)
			var onboarded: bool = bool(data.get("onboardingDone", false))
			if not onboarded:
				get_tree().change_scene_to_file("res://scenes/OnboardingScreen.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/Main.tscn")
	)
