extends Control
## OnboardingScreen — Beautiful welcome slides + placement quiz.
## Shown only once per student (onboarding_done == 0).
## Quiz assigns reading level 1-4, saved to DB on completion.

# ── Placement Quiz Data ────────────────────────────────────────────────────────
const QUIZ_QUESTIONS: Array[Dictionary] = [
	{
		"type": "multiple_choice",
		"passage":
		"Maria opened the old book carefully. The pages were yellow and smelled like rain. She smiled because her grandmother used to read this same book to her.",
		"question": "Why did Maria smile when she opened the book?",
		"options":
		[
			"She found money inside.",
			"It reminded her of her grandmother.",
			"The book was new and colorful.",
			"She had never seen a book before."
		],
		"correct_index": 1,
		"feedback_correct": "That's right! The old book reminded Maria of her grandmother.",
		"feedback_wrong":
		"The passage says she smiled because her grandmother used to read it to her."
	},
	{
		"type": "multiple_choice",
		"passage":
		"The school library was the quietest place in the village. Students whispered to each other between the tall shelves. Sunlight came through one narrow window and made a long stripe across the dusty floor.",
		"question": 'What does the word "narrow" most likely mean in this passage?',
		"options": ["Very wide", "Very old", "Not wide", "Very bright"],
		"correct_index": 2,
		"feedback_correct": "Excellent! A narrow window lets in only a thin stripe of light.",
		"feedback_wrong": '"Narrow" means not wide. The single stripe of light is a clue.'
	},
	{
		"type": "fill_blank",
		"passage": "The cat sat on the mat. It was a fat cat.",
		"sentence": "The cat sat on the ___.",
		"answer": "mat",
		"feedback_correct": "Well done! The cat sat on the mat.",
		"feedback_wrong": "The passage says 'The cat sat on the mat.'"
	},
	{
		"type": "fill_blank",
		"passage":
		"The brave knight crossed the bridge. He carried a shining sword and a round shield.",
		"sentence": "The knight carried a shining ___ and a round shield.",
		"answer": "sword",
		"feedback_correct": "Correct! The knight carried a shining sword.",
		"feedback_wrong": "Look at what the knight carried — it was a shining sword."
	},
	{
		"type": "drag_drop",
		"passage": "Read the words below and arrange them to make a proper sentence.",
		"question": "Arrange these words into a correct sentence:",
		"words": ["the", "village", "beautiful", "was", "very"],
		"correct_order": ["the", "village", "was", "very", "beautiful"],
		"feedback_correct": 'Perfect! "The village was very beautiful."',
		"feedback_wrong": "The correct order is: the village was very beautiful."
	}
]

const LEVEL_NAMES: Dictionary = {
	1: "Non-Reader", 2: "Emerging Reader", 3: "Developing Reader", 4: "Independent Reader"
}

const LEVEL_DESCRIPTIONS: Dictionary = {
	1: "We will start with simple words and short stories to build your confidence.",
	2: "You are making great progress! We will practice reading sentences together.",
	3: "You are a growing reader! We will tackle longer passages and new vocabulary.",
	4: "Excellent! You will face the most challenging quests in the village!"
}

const LEVEL_COLORS: Dictionary = {
	1: Color(0.914, 0.388, 0.431),  # coral
	2: Color(0.392, 0.769, 0.910),  # sky blue
	3: Color(0.357, 0.851, 0.635),  # seafoam
	4: Color(0.886, 0.725, 0.290),  # gold
}

# Accent colors per slide for illustration panels
const SLIDE_COLORS: Array[Color] = [
	Color(0.914, 0.388, 0.431),  # coral
	Color(0.357, 0.851, 0.635),  # seafoam
	Color(0.886, 0.725, 0.290),  # gold
]

# ── State ─────────────────────────────────────��────────────────────────────────
var _current_slide: int = 0
var _current_q: int = 0
var _score: int = 0
var _drag_order: Array[String] = []
var _word_bank_words: Array[String] = []
var _transitioning: bool = false
var _username: String = ""
var _character_gender: String = ""  # "male" or "female"

