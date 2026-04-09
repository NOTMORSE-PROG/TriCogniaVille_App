class_name CloseButton
extends Control
## CloseButton — Drawn circle + X close button.
## Visual and input rect are always identical — no sweet-spot issues.

signal pressed

var _hovered: bool = false


func setup(size_px: float) -> void:
	custom_minimum_size = Vector2(size_px, size_px)
	size = Vector2(size_px, size_px)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5

	# Circle background
	var bg := Color(1.0, 1.0, 1.0, 0.10 if not _hovered else 0.22)
	draw_circle(c, r, bg)

	# Circle border
	var border_col := Color(StyleFactory.GOLD.r, StyleFactory.GOLD.g, StyleFactory.GOLD.b, 0.55)
	draw_arc(c, r - 1.0, 0.0, TAU, 48, border_col, 1.5, true)

	# X lines
	var arm := r * 0.38
	var lw := maxf(2.0, r * 0.09)
	draw_line(c + Vector2(-arm, -arm), c + Vector2(arm, arm), StyleFactory.GOLD, lw, true)
	draw_line(c + Vector2(arm, -arm), c + Vector2(-arm, arm), StyleFactory.GOLD, lw, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		pressed.emit()
		accept_event()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_hovered = true
			queue_redraw()
		NOTIFICATION_MOUSE_EXIT:
			_hovered = false
			queue_redraw()
