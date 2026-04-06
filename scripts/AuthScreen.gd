extends Control
## AuthScreen — Cloud-authenticated Sign In / Sign Up screen.
## Students login with email+password or Google OAuth.
## Replaces the previous PIN-based local auth.

enum View { LANDING, SIGN_IN, SIGN_UP, LOADING }

# ── State ──────────────────────────────────────────────────────────────────────
var _current_view: View = View.LANDING
var _transitioning: bool = false
var _google_session_id: String = ""
var _google_poll_timer: Timer
var _google_polling: bool = false
var _google_retry_btn: Button

# ── Dynamically created view containers ───────────────────────────────────────
var _landing_view: VBoxContainer
var _signin_view: VBoxContainer
var _signup_view: VBoxContainer
var _loading_view: VBoxContainer

# ── Form inputs ───────────────────────────────────────────────────────────────
var _signin_email: LineEdit
var _signin_password: LineEdit
var _signin_error: Label
var _signin_button: Button

var _signup_name: LineEdit
var _signup_email: LineEdit
var _signup_password: LineEdit
var _signup_confirm: LineEdit
var _signup_error: Label
var _signup_button: Button

var _loading_label: Label

var _content_card: PanelContainer
var _card_margin: MarginContainer


func _ready() -> void:
	theme = ThemeBuilder.build()

	# Check if already authenticated
	if ApiClient.is_authenticated:
		_proceed_to_game()
		return

	# Listen for auth changes (e.g., from Google OAuth completing)
	ApiClient.auth_state_changed.connect(func(logged_in: bool) -> void:
		if logged_in:
			_proceed_to_game()
	)

	_setup_ui()
	_animate_entrance()


func _setup_ui() -> void:
	_content_card = $ContentCard
	_content_card.add_theme_stylebox_override("panel", StyleFactory.make_glass_card())

	_card_margin = $ContentCard/CardMargin

	# Remove old views (they're from the PIN-based scene)
	for child in _card_margin.get_children():
		child.queue_free()

	# Wait a frame for queue_free to complete
	await get_tree().process_frame

	# Build new views
	_build_landing_view()
	_build_signin_view()
	_build_signup_view()
	_build_loading_view()

	_show_view_instant(View.LANDING)

	# Style title
	_style_title()


# ── Build Views ──────────────────────────────────────────────────────────────

func _build_landing_view() -> void:
	_landing_view = VBoxContainer.new()
	_landing_view.name = "LandingView"
	_landing_view.alignment = BoxContainer.ALIGNMENT_CENTER
	_landing_view.add_theme_constant_override("separation", 16)
	_card_margin.add_child(_landing_view)

	var welcome_label := Label.new()
	welcome_label.text = "Welcome!"
	welcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome_label.add_theme_font_size_override("font_size", 32)
	welcome_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_landing_view.add_child(welcome_label)

	var desc_label := Label.new()
	desc_label.text = "Sign in to start your reading adventure"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_landing_view.add_child(desc_label)

	_landing_view.add_child(_make_spacer(20))

	var signin_btn := Button.new()
	signin_btn.text = "Sign In"
	signin_btn.custom_minimum_size = Vector2(0, 56)
	_style_primary_button(signin_btn)
	signin_btn.pressed.connect(func(): _switch_view(View.SIGN_IN))
	_landing_view.add_child(signin_btn)

	var signup_btn := Button.new()
	signup_btn.text = "Create Account"
	signup_btn.custom_minimum_size = Vector2(0, 56)
	_style_secondary_button(signup_btn)
	signup_btn.pressed.connect(func(): _switch_view(View.SIGN_UP))
	_landing_view.add_child(signup_btn)

	_landing_view.add_child(_make_spacer(8))

	var or_label := Label.new()
	or_label.text = "─── or ───"
	or_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	or_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_landing_view.add_child(or_label)

	var google_btn := Button.new()
	google_btn.text = "Sign in with Google"
	google_btn.custom_minimum_size = Vector2(0, 56)
	_style_google_button(google_btn)
	google_btn.pressed.connect(_on_google_signin)
	_landing_view.add_child(google_btn)