# ── Node refs ──────────────────────────────────────────────────────────────────
@onready var _slide_container: Control = $SlideContainer
@onready
var _slides: Array = [$SlideContainer/Slide1, $SlideContainer/Slide2, $SlideContainer/Slide3]
@onready var _slide_dots: Array = [
	$SlideControls/DotRow/SlideDot1,
	$SlideControls/DotRow/SlideDot2,
	$SlideControls/DotRow/SlideDot3
]
@onready var _prev_btn: Button = $SlideControls/PrevButton
@onready var _next_btn: Button = $SlideControls/NextButton

@onready var _quiz_container: Control = $QuizContainer
@onready var _quiz_title: Label = $QuizContainer/QuizHeader/QuizTitle
@onready var _quiz_progress: ProgressBar = $QuizContainer/QuizHeader/QuizProgressBar
@onready var _passage_card: PanelContainer = $QuizContainer/PassageCard
@onready var _passage_label: RichTextLabel = $QuizContainer/PassageCard/PassageMargin/PassageLabel
@onready var _question_label: Label = $QuizContainer/QuestionLabel

@onready var _mc_container: VBoxContainer = $QuizContainer/MCContainer
@onready var _fill_container: VBoxContainer = $QuizContainer/FillBlankContainer
@onready var _drag_container: Control = $QuizContainer/DragDropContainer
@onready var _feedback_panel: Panel = $QuizContainer/FeedbackPanel
@onready var _feedback_icon: Label = $QuizContainer/FeedbackPanel/FeedbackIcon
@onready var _feedback_text: Label = $QuizContainer/FeedbackPanel/FeedbackText
@onready var _next_q_btn: Button = $QuizContainer/FeedbackPanel/NextQuestionButton

@onready var _fill_sentence: Label = $QuizContainer/FillBlankContainer/SentenceLabel
@onready var _fill_input: LineEdit = $QuizContainer/FillBlankContainer/BlankInput

@onready var _drag_word_bank: HBoxContainer = $QuizContainer/DragDropContainer/WordBank
@onready var _drag_drop_zone: HBoxContainer = $QuizContainer/DragDropContainer/DropZone

# ── Username + Character Selection refs ────────────────────────────────────────
@onready var _username_container: Control = $UsernameContainer
@onready var _username_input: LineEdit = $UsernameContainer/UsernameCard/CardContent/UsernameInput
@onready var _username_error: Label = $UsernameContainer/UsernameCard/CardContent/UsernameError
@onready
var _username_continue: Button = $UsernameContainer/UsernameCard/CardContent/UsernameContinue

@onready var _character_container: Control = $CharacterContainer
@onready
var _male_frame: PanelContainer = $CharacterContainer/CharacterCard/CardContent/CharacterRow/MaleOption/MaleFrame
@onready
var _female_frame: PanelContainer = $CharacterContainer/CharacterCard/CardContent/CharacterRow/FemaleOption/FemaleFrame
@onready
var _male_preview: TextureRect = $CharacterContainer/CharacterCard/CardContent/CharacterRow/MaleOption/MaleFrame/MalePreview
@onready
var _female_preview: TextureRect = $CharacterContainer/CharacterCard/CardContent/CharacterRow/FemaleOption/FemaleFrame/FemalePreview
@onready
var _male_select_btn: Button = $CharacterContainer/CharacterCard/CardContent/CharacterRow/MaleOption/MaleSelectBtn
@onready
var _female_select_btn: Button = $CharacterContainer/CharacterCard/CardContent/CharacterRow/FemaleOption/FemaleSelectBtn
@onready var _selected_label: Label = $CharacterContainer/CharacterCard/CardContent/SelectedLabel
@onready
var _character_continue: Button = $CharacterContainer/CharacterCard/CardContent/CharacterContinue

@onready var _result_panel: Panel = $ResultPanel
@onready var _result_title: Label = $ResultPanel/ResultTitle
@onready var _result_level_name: Label = $ResultPanel/LevelName
@onready var _result_level_desc: Label = $ResultPanel/LevelDesc
@onready var _result_badge: Panel = $ResultPanel/LevelBadge
@onready var _result_badge_label: Label = $ResultPanel/LevelBadge/BadgeLabel
@onready var _start_btn: Button = $ResultPanel/StartAdventureButton

# ── Lifecycle ─��───────────────────────────���────────────────────────────────────


