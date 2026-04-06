extends Control
## ReadAloudInteraction — Simplified read-aloud for MVP.
## Displays word/passage, waits minimum 5s, then enables "I finished reading" button.
## No microphone — completion-based only.

signal answer_submitted(correct: bool)

var _sx: float = 1.0
var _sy: float = 1.0
var _question: Dictionary = {}

var _timer: Timer
var _confirm_btn: Button
var _progress_bar: ProgressBar
var _elapsed: float = 0.0
const MIN_DISPLAY_TIME := 5.0


func setup(question: Dictionary, _show_hints: bool, sx: float = 1.0, sy: float = 1.0) -> void:
	_sx = sx
	_sy = sy
	_question = question
	_elapsed = 0.0
	_build_ui()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", int(16 * _sy))
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Instruction
	var instruction: String = _question.get("instruction", "Read this aloud clearly.")
	var inst_label := Label.new()
	inst_label.text = instruction
	inst_label.add_theme_font_size_override("font_size", int(18 * _sy))
	inst_label.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	inst_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inst_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(inst_label)

	# Content card
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", StyleFactory.make_glass_card(16))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var word: String = _question.get("word", "")
	var passage: String = _question.get("passage", "")

	if not word.is_empty():
		# Single word — large centered
		var word_label := Label.new()
		word_label.text = word
		word_label.add_theme_font_size_override("font_size", int(40 * _sy))
		word_label.add_theme_color_override("font_color", StyleFactory.GOLD)
		word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(word_label)
	elif not passage.is_empty():
		# Passage — readable size
		var passage_label := RichTextLabel.new()
		passage_label.text = passage
		passage_label.fit_content = true
		passage_label.bbcode_enabled = false
		passage_label.scroll_active = false
		passage_label.add_theme_font_size_override("normal_font_size", int(18 * _sy))
		passage_label.add_theme_color_override("default_color", StyleFactory.TEXT_PRIMARY)
		passage_label.custom_minimum_size = Vector2(0, 80 * _sy)
		passage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(passage_label)

	vbox.add_child(card)

	# Timer progress bar
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = MIN_DISPLAY_TIME
	_progress_bar.value = 0.0
	_progress_bar.custom_minimum_size = Vector2(0, 8 * _sy)
	_progress_bar.add_theme_stylebox_override("background", StyleFactory.make_progress_bg())
	_progress_bar.add_theme_stylebox_override("fill", StyleFactory.make_progress_fill())
	_progress_bar.show_percentage = false
	vbox.add_child(_progress_bar)

	# Timer label
	var timer_label := Label.new()
	timer_label.text = "Read aloud, then tap the button below when done."
	timer_label.add_theme_font_size_override("font_size", int(13 * _sy))
	timer_label.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(timer_label)

	# Confirm button (disabled initially)
	var center := CenterContainer.new()
	vbox.add_child(center)

	_confirm_btn = Button.new()
	_confirm_btn.text = "I finished reading"
	_confirm_btn.disabled = true
	_confirm_btn.custom_minimum_size = Vector2(220 * _sx, 52 * _sy)
	_confirm_btn.add_theme_font_size_override("font_size", int(18 * _sy))
	_confirm_btn.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_confirm_btn.add_theme_stylebox_override("normal", StyleFactory.make_primary_button_normal())
	_confirm_btn.add_theme_stylebox_override("hover", StyleFactory.make_primary_button_hover())
	_confirm_btn.add_theme_stylebox_override("pressed", StyleFactory.make_primary_button_pressed())
	_confirm_btn.add_theme_stylebox_override("disabled", StyleFactory.make_disabled_button())
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	center.add_child(_confirm_btn)

	# Start the countdown
	_elapsed = 0.0
	set_process(true)


func _process(delta: float) -> void:
	if _elapsed >= MIN_DISPLAY_TIME:
		set_process(false)
		return
	_elapsed += delta
	if is_instance_valid(_progress_bar):
		_progress_bar.value = minf(_elapsed, MIN_DISPLAY_TIME)
	if _elapsed >= MIN_DISPLAY_TIME:
		_enable_button()


func _enable_button() -> void:
	if not is_instance_valid(_confirm_btn):
		return
	_confirm_btn.disabled = false
	UIAnimations.fade_in_up(self, _confirm_btn)
	UIAnimations.make_interactive(_confirm_btn)


func _on_confirm_pressed() -> void:
	_confirm_btn.disabled = true
	_confirm_btn.text = "Great job!"
	_confirm_btn.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)

	var style := StyleFactory.make_primary_button_normal()
	style.bg_color = StyleFactory.SUCCESS_GREEN.darkened(0.4)
	_confirm_btn.add_theme_stylebox_override("disabled", style)

	UIAnimations.flash_screen(self, Color(0.357, 0.851, 0.635, 0.08))

	# Read-aloud always counts as correct for MVP
	answer_submitted.emit(true)