func _build_signin_view() -> void:
	_signin_view = VBoxContainer.new()
	_signin_view.name = "SignInView"
	_signin_view.alignment = BoxContainer.ALIGNMENT_CENTER
	_signin_view.add_theme_constant_override("separation", 12)
	_card_margin.add_child(_signin_view)

	var title := Label.new()
	title.text = "Sign In"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_signin_view.add_child(title)

	_signin_view.add_child(_make_spacer(8))

	_signin_email = _make_input("Email address")
	_signin_view.add_child(_signin_email)

	_signin_password = _make_input("Password", true)
	_signin_view.add_child(_signin_password)

	_signin_error = _make_error_label()
	_signin_view.add_child(_signin_error)

	_signin_button = Button.new()
	_signin_button.text = "Sign In"
	_signin_button.custom_minimum_size = Vector2(0, 56)
	_style_primary_button(_signin_button)
	_signin_button.pressed.connect(_on_signin_pressed)
	_signin_view.add_child(_signin_button)

	var back_btn := _make_back_button()
	back_btn.pressed.connect(func(): _switch_view(View.LANDING))
	_signin_view.add_child(back_btn)


func _build_signup_view() -> void:
	_signup_view = VBoxContainer.new()
	_signup_view.name = "SignUpView"
	_signup_view.alignment = BoxContainer.ALIGNMENT_CENTER
	_signup_view.add_theme_constant_override("separation", 10)
	_card_margin.add_child(_signup_view)

	var title := Label.new()
	title.text = "Create Account"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_signup_view.add_child(title)

	_signup_view.add_child(_make_spacer(4))

	_signup_name = _make_input("Your name")
	_signup_view.add_child(_signup_name)

	_signup_email = _make_input("Email address")
	_signup_view.add_child(_signup_email)

	_signup_password = _make_input("Password (min 6 chars)", true)
	_signup_view.add_child(_signup_password)

	_signup_confirm = _make_input("Confirm password", true)
	_signup_view.add_child(_signup_confirm)

	_signup_error = _make_error_label()
	_signup_view.add_child(_signup_error)

	_signup_button = Button.new()
	_signup_button.text = "Create Account"
	_signup_button.custom_minimum_size = Vector2(0, 56)
	_style_primary_button(_signup_button)
	_signup_button.pressed.connect(_on_signup_pressed)
	_signup_view.add_child(_signup_button)

	var back_btn := _make_back_button()
	back_btn.pressed.connect(func(): _switch_view(View.LANDING))
	_signup_view.add_child(back_btn)


func _build_loading_view() -> void:
	_loading_view = VBoxContainer.new()
	_loading_view.name = "LoadingView"
	_loading_view.alignment = BoxContainer.ALIGNMENT_CENTER
	_loading_view.add_theme_constant_override("separation", 16)
	_card_margin.add_child(_loading_view)

	_loading_label = Label.new()
	_loading_label.text = "Signing in..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_size_override("font_size", 24)
	_loading_label.add_theme_color_override("font_color", StyleFactory.TEXT_SECONDARY)
	_loading_view.add_child(_loading_label)

	_google_retry_btn = Button.new()
	_google_retry_btn.text = "Try Again"
	_google_retry_btn.visible = false
	_google_retry_btn.pressed.connect(_on_google_retry)
	_loading_view.add_child(_google_retry_btn)


# ── UI Helpers ───────────────────────────────────────────────────────────────

func _make_input(placeholder: String, secret: bool = false) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size = Vector2(0, 52)
	input.secret = secret
	input.add_theme_font_size_override("font_size", 22)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.08)
	style.border_color = Color(1, 1, 1, 0.15)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16
	style.content_margin_right = 16
	input.add_theme_stylebox_override("normal", style)
	var focus_style := style.duplicate()
	focus_style.border_color = StyleFactory.ACCENT_CORAL
	input.add_theme_stylebox_override("focus", focus_style)
	return input