func _ready() -> void:
	theme = ThemeBuilder.build()

	_quiz_container.visible = false
	_result_panel.visible = false
	_username_container.visible = false
	_character_container.visible = false

	# Style new step cards
	_setup_username_step()
	_setup_character_step()

	# Style illustration panels per slide
	_style_illustrations()

	# Style buttons
	_style_slide_buttons()
	_style_quiz_buttons()

	# Style passage card
	_passage_card.add_theme_stylebox_override(
		"panel", StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 14, 1)
	)

	# Style result panel
	_result_panel.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(20))
	_style_primary($ResultPanel/StartAdventureButton)

	_show_slide_instant(0)
	_connect_controls()

	# Entrance animation
	_animate_entrance()


func _style_illustrations() -> void:
	for i in _slides.size():
		var panel: PanelContainer = _slides[i].get_node("IllustrationPanel")
		var style := StyleBoxFlat.new()
		style.bg_color = SLIDE_COLORS[i].darkened(0.6)
		style.corner_radius_top_left = 20
		style.corner_radius_top_right = 20
		style.corner_radius_bottom_left = 20
		style.corner_radius_bottom_right = 20
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		var border_col := SLIDE_COLORS[i].lightened(0.2)
		border_col.a = 0.3
		style.border_color = border_col
		var shadow_col: Color = SLIDE_COLORS[i]
		shadow_col.a = 0.15
		style.shadow_color = shadow_col
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 4)
		style.anti_aliasing = true
		panel.add_theme_stylebox_override("panel", style)


func _style_slide_buttons() -> void:
	_style_primary(_next_btn)
	_style_secondary(_prev_btn)


func _style_quiz_buttons() -> void:
	# MC options
	for opt in [
		$QuizContainer/MCContainer/MCOptionA,
		$QuizContainer/MCContainer/MCOptionB,
		$QuizContainer/MCContainer/MCOptionC,
		$QuizContainer/MCContainer/MCOptionD
	]:
		opt.add_theme_stylebox_override("normal", StyleFactory.make_student_card_normal())
		opt.add_theme_stylebox_override("hover", StyleFactory.make_student_card_hover())
		opt.add_theme_stylebox_override("pressed", StyleFactory.make_student_card_pressed())
		UIAnimations.make_interactive(opt)

	# Fill blank submit
	_style_primary($QuizContainer/FillBlankContainer/SubmitFillButton)
	# Drag submit
	_style_primary($QuizContainer/DragDropContainer/SubmitDragButton)
	# Next question
	_style_primary(_next_q_btn)


