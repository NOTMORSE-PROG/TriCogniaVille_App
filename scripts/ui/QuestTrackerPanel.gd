extends Control
## QuestTrackerPanel — Persistent collapsible quest log panel.
## Shows current building objective + checklist of steps.
## Anchored top-right, below the progress bar. Uses StyleFactory + UIAnimations.

var _sx: float = 1.0
var _sy: float = 1.0
var _collapsed: bool = false
var _transitioning: bool = false
var _player_ref: Node2D
var _current_building_id: String = ""
var _current_building_pos: Vector2 = Vector2.ZERO
var _proximity_checked: bool = false

# UI nodes
var _panel: PanelContainer
var _panel_vbox: VBoxContainer
var _toggle_btn: Button
var _building_header: Label
var _topic_header: Label
var _checklist_vbox: VBoxContainer
var _completion_container: VBoxContainer

# Checklist state
var _items: Array[Dictionary] = []
# Each: { "text": String, "completed": bool, "checkbox": Panel, "label": Label, "row": HBoxContainer }

const CHECKLIST_TEMPLATES: Array[String] = [
	"Walk to %s",
	"Start the quest",
	"Complete Tutorial stage",
	"Complete Practice stage",
	"Complete Mission (7/10)",
	"Building unlocked!",
]


func setup(sx: float, sy: float, player: Node2D = null) -> void:
	_sx = sx
	_sy = sy
	_player_ref = player
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layout()
	_connect_signals()
	call_deferred("_refresh")


func set_player_ref(player: Node2D) -> void:
	_player_ref = player


# ═════════════════════════════════════════════════════════════════════════════
# LAYOUT
# ═════════════════════════════════════════════════════════════════════════════

func _build_layout() -> void:
	# Outer positioning — top-right
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -310.0 * _sx
	offset_right = 0.0
	offset_top = 60.0 * _sy  # below progress bar
	offset_bottom = 460.0 * _sy  # prevent growing off-screen

	# Toggle button (always visible)
	_toggle_btn = Button.new()
	_toggle_btn.text = ">"
	_toggle_btn.custom_minimum_size = Vector2(28 * _sx, 28 * _sy)
	_toggle_btn.add_theme_font_size_override("font_size", int(14 * _sy))
	_toggle_btn.add_theme_color_override("font_color", StyleFactory.TEXT_MUTED)
	_toggle_btn.add_theme_stylebox_override("normal", StyleFactory.make_secondary_button_normal())
	_toggle_btn.add_theme_stylebox_override("hover", StyleFactory.make_secondary_button_hover())
	_toggle_btn.add_theme_stylebox_override("pressed", StyleFactory.make_secondary_button_pressed())
	_toggle_btn.position = Vector2(-34 * _sx, 8 * _sy)
	_toggle_btn.pressed.connect(_toggle_collapsed)
	_toggle_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_toggle_btn)

	# Main panel
	_panel = PanelContainer.new()
	var style: StyleBoxFlat = StyleFactory.make_glass_card(12)
	style.bg_color = Color(0.06, 0.10, 0.20, 0.65)
	# Override the 32px default margins from make_glass_card — too wide for a side panel
	style.content_margin_left = 10.0 * _sx
	style.content_margin_right = 10.0 * _sx
	style.content_margin_top = 10.0 * _sy
	style.content_margin_bottom = 10.0 * _sy
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size = Vector2(280 * _sx, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_panel_vbox = VBoxContainer.new()
	_panel_vbox.add_theme_constant_override("separation", int(6 * _sy))
	_panel_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_panel_vbox)

	# Building header
	_building_header = Label.new()
	_building_header.add_theme_font_size_override("font_size", int(14 * _sy))
	_building_header.add_theme_color_override("font_color", StyleFactory.TEXT_PRIMARY)
	_building_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_vbox.add_child(_building_header)

	_topic_header = Label.new()
	_topic_header.add_theme_font_size_override("font_size", int(11 * _sy))
	_topic_header.add_theme_color_override("font_color", StyleFactory.GOLD)
	_topic_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_vbox.add_child(_topic_header)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", int(2 * _sy))
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_vbox.add_child(sep)

	# Checklist
	_checklist_vbox = VBoxContainer.new()
	_checklist_vbox.add_theme_constant_override("separation", int(6 * _sy))
	_checklist_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_checklist_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_vbox.add_child(_checklist_vbox)

	# Completion state (hidden by default)
	_completion_container = VBoxContainer.new()
	_completion_container.visible = false
	_completion_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_vbox.add_child(_completion_container)