func _make_error_label() -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.visible = false
	return lbl


func _make_back_button() -> Button:
	var btn := Button.new()
	btn.text = "← Back"
	btn.custom_minimum_size = Vector2(0, 40)
	var transparent := StyleBoxFlat.new()
	transparent.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", transparent)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.05)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", transparent)
	btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	btn.add_theme_color_override("font_hover_color", StyleFactory.TEXT_SECONDARY)
	return btn


func _make_spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer


# ── Button Styling ───────────────────────────────────────────────────────────

func _style_primary_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	btn.add_theme_stylebox_override("disabled", StyleFactory.make_disabled_button())
	UIAnimations.make_interactive(btn)


func _style_secondary_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	UIAnimations.make_interactive(btn)


func _style_google_button(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.95, 0.95, 0.95, 1.0)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	btn.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1))
	UIAnimations.make_interactive(btn)


func _style_title() -> void:
	var title: Label = $BrandingLayer/TitleLabel
	var font := ThemeBuilder.load_font("res://assets/fonts/Nunito-Variable.ttf")
	if font:
		title.add_theme_font_override("font", font)
		$BrandingLayer/SubtitleLabel.add_theme_font_override("font", font)


func _animate_entrance() -> void:
	var branding: VBoxContainer = $BrandingLayer
	branding.modulate.a = 0.0
	branding.position.y -= 30
	var original_y: float = branding.position.y + 30

	var tw := create_tween().set_parallel(true)
	tw.tween_property(branding, "modulate:a", 1.0, 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
		.set_delay(0.1)
	tw.tween_property(branding, "position:y", original_y, 0.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) \
		.set_delay(0.1)

	_content_card.modulate.a = 0.0
	var card_orig_y: float = _content_card.position.y
	_content_card.position.y += 50
	tw.tween_property(_content_card, "modulate:a", 1.0, 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
		.set_delay(0.25)
	tw.tween_property(_content_card, "position:y", card_orig_y, 0.55) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) \
		.set_delay(0.25)


# ── View Management ──────────────────────────────────────────────────────────

func _get_view_node(v: View) -> Control:
	match v:
		View.LANDING: return _landing_view
		View.SIGN_IN: return _signin_view
		View.SIGN_UP: return _signup_view
		View.LOADING: return _loading_view
	return _landing_view


func _show_view_instant(v: View) -> void:
	if _landing_view: _landing_view.visible = (v == View.LANDING)
	if _signin_view: _signin_view.visible = (v == View.SIGN_IN)
	if _signup_view: _signup_view.visible = (v == View.SIGN_UP)
	if _loading_view: _loading_view.visible = (v == View.LOADING)
	_current_view = v


func _switch_view(new_view: View) -> void:
	if _transitioning or new_view == _current_view:
		return
	_transitioning = true

	var old_node := _get_view_node(_current_view)
	var new_node := _get_view_node(new_view)

	await UIAnimations.crossfade(self, old_node, new_node, 0.3)
	_current_view = new_view
	_transitioning = false


# ── Auth Handlers ────────────────────────────────────────────────────────────

func _on_signin_pressed() -> void:
	var email := _signin_email.text.strip_edges()
	var password := _signin_password.text

	if email.is_empty() or password.is_empty():
		_signin_error.text = "Please fill in all fields."
		_signin_error.visible = true
		return

	_signin_error.visible = false
	_signin_button.disabled = true
	_signin_button.text = "Signing in..."

	ApiClient.login(email, password, func(success: bool, data: Dictionary) -> void:
		_signin_button.disabled = false
		_signin_button.text = "Sign In"

		if success:
			UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.12))
			await get_tree().create_timer(0.4).timeout
			_proceed_to_game()
		else:
			_signin_error.text = data.get("error", "Login failed. Please try again.")
			_signin_error.visible = true
	)