func _style_primary(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	btn.add_theme_stylebox_override("disabled", StyleFactory.make_disabled_button())
	UIAnimations.make_interactive(btn)


func _style_secondary(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	UIAnimations.make_interactive(btn)


func _animate_entrance() -> void:
	var slide: Control = _slides[0]
	slide.modulate.a = 0.0
	var tw := create_tween()
	(
		tw
		. tween_property(slide, "modulate:a", 1.0, 0.5)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
		. set_delay(0.15)
	)


func _connect_controls() -> void:
	$SlideControls/PrevButton.pressed.connect(func(): _navigate_slide(-1))
	$SlideControls/NextButton.pressed.connect(_on_next_pressed)

	_connect_mc_buttons()
	$QuizContainer/FillBlankContainer/SubmitFillButton.pressed.connect(_on_fill_submitted)
	$QuizContainer/DragDropContainer/SubmitDragButton.pressed.connect(_on_drag_submitted)
	_next_q_btn.pressed.connect(_on_next_question_pressed)
	_start_btn.pressed.connect(_on_start_adventure_pressed)


# ── Slides ──────────────────────────────────────��──────────────────────────────


func _show_slide_instant(index: int) -> void:
	_current_slide = clampi(index, 0, 2)
	for i in _slides.size():
		_slides[i].visible = (i == _current_slide)
	_update_slide_ui()


func _update_slide_ui() -> void:
	UIAnimations.update_page_dots(self, _slide_dots, _current_slide)
	_prev_btn.visible = (_current_slide > 0)
	_next_btn.text = "Start Quiz  →" if _current_slide == 2 else "Next  →"


func _navigate_slide(direction: int) -> void:
	if _transitioning:
		return
	var new_index := clampi(_current_slide + direction, 0, 2)
	if new_index == _current_slide:
		return

	_transitioning = true
	var old_slide: Control = _slides[_current_slide]
	var new_slide: Control = _slides[new_index]
	_current_slide = new_index

	_update_slide_ui()
	await UIAnimations.slide_horizontal(self, old_slide, new_slide, direction)
	_transitioning = false


func _on_next_pressed() -> void:
	if _current_slide < 2:
		_navigate_slide(1)
	else:
		_show_username_step()


# ── Username Step ──────────────────────────────────────────────────────────────


func _setup_username_step() -> void:
	# Style card
	$UsernameContainer/UsernameCard.add_theme_stylebox_override(
		"panel", StyleFactory.make_glass_card(20)
	)
	_style_primary(_username_continue)
	_username_input.text_changed.connect(_on_username_text_changed)
	_username_continue.pressed.connect(_on_username_continue)


func _on_username_text_changed(new_text: String) -> void:
	var stripped := new_text.strip_edges()
	_username_continue.disabled = stripped.length() < 2
	if stripped.length() > 0 and stripped.length() < 2:
		_username_error.text = "Username must be at least 2 characters"
		_username_error.visible = true
	else:
		_username_error.visible = false


func _show_username_step() -> void:
	_transitioning = true
	# Fade out slides + controls
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_slide_container, "modulate:a", 0.0, 0.3)
	tw.tween_property($SlideControls, "modulate:a", 0.0, 0.3)
	await tw.finished

	_slide_container.visible = false
	$SlideControls.visible = false
	_username_container.visible = true
	_username_container.modulate.a = 0.0

	var tw2 := create_tween()
	(
		tw2
		. tween_property(_username_container, "modulate:a", 1.0, 0.35)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	await tw2.finished
	_transitioning = false
	_username_input.grab_focus()


func _on_username_continue() -> void:
	var stripped := _username_input.text.strip_edges()
	if stripped.length() < 2:
		_username_error.text = "Username must be at least 2 characters"
		_username_error.visible = true
		return
	_username = stripped
	_show_character_select()


# ── Character Selection Step ───────────────────────────────────────────────────


func _setup_character_step() -> void:
	# Style card
	$CharacterContainer/CharacterCard.add_theme_stylebox_override(
		"panel", StyleFactory.make_glass_card(20)
	)

	# Load sprite previews with nearest-neighbor filtering (crisp pixel art)
	var male_tex := load("res://assets/sprites/character/player.png")
	var female_tex := load("res://assets/sprites/character/player_female.png")
	_male_preview.texture = male_tex
	_female_preview.texture = female_tex

	# Style frames
	var frame_style := StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 16, 1)
	_male_frame.add_theme_stylebox_override("panel", frame_style)
	_female_frame.add_theme_stylebox_override("panel", frame_style.duplicate())

	# Style buttons
	_style_secondary(_male_select_btn)
	_style_secondary(_female_select_btn)
	_style_primary(_character_continue)

	# Connect
	_male_select_btn.pressed.connect(func(): _on_character_selected("male"))
	_female_select_btn.pressed.connect(func(): _on_character_selected("female"))
	_character_continue.pressed.connect(_on_character_continue)


func _show_character_select() -> void:
	_transitioning = true
	# Fade out username
	var tw := create_tween()
	tw.tween_property(_username_container, "modulate:a", 0.0, 0.25)
	await tw.finished
	_username_container.visible = false

	_character_container.visible = true
	_character_container.modulate.a = 0.0
	var tw2 := create_tween()
	(
		tw2
		. tween_property(_character_container, "modulate:a", 1.0, 0.35)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	await tw2.finished
	_transitioning = false


func _on_character_selected(gender: String) -> void:
	_character_gender = gender
	_character_continue.disabled = false

	# Highlight selected frame, dim the other
	var selected_frame: PanelContainer = _male_frame if gender == "male" else _female_frame
	var other_frame: PanelContainer = _female_frame if gender == "male" else _male_frame

	var active_style := StyleFactory.make_elevated_card(StyleFactory.BG_SURFACE, 16, 2)
	active_style.border_width_top = 3
	active_style.border_width_left = 3
	active_style.border_width_right = 3
	active_style.border_width_bottom = 3
	active_style.border_color = StyleFactory.ACCENT_CORAL
	selected_frame.add_theme_stylebox_override("panel", active_style)

	var dim_style := StyleFactory.make_elevated_card(StyleFactory.BG_CARD, 16, 1)
	other_frame.add_theme_stylebox_override("panel", dim_style)

	_selected_label.text = "Selected: %s" % ("Boy" if gender == "male" else "Girl")
	_selected_label.visible = true


func _on_character_continue() -> void:
	if _character_gender.is_empty():
		return

	# Save username + character_gender to DB
	var student: Dictionary = GameManager.current_student
	if not student.is_empty():
		DatabaseManager.update_student_profile(student.id, _username, _character_gender)
		GameManager.current_student["username"] = _username
		GameManager.current_student["character_gender"] = _character_gender

	# Transition to quiz
	_transitioning = true
	var tw := create_tween()
	tw.tween_property(_character_container, "modulate:a", 0.0, 0.25)
	await tw.finished
	_character_container.visible = false

	_quiz_container.visible = true
	_quiz_container.modulate.a = 0.0
	_score = 0
	_current_q = 0

	var tw2 := create_tween()
	(
		tw2
		. tween_property(_quiz_container, "modulate:a", 1.0, 0.35)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	await tw2.finished
	_transitioning = false
	_load_question(0)


# ── Quiz ────────────��─────────────────────────��────────────────────────────────


func _load_question(index: int) -> void:
	_feedback_panel.visible = false
	_mc_container.visible = false
	_fill_container.visible = false
	_drag_container.visible = false

	var q := QUIZ_QUESTIONS[index]
	_quiz_title.text = "Question %d / %d" % [index + 1, QUIZ_QUESTIONS.size()]

	# Animate progress bar
	var target_val := float(index) / float(QUIZ_QUESTIONS.size()) * 100.0
	var tw := create_tween()
	(
		tw
		. tween_property(_quiz_progress, "value", target_val, 0.4)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_IN_OUT)
	)

	_passage_label.text = q.get("passage", "")

	# Wait a frame for RichTextLabel to calculate content height, then resize card
	await get_tree().process_frame
	var content_h: float = _passage_label.get_content_height()
	var card_h: float = content_h + 48.0  # 16 top + 16 bottom margin + 16 padding
	_passage_card.offset_bottom = _passage_card.offset_top + maxf(card_h, 140.0)

	# Reposition elements below the card
	var below_card: float = _passage_card.offset_bottom + 12.0
	_question_label.offset_top = below_card
	_question_label.offset_bottom = below_card + 50.0
	var answers_top: float = _question_label.offset_bottom + 10.0
	_mc_container.offset_top = answers_top
	_fill_container.offset_top = answers_top
	_drag_container.offset_top = answers_top

	match q.type:
		"multiple_choice":
			_populate_mc(q)
		"fill_blank":
			_populate_fill_blank(q)
		"drag_drop":
			_populate_drag_drop(q)


func _connect_mc_buttons() -> void:
	var btns := [
		$QuizContainer/MCContainer/MCOptionA,
		$QuizContainer/MCContainer/MCOptionB,
		$QuizContainer/MCContainer/MCOptionC,
		$QuizContainer/MCContainer/MCOptionD,
	]
	for i in btns.size():
		var captured := i
		btns[i].pressed.connect(func(): _on_mc_pressed(captured))


func _on_mc_pressed(index: int) -> void:
	var q := QUIZ_QUESTIONS[_current_q]
	var correct: bool = index == (q.correct_index as int)
	if correct:
		_score += 1
	_show_feedback(
		correct, q.get("feedback_correct", "") if correct else q.get("feedback_wrong", "")
	)


func _populate_mc(q: Dictionary) -> void:
	_question_label.text = q.question
	_mc_container.visible = true
	var option_buttons := [
		$QuizContainer/MCContainer/MCOptionA,
		$QuizContainer/MCContainer/MCOptionB,
		$QuizContainer/MCContainer/MCOptionC,
		$QuizContainer/MCContainer/MCOptionD
	]
	for i in option_buttons.size():
		option_buttons[i].text = q.options[i]
		option_buttons[i].disabled = false
		option_buttons[i].remove_theme_color_override("font_color")

	# Stagger MC option entrance (fade only — position breaks VBoxContainer layout)
	var idx := 0
	for btn in option_buttons:
		btn.modulate.a = 0.0
		var tw := create_tween()
		(
			tw
			. tween_property(btn, "modulate:a", 1.0, 0.25)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
			. set_delay(idx * 0.07)
		)
		idx += 1


func _populate_fill_blank(q: Dictionary) -> void:
	_question_label.text = ""
	_fill_container.visible = true
	_fill_sentence.text = q.sentence
	_fill_input.text = ""
	_fill_input.placeholder_text = "Type your answer here"


func _populate_drag_drop(q: Dictionary) -> void:
	_question_label.text = q.get("question", "Arrange the words in the correct order:")
	_drag_container.visible = true
	_drag_order = []

	for child in _drag_word_bank.get_children():
		child.queue_free()
	for child in _drag_drop_zone.get_children():
		child.queue_free()

	_word_bank_words.assign(q.words.duplicate())
	_word_bank_words.shuffle()
	for word in _word_bank_words:
		_add_chip_to_bank(word)


func _add_chip_to_bank(word: String) -> void:
	var btn := Button.new()
	btn.text = word
	btn.custom_minimum_size = Vector2(90, 52)
	btn.add_theme_font_size_override("font_size", 24)
	# Bank chip style: sky blue tint
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.392, 0.769, 0.910, 0.15)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.392, 0.769, 0.910, 0.3)
	style.anti_aliasing = true
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.392, 0.769, 0.910, 0.25)
	btn.add_theme_stylebox_override("hover", hover)
	UIAnimations.make_interactive(btn)

	var captured := word
	btn.pressed.connect(func(): _on_word_chip_pressed(captured, btn))
	_drag_word_bank.add_child(btn)


