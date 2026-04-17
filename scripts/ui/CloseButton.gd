class_name CloseButton
extends Control
## CloseButton — Drawn circle + X close button.
## Layout size matches the visual circle exactly; _has_point() silently expands
## the input detection zone so taps near-but-not-on the circle still register.

signal pressed

## Hit-area padding, px. Asymmetric by design — top/sides can bleed over the
## card border (nothing interactive above or beside the button), but bottom
## must stay within the title bar so it doesn't steal scroll gestures.
const HIT_PADDING_SIDE   := 44.0
const HIT_PADDING_TOP    := 44.0
const HIT_PADDING_BOTTOM := 16.0

var _hovered: bool = false


func setup(size_px: float) -> void:
	custom_minimum_size = Vector2(size_px, size_px)
	size = Vector2(size_px, size_px)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


## Expand the input-detection rect without touching layout or visuals.
func _has_point(point: Vector2) -> bool:
	return Rect2(
		-HIT_PADDING_SIDE,
		-HIT_PADDING_TOP,
		size.x + HIT_PADDING_SIDE * 2.0,
		size.y + HIT_PADDING_TOP + HIT_PADDING_BOTTOM
	).has_point(point)


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