# ═════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═════════════════════════════════════════════════════════════════════════════

func _connect_signals() -> void:
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_stage_changed.connect(_on_stage_changed)
	QuestManager.quest_completed.connect(_on_quest_completed)
	GameManager.building_unlocked.connect(_on_building_unlocked)
	GameManager.all_buildings_unlocked.connect(_on_all_unlocked)


func _on_quest_started(_building_id: String) -> void:
	_set_item_completed(0)  # "Walk to X" — they were close enough to tap
	_set_item_completed(1)  # "Start the quest"


func _on_stage_changed(stage: String) -> void:
	match stage:
		"practice":
			_set_item_completed(2)  # "Complete Tutorial stage"
		"mission":
			_set_item_completed(3)  # "Complete Practice stage"


func _on_quest_completed(_building_id: String, passed: bool, _score: int) -> void:
	if passed:
		_set_item_completed(4)  # "Complete Mission"


func _on_building_unlocked(_building_id: String) -> void:
	_set_item_completed(5)  # "Building unlocked!"
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		if is_instance_valid(self):
			_refresh()
	)


func _on_all_unlocked() -> void:
	_show_village_restored()


# ═════════════════════════════════════════════════════════════════════════════
# PROXIMITY POLLING
# ═════════════════════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	if _items.size() == 0 or _proximity_checked:
		return
	if _items[0].get("completed", false):
		return
	if not is_instance_valid(_player_ref):
		return
	if _current_building_pos == Vector2.ZERO:
		return
	if _player_ref.position.distance_to(_current_building_pos) < 150.0 * _sx:
		_proximity_checked = true
		_set_item_completed(0)


# ═════════════════════════════════════════════════════════════════════════════
# REFRESH / REBUILD CHECKLIST
# ═════════════════════════════════════════════════════════════════════════════

func _refresh() -> void:
	_proximity_checked = false
	_items.clear()
	for child in _checklist_vbox.get_children():
		child.queue_free()

	var next_id: String = QuestData.get_next_unlockable(GameManager.unlocked_buildings)
	if next_id.is_empty():
		_show_village_restored()
		return

	_current_building_id = next_id
	_completion_container.visible = false
	_checklist_vbox.visible = true

	# Header
	var label: String = QuestData.get_building_label(next_id)
	var meta: Dictionary = QuestData.BUILDING_QUEST_MAP.get(next_id, {})
	var topic: String = meta.get("topic", "")

	_building_header.text = label
	_topic_header.text = topic

	# Get building position for proximity check
	_current_building_pos = Vector2.ZERO
	var parent_node: Node = get_parent()
	while parent_node != null:
		if parent_node.has_method("_spawn_buildings"):
			break
		parent_node = parent_node.get_parent()
	# Fallback: search for building node in the scene tree
	var building_node: Node = _find_building_node(next_id)
	if building_node != null:
		_current_building_pos = building_node.position

	# Build checklist rows
	for i in CHECKLIST_TEMPLATES.size():
		var text: String = CHECKLIST_TEMPLATES[i]
		if i == 0:
			text = text % label
		var row: HBoxContainer = _make_checklist_row(text, false)
		_checklist_vbox.add_child(row)
		_items.append({
			"text": text,
			"completed": false,
			"row": row,
		})




func _find_building_node(building_id: String) -> Node:
	# Walk up to Main scene and find the building controller
	if not is_inside_tree():
		return null
	var root: Node = get_tree().current_scene
	if root == null:
		return null
	var ysort: Node = root.get_node_or_null("YSortLayer")
	if ysort == null:
		return null
	return ysort.get_node_or_null(building_id)


# ═════════════════════════════════════════════════════════════════════════════
# CHECKLIST ITEM
# ═════════════════════════════════════════════════════════════════════════════