func _add_chip_to_zone(word: String) -> void:
	var btn := Button.new()
	btn.text = word
	btn.custom_minimum_size = Vector2(90, 52)
	btn.add_theme_font_size_override("font_size", 24)
	# Placed chip style: coral tint
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.914, 0.388, 0.431, 0.2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.914, 0.388, 0.431, 0.4)
	style.anti_aliasing = true
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.914, 0.388, 0.431, 0.35)
	btn.add_theme_stylebox_override("hover", hover)
	UIAnimations.make_interactive(btn)

	var captured_word := word
	var captured_btn := btn
	btn.pressed.connect(func(): _on_placed_chip_pressed(captured_word, captured_btn))
	_drag_drop_zone.add_child(btn)


# ── Answer Handlers ──────���─────────────────────��───────────────────────────────


func _on_fill_submitted() -> void:
	var q := QUIZ_QUESTIONS[_current_q]
	var answer := _fill_input.text.strip_edges().to_lower()
	var correct: bool = answer == q.answer.to_lower()
	if correct:
		_score += 1
	_show_feedback(
		correct, q.get("feedback_correct", "") if correct else q.get("feedback_wrong", "")
	)


func _on_word_chip_pressed(word: String, btn: Button) -> void:
	if is_instance_valid(btn) and btn.get_parent() == _drag_word_bank:
		_drag_word_bank.remove_child(btn)
		btn.queue_free()
	_word_bank_words.erase(word)
	_drag_order.append(word)
	_add_chip_to_zone(word)