func _on_signup_pressed() -> void:
	var player_name := _signup_name.text.strip_edges()
	var email := _signup_email.text.strip_edges()
	var password := _signup_password.text
	var confirm := _signup_confirm.text

	if player_name.is_empty() or email.is_empty() or password.is_empty():
		_signup_error.text = "Please fill in all fields."
		_signup_error.visible = true
		return

	if password.length() < 6:
		_signup_error.text = "Password must be at least 6 characters."
		_signup_error.visible = true
		return

	if password != confirm:
		_signup_error.text = "Passwords do not match."
		_signup_error.visible = true
		return

	_signup_error.visible = false
	_signup_button.disabled = true
	_signup_button.text = "Creating account..."

	ApiClient.register(email, password, player_name, func(success: bool, data: Dictionary) -> void:
		_signup_button.disabled = false
		_signup_button.text = "Create Account"

		if success:
			UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.12))
			await get_tree().create_timer(0.4).timeout
			_proceed_to_game()
		else:
			_signup_error.text = data.get("error", "Registration failed. Please try again.")
			_signup_error.visible = true
	)


func _on_google_signin() -> void:
	_loading_label.text = "Opening Google Sign-In..."
	_switch_view(View.LOADING)

	ApiClient.google_auth_start(func(success: bool, data: Dictionary) -> void:
		if success and data.has("sessionId"):
			_google_session_id = data["sessionId"]
			_loading_label.text = "Complete sign-in in your browser...\nThen return to the app."
			_start_google_poll()
		else:
			_loading_label.text = "Failed to start Google Sign-In.\nPlease try again."
			await get_tree().create_timer(2.0).timeout
			_switch_view(View.LANDING)
	)


func _start_google_poll() -> void:
	if _google_poll_timer:
		_google_poll_timer.queue_free()

	_google_polling = true
	_google_retry_btn.visible = false

	_google_poll_timer = Timer.new()
	_google_poll_timer.wait_time = 2.0
	_google_poll_timer.autostart = true
	var poll_state := [0]  # [count] — array ref so lambda can mutate it
	var max_polls := 150  # 5 minutes at 2s intervals

	_google_poll_timer.timeout.connect(func() -> void:
		poll_state[0] += 1
		if poll_state[0] > max_polls:
			_google_polling = false
			_google_retry_btn.visible = false
			_google_poll_timer.stop()
			_loading_label.text = "Sign-in timed out. Please try again."
			await get_tree().create_timer(2.0).timeout
			_switch_view(View.LANDING)
			return

		ApiClient.google_auth_poll(_google_session_id, func(success: bool, data: Dictionary) -> void:
			if success and data.get("status") == "completed":
				_google_polling = false
				_google_poll_timer.stop()
				UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.12))
				# ApiClient will update auth state, which triggers _proceed_to_game via signal
		)
	)
	add_child(_google_poll_timer)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN and _google_polling:
		_show_retry_option()


func _show_retry_option() -> void:
	_loading_label.text = "Complete sign-in in your browser.\nIf you exited, tap Try Again."
	_google_retry_btn.visible = true


func _on_google_retry() -> void:
	_google_polling = false
	_google_retry_btn.visible = false
	if _google_poll_timer:
		_google_poll_timer.stop()
		_google_poll_timer.queue_free()
		_google_poll_timer = null
	_google_session_id = ""
	_switch_view(View.LANDING)


# ── Navigation ───────────────────────────────────────────────────────────────

func _proceed_to_game() -> void:
	if _google_poll_timer:
		_google_poll_timer.stop()
		_google_poll_timer.queue_free()
		_google_poll_timer = null

	# Set GameManager state from ApiClient
	var student := ApiClient.current_student
	if not student.is_empty():
		GameManager.set_current_student(student)

	# Check onboarding
	var onboarding_done = student.get("onboardingDone", false)
	if onboarding_done is int:
		onboarding_done = onboarding_done != 0
	if not onboarding_done:
		get_tree().change_scene_to_file("res://scenes/OnboardingScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