func _make_checklist_row(text: String, completed: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(6 * _sx))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Checkbox
	var checkbox := Panel.new()
	checkbox.name = "Checkbox"
	checkbox.custom_minimum_size = Vector2(18 * _sx, 18 * _sy)
	checkbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_checkbox(checkbox, completed)
	row.add_child(checkbox)

	# Text
	var lbl := Label.new()
	lbl.name = "Label"
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", int(12 * _sy))
	lbl.add_theme_color_override("font_color",
		StyleFactory.SUCCESS_GREEN if completed else StyleFactory.TEXT_SECONDARY)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)

	return row


func _style_checkbox(checkbox: Panel, completed: bool) -> void:
	var cb_style := StyleBoxFlat.new()
	var r := int(3 * _sx)
	cb_style.corner_radius_top_left = r
	cb_style.corner_radius_top_right = r
	cb_style.corner_radius_bottom_left = r
	cb_style.corner_radius_bottom_right = r
	cb_style.anti_aliasing = true

	# Remove old checkmark children
	for child in checkbox.get_children():
		child.queue_free()

	if completed:
		cb_style.bg_color = StyleFactory.SUCCESS_GREEN
		cb_style.border_width_left = 0
		cb_style.border_width_right = 0
		cb_style.border_width_top = 0
		cb_style.border_width_bottom = 0
		# Checkmark
		var check_lbl := Label.new()
		check_lbl.text = "✓"
		check_lbl.add_theme_font_size_override("font_size", int(12 * _sy))
		check_lbl.add_theme_color_override("font_color", Color.WHITE)
		check_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		check_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		check_lbl.anchor_right = 1.0
		check_lbl.anchor_bottom = 1.0
		check_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		checkbox.add_child(check_lbl)
	else:
		cb_style.bg_color = Color(0, 0, 0, 0)
		cb_style.border_width_left = 2
		cb_style.border_width_right = 2
		cb_style.border_width_top = 2
		cb_style.border_width_bottom = 2
		cb_style.border_color = StyleFactory.TEXT_MUTED

	checkbox.add_theme_stylebox_override("panel", cb_style)


func _set_item_completed(index: int, animate: bool = true) -> void:
	if index < 0 or index >= _items.size():
		return
	if _items[index].get("completed", false):
		return
	_items[index]["completed"] = true

	var row: HBoxContainer = _items[index].get("row")
	if not is_instance_valid(row):
		return

	var checkbox: Panel = row.get_node_or_null("Checkbox")
	var lbl: Label = row.get_node_or_null("Label")

	if is_instance_valid(checkbox):
		_style_checkbox(checkbox, true)
		if animate:
			checkbox.pivot_offset = checkbox.size / 2.0
			var tw := create_tween()
			tw.tween_property(checkbox, "scale", Vector2(1.3, 1.3), 0.12) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(checkbox, "scale", Vector2.ONE, 0.15) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if is_instance_valid(lbl):
		lbl.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)


# ═════════════════════════════════════════════════════════════════════════════
# COLLAPSE / EXPAND
# ═════════════════════════════════════════════════════════════════════════════

func _toggle_collapsed() -> void:
	if _transitioning:
		return
	_transitioning = true
	_collapsed = not _collapsed

	if _collapsed:
		_toggle_btn.text = "<"
		var tw := create_tween()
		tw.tween_property(_panel, "modulate:a", 0.0, 0.25) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			_panel.visible = false
			_transitioning = false
		)
	else:
		_panel.visible = true
		_toggle_btn.text = ">"
		var tw := create_tween()
		tw.tween_property(_panel, "modulate:a", 1.0, 0.25) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			_transitioning = false
		)


# ═════════════════════════════════════════════════════════════════════════════
# VILLAGE RESTORED
# ═════════════════════════════════════════════════════════════════════════════

func _show_village_restored() -> void:
	_checklist_vbox.visible = false
	_building_header.text = "Village Restored!"
	_building_header.add_theme_color_override("font_color", StyleFactory.GOLD)
	_topic_header.text = "All buildings unlocked"
	_topic_header.add_theme_color_override("font_color", StyleFactory.SUCCESS_GREEN)
	set_process(false)