func _on_placed_chip_pressed(word: String, btn: Button) -> void:
	if is_instance_valid(btn) and btn.get_parent() == _drag_drop_zone:
		_drag_drop_zone.remove_child(btn)
		btn.queue_free()
	_drag_order.erase(word)
	_word_bank_words.append(word)
	_add_chip_to_bank(word)


func _on_drag_submitted() -> void:
	var q := QUIZ_QUESTIONS[_current_q]
	var correct := true
	if _drag_order.size() != q.correct_order.size():
		correct = false
	else:
		for i in _drag_order.size():
			if _drag_order[i].to_lower() != q.correct_order[i].to_lower():
				correct = false
				break
	if correct:
		_score += 1
	_show_feedback(
		correct, q.get("feedback_correct", "") if correct else q.get("feedback_wrong", "")
	)


# ── Feedback ──────────��────────────────────────���───────────────────────────────


func _show_feedback(correct: bool, explanation: String) -> void:
	_mc_container.visible = false
	_fill_container.visible = false
	_drag_container.visible = false

	# Style feedback panel based on correct/wrong
	_feedback_panel.add_theme_stylebox_override("panel", StyleFactory.make_feedback_panel(correct))

	_feedback_panel.visible = true
	_feedback_panel.modulate.a = 0.0

	# Animate feedback panel in
	var tw := create_tween()
	tw.tween_property(_feedback_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)

	# Icon with animation
	if correct:
		_feedback_icon.text = "Correct!"
		_feedback_icon.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
		# Flash green screen
		UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.1))
	else:
		_feedback_icon.text = "Not Quite"
		_feedback_icon.add_theme_color_override("font_color", StyleFactory.TEXT_ERROR)
		UIAnimations.shake_error(self, _feedback_panel)

	_feedback_text.text = explanation

	if _current_q >= QUIZ_QUESTIONS.size() - 1:
		_next_q_btn.text = "See My Results!"
	else:
		_next_q_btn.text = "Next Question  →"


func _on_next_question_pressed() -> void:
	_feedback_panel.visible = false
	if _current_q < QUIZ_QUESTIONS.size() - 1:
		_current_q += 1
		_load_question(_current_q)
	else:
		_show_results()


# ── Results ───────��────────────────────────────────────────────────────────────


func _show_results() -> void:
	# Fade out quiz
	var tw_out := create_tween()
	tw_out.tween_property(_quiz_container, "modulate:a", 0.0, 0.3)
	await tw_out.finished
	_quiz_container.visible = false

	var level := _score_to_level(_score)
	var level_name: String = LEVEL_NAMES[level]
	var level_desc: String = LEVEL_DESCRIPTIONS[level]
	var level_color: Color = LEVEL_COLORS[level]

	_result_level_name.text = level_name
	_result_level_name.add_theme_color_override("font_color", level_color)
	_result_level_desc.text = level_desc
	_result_badge_label.text = "Level %d" % level

	# Style badge with level color
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = level_color
	badge_style.corner_radius_top_left = 16
	badge_style.corner_radius_top_right = 16
	badge_style.corner_radius_bottom_left = 16
	badge_style.corner_radius_bottom_right = 16
	badge_style.shadow_color = level_color
	badge_style.shadow_color.a = 0.3
	badge_style.shadow_size = 12
	badge_style.shadow_offset = Vector2(0, 4)
	badge_style.anti_aliasing = true
	_result_badge.add_theme_stylebox_override("panel", badge_style)

	# Animate progress bar to 100%
	var tw_prog := create_tween()
	(
		tw_prog
		. tween_property(_quiz_progress, "value", 100.0, 0.5)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_OUT)
	)

	# Show result panel with dramatic reveal
	_result_panel.visible = true
	_result_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_result_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	await tw.finished

	# Elastic badge reveal
	await UIAnimations.elastic_reveal(self, _result_badge)

	# Stagger in the text elements
	UIAnimations.fade_in_up(self, _result_title, 0.0)
	UIAnimations.fade_in_up(self, _result_level_name, 0.15)
	UIAnimations.fade_in_up(self, _result_level_desc, 0.3)
	UIAnimations.fade_in_up(self, _start_btn, 0.45)

	# Celebration flash
	UIAnimations.flash_screen(self, Color(level_color.r, level_color.g, level_color.b, 0.1))

	print(
		(
			"[OnboardingScreen] Placement complete. Score: %d/5 -> Level %d (%s)"
			% [_score, level, level_name]
		)
	)


func _score_to_level(s: int) -> int:
	if s <= 1:
		return 1
	if s == 2:
		return 2
	if s <= 4:
		return 3
	return 4


func _on_start_adventure_pressed() -> void:
	var student: Dictionary = GameManager.current_student
	if student.is_empty():
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
		return
	var level := _score_to_level(_score)
	DatabaseManager.update_student_level(student.id, level)
	DatabaseManager.mark_onboarding_done(student.id)
	GameManager.current_student["reading_level"] = level
	GameManager.current_student["onboarding_done"] = 1

	# Fade out before transition
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	await tw.finished

	get_tree().change_scene_to_file("res://scenes/Main.tscn")
